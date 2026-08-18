extends CharacterBody3D

@export var SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 4.5
@export var MOUSE_SENSITIVITY: float = 0.002

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera

# Temporary debug visualization for interaction ray
var _debug_mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _debug_material: StandardMaterial3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_ensure_input_map()
	_setup_debug_ray()

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

func _process(_delta: float) -> void:
	_update_debug_ray()

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
