extends CharacterBody3D

@export var SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 4.5
@export var MOUSE_SENSITIVITY: float = 0.002

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera

var is_control_disabled: bool = false
var is_dead: bool = false

var health: int = 200
var weapon_cooldown: float = 0.0
var spawn_protection_timer: float = 0.0
var _damage_overlay: ColorRect
var _health_label: Label

# Temporary debug visualization for interaction ray
var _debug_mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _debug_material: StandardMaterial3D

func _ready() -> void:
	add_to_group("player")
	collision_layer = 4 # Layer 3 is bit 2 (1 << 2 = 4)
	collision_mask = 3  # Layer 1 (Env) + Layer 2 (Robot)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_ensure_input_map()
	_setup_debug_ray()
	_setup_damage_overlay()

func _setup_damage_overlay() -> void:
	_damage_overlay = ColorRect.new()
	_damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_damage_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
	_damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_health_label = Label.new()
	_health_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_health_label.offset_left = 20
	_health_label.offset_bottom = -20
	_health_label.add_theme_font_size_override("font_size", 32)
	_health_label.add_theme_color_override("font_color", Color.GREEN_YELLOW)
	_update_health_ui()
	
	var canvas = CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	canvas.add_child(_damage_overlay)
	canvas.add_child(_health_label)

func _update_health_ui() -> void:
	if _health_label:
		_health_label.text = "HP: " + str(health)

func _setup_debug_ray() -> void:
	_debug_mesh_instance = MeshInstance3D.new()
	_debug_mesh_instance.name = "DebugRayVisualizer"
	_debug_mesh_instance.top_level = true
	_immediate_mesh = ImmediateMesh.new()
	_debug_material = StandardMaterial3D.new()
	_debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_debug_material.vertex_color_use_as_albedo = true
	_debug_mesh_instance.mesh = _immediate_mesh
	_debug_mesh_instance.material_override = _debug_material
	add_child(_debug_mesh_instance)

func _process(delta: float) -> void:
	if spawn_protection_timer > 0:
		spawn_protection_timer -= delta
		
	if weapon_cooldown > 0:
		weapon_cooldown -= delta
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if weapon_cooldown <= 0:
			print("[COMBAT DEBUG]\nPlayer fire input received")
			print("[COMBAT] Fire input detected")
			_fire_weapon()

func _update_debug_ray() -> void:
	if not camera or not _immediate_mesh:
		return
	var ray_origin := camera.global_position
	var ray_end := ray_origin - camera.global_transform.basis.z * 12.0
	
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 4 # Collision layer 4 (Interactables)
	query.exclude = [get_rid()]
	var result := space_state.intersect_ray(query)
	
	var has_hit := result != null and not result.is_empty()
	var hit_point := ray_end
	if has_hit and result.has("position"):
		hit_point = result["position"]
		
	_immediate_mesh.clear_surfaces()
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	# Green line if ray intersects interactable, red line if empty
	var color := Color.GREEN if has_hit else Color.RED
	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(ray_origin)
	_immediate_mesh.surface_add_vertex(hit_point)
	
	if not has_hit:
		_immediate_mesh.surface_set_color(Color(1.0, 0.3, 0.3, 0.5))
		_immediate_mesh.surface_add_vertex(hit_point)
		_immediate_mesh.surface_add_vertex(ray_end)
		
	_immediate_mesh.surface_end()

func _unhandled_input(event: InputEvent) -> void:
	if is_control_disabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		if spring_arm:
			spring_arm.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-80.0), deg_to_rad(60.0))
	elif event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("interact"):
		_try_interact()

func _physics_process(delta: float) -> void:
	# Add gravity if not on floor
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_control_disabled:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get WASD input direction relative to player rotation
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()

func reset_to_position(pos: Vector3, rot_y: float) -> void:
	global_position = pos
	global_rotation.y = rot_y
	velocity = Vector3.ZERO
	health = 200
	is_dead = false
	weapon_cooldown = 0.0
	spawn_protection_timer = 3.0
	is_control_disabled = false
	_update_health_ui()
	if spring_arm:
		spring_arm.rotation = Vector3.ZERO

func take_damage(amount: int) -> void:
	if is_dead or spawn_protection_timer > 0:
		return
		
	health -= amount
	_update_health_ui()
	print("[COMBAT] Player took damage: ", amount, " | HP: ", health)
	if _damage_overlay:
		_damage_overlay.color = Color(1.0, 0.0, 0.0, 0.4)
		var tw = create_tween()
		tw.tween_property(_damage_overlay, "color", Color(1.0, 0.0, 0.0, 0.0), 0.3)
	if health <= 0:
		is_dead = true
		if Mission01.has_method("trigger_player_caught"):
			Mission01.trigger_player_caught()

func _is_robot_collider(collider) -> bool:
	if not collider: return false
	var curr = collider
	while curr:
		if curr.is_in_group("security_robots"):
			return true
		curr = curr.get_parent()
	return false

func _fire_weapon() -> void:
	if weapon_cooldown > 0 or is_control_disabled or is_dead:
		return
	weapon_cooldown = 0.5
	print("[COMBAT] Player fired")
	
	if not camera: return
	var space_state := get_world_3d().direct_space_state
	var ray_origin := camera.global_position
	var ray_end := ray_origin - camera.global_transform.basis.z * 50.0
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 3 # Layer 1 (Env) + Layer 2 (Security Robot)
	query.exclude = [get_rid()]
	var result := space_state.intersect_ray(query)
	
	if result and result.has("collider"):
		var collider = result["collider"]
		print("[COMBAT DEBUG] Player weapon ray hit: ", collider.name)
		if _is_robot_collider(collider):
			print("[COMBAT] Player weapon hit: SecurityRobot")
			if collider.has_method("take_damage"):
				collider.take_damage(1)
	else:
		print("[COMBAT DEBUG] Player weapon ray hit: NONE")

func _try_interact() -> void:
	print("E INTERACTION FUNCTION CALLED")
	if not camera:
		return
	var space_state := get_world_3d().direct_space_state
	var ray_origin := camera.global_position
	var ray_end := ray_origin - camera.global_transform.basis.z * 12.0
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 4 # Collision layer 4 (Interactables)
	query.exclude = [get_rid()]
	var result := space_state.intersect_ray(query)
	print("RAY RESULT: ", result)
	if result and result.has("collider"):
		var collider: Object = result["collider"]
		if collider.has_method("interact"):
			collider.interact()

func _ensure_input_map() -> void:
	var required_actions: Dictionary = {
		"move_forward": KEY_W,
		"move_backward": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"jump": KEY_SPACE,
		"interact": KEY_E
	}
	for action: String in required_actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var key_event := InputEventKey.new()
			key_event.physical_keycode = required_actions[action]
			InputMap.action_add_event(action, key_event)
			
	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("fire", mouse_event)
