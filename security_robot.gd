extends CharacterBody3D

enum State {
	PATROL,
	SUSPICIOUS,
	ALERT,
	PURSUIT,
	SEARCH
}

@export var SPEED: float = 3.0
@export var PURSUIT_SPEED: float = 4.8
@export var ROTATION_SPEED: float = 2.0
@export var patrol_points: Array[NodePath]

@onready var head: Node3D = $Head
@onready var scan_light: SpotLight3D = $Head/ScanLight
@onready var vision_area: Area3D = $Head/VisionArea
@onready var los_ray: RayCast3D = $Head/LineOfSightRay

var current_state: State = State.PATROL
var patrol_index: int = 0
var patrol_target: Vector3
var is_waiting: bool = false
var wait_timer: float = 0.0
var warning_timer: float = 0.0

var health: int = 3
var is_destroyed: bool = false
var attack_cooldown: float = 0.0

var detected_player: Node3D = null

# Stealth parameters
var reaction_window: float = 1.5
var search_timer: float = 0.0
var search_duration: float = 3.0
var search_target: Vector3 = Vector3.ZERO
var last_known_position: Vector3 = Vector3.ZERO
var is_searching_at_target: bool = false
var alert_transition_timer: float = 0.0
var pursuit_lost_timer: float = 0.0
var _last_los_print_time: int = 0

# Initial transform cache for reset
var initial_position: Vector3
var initial_rotation: Vector3

func _ready() -> void:
	add_to_group("security_robots")
	initial_position = global_position
	initial_rotation = global_rotation
	
	vision_area.body_entered.connect(_on_vision_body_entered)
	vision_area.body_exited.connect(_on_vision_body_exited)
	_set_next_patrol_point()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0
		
	if is_destroyed:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	# ── State Machine ──
	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.SUSPICIOUS:
			_process_suspicious(delta)
		State.ALERT:
			_process_alert(delta)
		State.PURSUIT:
			_process_pursuit(delta)
		State.SEARCH:
			_process_search(delta)
			
	move_and_slide()

func _process_patrol(delta: float) -> void:
	scan_light.light_color = Color(0.1, 0.8, 1.0) # Normal blue/cyan light
	
	# Check for player detection
	if _has_line_of_sight():
		last_known_position = detected_player.global_position
		_change_state(State.ALERT)
		return

	if is_waiting:
		wait_timer -= delta
		# Slowly scan left and right while waiting
		head.rotation.y = sin(wait_timer * 2.0) * 0.5
		if wait_timer <= 0:
			is_waiting = false
			_set_next_patrol_point()
		return
		
	# Smoothly rotate head back to center
	head.rotation.y = lerp_angle(head.rotation.y, 0.0, ROTATION_SPEED * delta)

	var to_target = patrol_target - global_position
	to_target.y = 0 # keep it on the horizontal plane
	
	if to_target.length() < 0.5:
		is_waiting = true
		wait_timer = 2.0 # Pause for 2 seconds
		velocity.x = 0
		velocity.z = 0
		print("ROBOT: REACHED PATROL POINT")
	else:
		var target_dir = to_target.normalized()
		var target_basis = Basis.looking_at(target_dir, Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_basis, ROTATION_SPEED * delta)
		
		velocity.x = target_dir.x * SPEED
		velocity.z = target_dir.z * SPEED

