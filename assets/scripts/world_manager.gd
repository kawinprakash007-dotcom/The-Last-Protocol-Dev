extends Node3D
class_name WorldManager

@export var day_length_seconds: float = 60.0
@export var sun_light: DirectionalLight3D
@export var environment: WorldEnvironment

@export_group("Colors")
@export var morning_sky_color: Color = Color(0.6, 0.8, 1.0)
@export var night_sky_color: Color = Color(0.02, 0.02, 0.05)
@export var morning_fog_color: Color = Color(0.7, 0.75, 0.8)
@export var night_fog_color: Color = Color(0.05, 0.05, 0.1)
@export var morning_ambient_color: Color = Color(0.9, 0.95, 1.0)
@export var night_ambient_color: Color = Color(0.1, 0.1, 0.2)

var time_elapsed: float = 0.0

func _ready():
	if not sun_light:
		push_warning("WorldManager: DirectionalLight3D not assigned.")
	if not environment:
		push_warning("WorldManager: WorldEnvironment not assigned.")

func _process(delta: float):
	time_elapsed += delta
	var day_progress = fmod(time_elapsed, day_length_seconds) / day_length_seconds
	
	if sun_light:
		# Rotate sun 360 degrees over the course of the day
		sun_light.rotation_degrees.x = lerp(-90.0, 270.0, day_progress)
		
		# Simple intensity curve (brightest at noon, dim at night)
		var intensity = clamp(sin(day_progress * PI), 0.0, 1.0)
		sun_light.light_energy = max(0.0, intensity * 2.0)
		
	if environment and environment.environment:
		var env = environment.environment
		
		var is_day = day_progress < 0.5
		var transition = 0.0
		
		if day_progress < 0.1: # Sunrise
			transition = day_progress / 0.1
		elif day_progress < 0.4: # Day
			transition = 1.0
		elif day_progress < 0.5: # Sunset
			transition = 1.0 - ((day_progress - 0.4) / 0.1)
		else: # Night
			transition = 0.0
			
		# Lerp colors based on transition
		if env.sky and env.sky.sky_material and env.sky.sky_material is ProceduralSkyMaterial:
			var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
			sky_mat.sky_top_color = night_sky_color.lerp(morning_sky_color, transition)
			sky_mat.sky_horizon_color = night_sky_color.lerp(morning_sky_color, transition).lerp(Color.WHITE, 0.2)
			
		env.ambient_light_color = night_ambient_color.lerp(morning_ambient_color, transition)
		env.ambient_light_energy = lerp(0.1, 1.0, transition)
		
		if env.volumetric_fog_enabled:
			env.volumetric_fog_albedo = night_fog_color.lerp(morning_fog_color, transition)
		elif env.fog_enabled:
			env.fog_light_color = night_fog_color.lerp(morning_fog_color, transition)
