extends Resource
class_name LightingProfile

@export_category("Sky & Ambient")
@export var background_energy: float = 1.0
@export var ambient_light_color: Color = Color.WHITE
@export var ambient_light_energy: float = 1.0

@export_category("Volumetric Fog")
@export var volumetric_fog_enabled: bool = true
@export var volumetric_fog_density: float = 0.05
@export var volumetric_fog_albedo: Color = Color.WHITE
@export var volumetric_fog_emission: Color = Color.BLACK
@export var volumetric_fog_emission_energy: float = 1.0
@export var volumetric_fog_anisotropy: float = 0.2

@export_category("Global Illumination")
@export var sdfgi_enabled: bool = true
@export var sdfgi_bounce_feedback: float = 0.5
@export var sdfgi_energy: float = 1.0

@export_category("Main Directional Light")
@export var dir_light_color: Color = Color.WHITE
@export var dir_light_energy: float = 1.0
@export var dir_light_rotation: Vector3 = Vector3(-45, -45, 0)
@export var dir_light_shadow_enabled: bool = true

func apply_to_environment(env: Environment) -> void:
	if not env: return
	
	env.background_energy_multiplier = background_energy
	env.ambient_light_color = ambient_light_color
	env.ambient_light_energy = ambient_light_energy
	
	env.volumetric_fog_enabled = volumetric_fog_enabled
	env.volumetric_fog_density = volumetric_fog_density
	env.volumetric_fog_albedo = volumetric_fog_albedo
	env.volumetric_fog_emission = volumetric_fog_emission
	env.volumetric_fog_emission_energy = volumetric_fog_emission_energy
	env.volumetric_fog_anisotropy = volumetric_fog_anisotropy
	
	env.sdfgi_enabled = sdfgi_enabled
	env.sdfgi_bounce_feedback = sdfgi_bounce_feedback
	env.sdfgi_energy = sdfgi_energy

func apply_to_directional_light(light: DirectionalLight3D) -> void:
	if not light: return
	
	light.light_color = dir_light_color
	light.light_energy = dir_light_energy
	light.rotation_degrees = dir_light_rotation
	light.shadow_enabled = dir_light_shadow_enabled
