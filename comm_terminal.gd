class_name CommTerminal
extends Interactable

## Communication Terminal — initially offline.
## Powered on by Room02 when auxiliary power is restored.
## Player interacts to trigger comms activation and the survivor signal.

var is_powered: bool = false
var is_activated: bool = false

@onready var screen_mesh: MeshInstance3D = $ScreenMesh
@onready var light: OmniLight3D = $OmniLight3D

var _mat_off: StandardMaterial3D
var _mat_on: StandardMaterial3D

func _ready() -> void:
	_mat_off = StandardMaterial3D.new()
	_mat_off.albedo_color = Color(0.05, 0.05, 0.05)

	_mat_on = StandardMaterial3D.new()
	_mat_on.albedo_color = Color(0.1, 0.9, 0.3)
	_mat_on.emission_enabled = true
	_mat_on.emission = Color(0.1, 0.9, 0.3)
	_mat_on.emission_energy_multiplier = 1.5

	# Start dark
	screen_mesh.material_override = _mat_off
	light.visible = false

func power_on() -> void:
	is_powered = true
	screen_mesh.material_override = _mat_on
	light.visible = true

func interact() -> void:
	if not is_powered:
		return
	if is_activated:
		return
	is_activated = true
	GameState.activate_comms()
