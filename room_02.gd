extends Node3D

@onready var power_core_mat: StandardMaterial3D = $PowerCore/MeshInstance3D.mesh.surface_get_material(0).duplicate()
@onready var core_light: OmniLight3D = $CoreLight
@onready var ambient_lights: Array[OmniLight3D] = [
	$AmbientLight1, $AmbientLight2, $AmbientLight3, $AmbientLight4
]
@onready var security_door: StaticBody3D = $SecurityDoor

func _ready() -> void:
	GameState.power_system_online.connect(_on_power_online)
	
	# Initial inactive state
	power_core_mat.emission_enabled = false
	$PowerCore/MeshInstance3D.material_override = power_core_mat
	core_light.visible = false
	for light in ambient_lights:
		light.light_energy = 0.5 # Dimmer initially

func _on_power_online() -> void:
	power_core_mat.emission_enabled = true
	core_light.visible = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	for light in ambient_lights:
		tween.tween_property(light, "light_energy", 2.0, 1.0)
	
	# Open security door by sliding it down
	tween.tween_property(security_door, "position:y", -2.5, 2.0)
	# Disable collision so player can walk through
	var collision = security_door.get_node("CollisionShape3D")
	if collision:
		collision.set_deferred("disabled", true)

	# Activate communication terminal
	var comm = get_node_or_null("CommTerminal")
	if comm and comm.has_method("power_on"):
		comm.power_on()
