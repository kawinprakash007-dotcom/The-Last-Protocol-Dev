class_name PowerRelay
extends Interactable

@export var sequence_index: int = 0
var is_activated: bool = false

@onready var core_mesh: MeshInstance3D = $PowerRelayVisual/Relay_Core
@onready var light: OmniLight3D = $OmniLight3D

# Simple visual materials
var _mat_inactive: StandardMaterial3D
var _mat_active: StandardMaterial3D
var _mat_destroyed: StandardMaterial3D

@export var health: int = 50
var is_destroyed: bool = false

func _ready() -> void:
	GameState.power_puzzle_reset.connect(_on_puzzle_reset)
	
	_mat_inactive = StandardMaterial3D.new()
	_mat_inactive.albedo_color = Color(0.1, 0.1, 0.1)
	
	_mat_active = StandardMaterial3D.new()
	_mat_active.albedo_color = Color(1.0, 0.6, 0.1)
	_mat_active.emission_enabled = true
	_mat_active.emission = Color(1.0, 0.6, 0.1)
	_mat_active.emission_energy_multiplier = 2.0
	
	_mat_destroyed = StandardMaterial3D.new()
	_mat_destroyed.albedo_color = Color(0.05, 0.05, 0.05)
	
	_update_visuals()

func interact() -> void:
	if is_activated or is_destroyed or GameState.power_restored:
		return
	
	print("[GAMEPLAY] Relay ", sequence_index, " interacted successfully.")
	if AudioManager.has_method("play_relay_interact"):
		AudioManager.play_relay_interact(global_position)
		
	is_activated = true
	_update_visuals()
	
	# Attempt to advance sequence
	GameState.advance_power_sequence(sequence_index)

func take_damage(amount: int) -> void:
	if is_destroyed: return
	health -= amount
	print("[COMBAT] Relay took damage: ", amount)
	if health <= 0:
		_explode()

func _explode() -> void:
	is_destroyed = true
	is_activated = true
	print("[GAMEPLAY] Relay ", sequence_index, " EXPLODED!")
	
	if AudioManager.has_method("play_relay_explosion"):
		AudioManager.play_relay_explosion(global_position)
		
	_update_visuals()
	
	# Damage nearby entities (radius 5.0)
	var space = get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = 5.0
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 3 # Player (1) and Robot (2)
	
	var results = space.intersect_shape(query)
	for res in results:
		var collider = res.collider
		if collider.has_method("take_damage"):
			collider.take_damage(50) # Massive explosion damage
			
	# Explosions forcefully advance the power sequence as a tactical option
	GameState.advance_power_sequence(sequence_index)


func _on_puzzle_reset() -> void:
	if is_destroyed: return
	is_activated = false
	_update_visuals()

func _update_visuals() -> void:
	if is_destroyed:
		core_mesh.material_override = _mat_destroyed
		light.visible = false
	elif is_activated:
		core_mesh.material_override = _mat_active
		light.visible = true
	else:
		core_mesh.material_override = _mat_inactive
		light.visible = false
