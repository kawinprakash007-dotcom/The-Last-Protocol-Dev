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

	# ── Player Capture Check ──
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and not player.is_control_disabled:
		var robot_pos_2d = Vector2(global_position.x, global_position.z)
		var player_pos_2d = Vector2(player.global_position.x, player.global_position.z)
		if robot_pos_2d.distance_to(player_pos_2d) < 1.3 and abs(global_position.y - player.global_position.y) < 2.0:
			# Capture!
			if Mission01.has_method("trigger_player_caught"):
				Mission01.trigger_player_caught()

func _process_patrol(delta: float) -> void:
	scan_light.light_color = Color(0.1, 0.8, 1.0) # Normal blue/cyan light
	
	# Check for player detection
	if _has_line_of_sight():
		last_known_position = detected_player.global_position
		_change_state(State.SUSPICIOUS)
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
			print("ROBOT: SUSPICIOUS")
			warning_timer = 0.0
		State.ALERT:
			print("ROBOT: HUMAN TARGET CONFIRMED")
			alert_transition_timer = 0.5
		State.PURSUIT:
			print("ROBOT: PURSUING")
			pursuit_lost_timer = 0.0
		State.SEARCH:
			print("ROBOT: SEARCHING")
			search_target = last_known_position
			is_searching_at_target = false
			search_timer = search_duration

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
	detected_player = null
	velocity = Vector3.ZERO
	scan_light.light_color = Color(0.1, 0.8, 1.0)
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
		detected_player = body
		# Only transition immediately if in PATROL. If already in another state (like SEARCH),
		# the search processing loop will handle the reacquisition transition.
		if current_state == State.PATROL:
			# Checking line of sight will happen in physics process, but we can set player reference here.
			pass

func _on_vision_body_exited(body: Node3D) -> void:
	if body == detected_player:
		detected_player = null

func _has_line_of_sight() -> bool:
	if not detected_player:
		return false
		
	los_ray.target_position = los_ray.to_local(detected_player.global_position + Vector3(0, 1.0, 0))
	los_ray.force_raycast_update()
	
	if los_ray.is_colliding():
		return los_ray.get_collider() == detected_player
	return false