func _process_suspicious(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	scan_light.light_color = Color(1.0, 0.6, 0.0) # Yellow warning light
	
	if _has_line_of_sight():
		last_known_position = detected_player.global_position
		
		# Look at player
		var to_player = detected_player.global_position - global_position
		to_player.y = 0
		var target_basis = Basis.looking_at(to_player.normalized(), Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_basis, ROTATION_SPEED * 2.0 * delta)
		head.rotation.y = lerp_angle(head.rotation.y, 0.0, ROTATION_SPEED * delta)
		
		warning_timer += delta
		if warning_timer >= reaction_window:
			_change_state(State.ALERT)
	else:
		# Player hid during suspicious window, transition to SEARCH
		_change_state(State.SEARCH)

func _process_alert(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	scan_light.light_color = Color(1.0, 0.1, 0.1) # Red warning light
	
	if _has_line_of_sight():
		last_known_position = detected_player.global_position
		var to_player = detected_player.global_position - global_position
		to_player.y = 0
		var target_basis = Basis.looking_at(to_player.normalized(), Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_basis, ROTATION_SPEED * 3.0 * delta)
		head.rotation.y = lerp_angle(head.rotation.y, 0.0, ROTATION_SPEED * delta)
		
		if attack_cooldown > 0:
			attack_cooldown -= delta
		if attack_cooldown <= 0:
			if current_state == State.SUSPICIOUS:
				print("[COMBAT] Encounter started")
			_fire_weapon()

	alert_transition_timer -= delta
	if alert_transition_timer <= 0.0:
		_change_state(State.PURSUIT)

func _process_pursuit(delta: float) -> void:
	scan_light.light_color = Color(1.0, 0.1, 0.1) # Red warning light
	
	if _has_line_of_sight():
		last_known_position = detected_player.global_position
		pursuit_lost_timer = 0.0
		
		var to_player = detected_player.global_position - global_position
		to_player.y = 0
		var target_dir = to_player.normalized()
		var target_basis = Basis.looking_at(target_dir, Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_basis, ROTATION_SPEED * 2.0 * delta)
		head.rotation.y = lerp_angle(head.rotation.y, 0.0, ROTATION_SPEED * delta)
		
		velocity.x = target_dir.x * PURSUIT_SPEED
		velocity.z = target_dir.z * PURSUIT_SPEED
		
		if attack_cooldown > 0:
			attack_cooldown -= delta
		if attack_cooldown <= 0:
			_fire_weapon()
	else:
		# Lost line of sight, move to last known position
		var to_target = last_known_position - global_position
		to_target.y = 0
		
		if to_target.length() < 1.0 or pursuit_lost_timer >= 4.0:
			_change_state(State.SEARCH)
			return
			
		pursuit_lost_timer += delta
		var target_dir = to_target.normalized()
		var target_basis = Basis.looking_at(target_dir, Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_basis, ROTATION_SPEED * 2.0 * delta)
		head.rotation.y = lerp_angle(head.rotation.y, 0.0, ROTATION_SPEED * delta)
		
		velocity.x = target_dir.x * PURSUIT_SPEED
		velocity.z = target_dir.z * PURSUIT_SPEED

func _process_search(delta: float) -> void:
	scan_light.light_color = Color(1.0, 0.6, 0.0) # Orange/yellow warning light
	
	if _has_line_of_sight():
		_change_state(State.ALERT)
		return

	if not is_searching_at_target:
		# Move to the search target location (last known position)
		var to_target = search_target - global_position
		to_target.y = 0
		
		if to_target.length() < 0.8:
			is_searching_at_target = true
			search_timer = search_duration
			velocity.x = 0
			velocity.z = 0
		else:
			var target_dir = to_target.normalized()
			var target_basis = Basis.looking_at(target_dir, Vector3.UP)
			global_transform.basis = global_transform.basis.slerp(target_basis, ROTATION_SPEED * delta)
			head.rotation.y = lerp_angle(head.rotation.y, 0.0, ROTATION_SPEED * delta)
			
			velocity.x = target_dir.x * SPEED
			velocity.z = target_dir.z * SPEED
	else:
		# Look around at the search target
		velocity.x = 0
		velocity.z = 0
		head.rotation.y = sin(search_timer * 4.0) * 0.7
		
		search_timer -= delta
		if search_timer <= 0:
			_return_to_patrol()

func _change_state(new_state: State) -> void:
	current_state = new_state
	match current_state:
		State.PATROL:
			print("ROBOT: PATROLLING")
		State.SUSPICIOUS:
			print("[COMBAT DEBUG] Robot state: SUSPICIOUS")
			print("[COMBAT] State -> SUSPICIOUS (LOS Confirmed)")
			if AudioManager.has_method("play_robot_alert"):
				AudioManager.play_robot_alert(global_position)
			warning_timer = 0.0
		State.ALERT:
			print("[COMBAT DEBUG] Robot state: ALERT")
			print("[COMBAT] State -> ALERT")
			alert_transition_timer = 0.5
		State.PURSUIT:
			print("ROBOT: PURSUING")
			pursuit_lost_timer = 0.0
		State.SEARCH:
			print("ROBOT: SEARCHING")
			search_target = last_known_position
			is_searching_at_target = false
			search_timer = search_duration

func _is_player_collider(collider) -> bool:
	if not collider: return false
	var curr = collider
	while curr:
		if curr == detected_player or curr.is_in_group("player"):
			return true
		curr = curr.get_parent()
	return false

func _fire_weapon() -> void:
	if not detected_player or is_destroyed: return
	
	print("[COMBAT DEBUG] Robot attempting attack")
	print("[COMBAT] Robot weapon cooldown ready")
	attack_cooldown = 1.5
	
	if AudioManager.has_method("play_robot_fire"):
		AudioManager.play_robot_fire(global_position)
	
	# Visual muzzle flash simulation via light flicker
	var original_energy = scan_light.light_energy
	scan_light.light_energy = original_energy * 3.0
	var tw = create_tween()
	tw.tween_property(scan_light, "light_energy", original_energy, 0.1)
	
	var space_state = get_world_3d().direct_space_state
	var origin = head.global_position
	var target = detected_player.global_position + Vector3(0, 0.5, 0) # Chest height
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	query.collision_mask = 5 # Layer 1 (Env) + Layer 3 (Player)
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)
	
	if result and result.has("collider"):
		var col = result.collider
		print("[COMBAT DEBUG] Robot weapon ray hit: ", col.name)
		if _is_player_collider(col):
			print("[COMBAT] Robot fired")
			print("[COMBAT] Robot weapon hit: Player")
			if detected_player.has_method("take_damage"):
				detected_player.take_damage(20)
	else:
		print("[COMBAT DEBUG] Robot weapon ray hit: NONE")

func take_damage(amount: int) -> void:
	if is_destroyed: return
	health -= amount
	print("[COMBAT] Robot took damage: ", amount)
	
	# Flicker light to show damage
	scan_light.light_color = Color.WHITE
	
	if health <= 0:
		is_destroyed = true
		print("[COMBAT] Robot destroyed")
		if AudioManager.has_method("play_robot_destroyed"):
			AudioManager.play_robot_destroyed(global_position)
		scan_light.light_color = Color(0.2, 0.2, 0.2)
		scan_light.light_energy = 0.5
		velocity = Vector3.ZERO
		collision_layer = 0
		if GameState.has_method("trigger_robot_destroyed"):
			GameState.trigger_robot_destroyed()
	else:
		if current_state in [State.PATROL, State.SEARCH, State.SUSPICIOUS]:
			print("[COMBAT] Encounter started (Robot took damage)")
			_change_state(State.ALERT)

func _return_to_patrol() -> void:
	print("ROBOT: TARGET LOST — RETURNING TO PATROL")
	if patrol_points.is_empty():
		_change_state(State.PATROL)
		return
		
	# Find nearest patrol point index
	var nearest_index = 0
	var min_dist = 1e9
	for i in range(patrol_points.size()):
		var node = get_node_or_null(patrol_points[i])
		if node and node is Node3D:
			var dist = global_position.distance_to(node.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_index = i
				
	patrol_index = nearest_index
	var target_node = get_node_or_null(patrol_points[patrol_index])
	if target_node and target_node is Node3D:
		patrol_target = target_node.global_position
		
	# Setup next patrol index for after reaching this one
	patrol_index = (patrol_index + 1) % patrol_points.size()
	is_waiting = false
	wait_timer = 0.0
	_change_state(State.PATROL)

func reset_to_initial_state() -> void:
	global_position = initial_position
	global_rotation = initial_rotation
	current_state = State.PATROL
	patrol_index = 0
	is_waiting = false
	wait_timer = 0.0
	warning_timer = 0.0
	health = 3
	is_destroyed = false
	attack_cooldown = 0.0
	detected_player = null
	velocity = Vector3.ZERO
	scan_light.light_color = Color(0.1, 0.8, 1.0)
	scan_light.light_energy = 1.0
	head.rotation = Vector3.ZERO
	_set_next_patrol_point()

func _set_next_patrol_point() -> void:
	if patrol_points.is_empty():
		patrol_target = global_position
		return
		
	var target_node = get_node_or_null(patrol_points[patrol_index])
	if target_node and target_node is Node3D:
		patrol_target = target_node.global_position
	
	patrol_index = (patrol_index + 1) % patrol_points.size()

func _on_vision_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		print("[COMBAT] VisionArea detected Player")
		print("[COMBAT DEBUG] VisionArea detected: ", body.name)
		detected_player = body
		if GameState.has_method("trigger_security_threat"):
			GameState.trigger_security_threat()

func _on_vision_body_exited(body: Node3D) -> void:
	if body == detected_player:
		detected_player = null

func _has_line_of_sight() -> bool:
	if not detected_player:
		return false
		
	var space_state = get_world_3d().direct_space_state
	var origin = head.global_position
	var target = detected_player.global_position + Vector3(0, 0.5, 0)
	
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	query.collision_mask = 5 # Layer 1 (Env) + Layer 3 (Player)
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)
	
	var los_true = false
	var col_name = "NONE"
	
	if result and result.has("collider"):
		var col = result.collider
		col_name = col.name
		if _is_player_collider(col):
			los_true = true
	
	if Time.get_ticks_msec() - _last_los_print_time > 1000:
		_last_los_print_time = Time.get_ticks_msec()
		print("[LOS DEBUG] Target = ", target)
		print("[LOS DEBUG] Collider = ", col_name)
		print("[LOS DEBUG] Result = ", "TRUE" if los_true else "FALSE")
	
	if los_true:
		print("[COMBAT] LOS CONFIRMED")
		return true
		
	return false
