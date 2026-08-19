extends Node3D

@onready var power_core_mat: StandardMaterial3D = $PowerCore/MeshInstance3D.mesh.surface_get_material(0).duplicate()
@onready var core_light: OmniLight3D = $CoreLight
@onready var ambient_lights: Array[OmniLight3D] = [
	$AmbientLight1, $AmbientLight2, $AmbientLight3, $AmbientLight4
]
@onready var security_door: StaticBody3D = $SecurityDoor

@onready var rack_indicators: Array[MeshInstance3D] = [
	$ServerRack1/ServerRackVisual/Rack_PowerIndicators,
	$ServerRack2/ServerRackVisual/Rack_PowerIndicators,
	$ServerRack3/ServerRackVisual/Rack_PowerIndicators,
	$ServerRack4/ServerRackVisual/Rack_PowerIndicators
]
var rack_materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	GameState.power_system_online.connect(_on_power_online)
	
	# Initial inactive state
	power_core_mat.emission_enabled = false
	$PowerCore/MeshInstance3D.material_override = power_core_mat
	core_light.visible = false
	for light in ambient_lights:
		light.light_energy = 0.5 # Dimmer initially

	for indicator in rack_indicators:
		if indicator and indicator.mesh:
			for i in range(indicator.mesh.get_surface_count()):
				var mat = indicator.mesh.surface_get_material(i).duplicate()
				mat.emission_energy_multiplier = 0.0
				indicator.set_surface_override_material(i, mat)
				rack_materials.append(mat)

func _on_power_online() -> void:
	power_core_mat.emission_enabled = true
	core_light.visible = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	for light in ambient_lights:
		tween.tween_property(light, "light_energy", 2.0, 1.0)
	
	for mat in rack_materials:
		tween.tween_property(mat, "emission_energy_multiplier", 5.0, 1.0)
	
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
