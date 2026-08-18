class_name PowerRelay
extends Interactable

@export var sequence_index: int = 0
var is_activated: bool = false

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D

# Simple visual materials
var _mat_inactive: StandardMaterial3D
var _mat_active: StandardMaterial3D

func _ready() -> void:
	GameState.power_puzzle_reset.connect(_on_puzzle_reset)
	
	_mat_inactive = StandardMaterial3D.new()
	_mat_inactive.albedo_color = Color(0.1, 0.1, 0.1)
	
	_mat_active = StandardMaterial3D.new()
	_mat_active.albedo_color = Color(1.0, 0.6, 0.1)
	_mat_active.emission_enabled = true
	_mat_active.emission = Color(1.0, 0.6, 0.1)
	_mat_active.emission_energy_multiplier = 2.0
	
	_update_visuals()

func interact() -> void:
	if is_activated or GameState.power_restored:
		return
	
	print("INTERACT: Relay ", sequence_index)
	is_activated = true
	_update_visuals()
	
	# Attempt to advance sequence
	GameState.advance_power_sequence(sequence_index)

func _on_puzzle_reset() -> void:
	is_activated = false
	_update_visuals()

func _update_visuals() -> void:
	if is_activated:
		mesh_instance.material_override = _mat_active
		light.visible = true
	else:
		mesh_instance.material_override = _mat_inactive
		light.visible = false
