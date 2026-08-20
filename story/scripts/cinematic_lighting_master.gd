extends Node
class_name CinematicLightingMaster

@export var current_environment: WorldEnvironment
@export var current_directional_light: DirectionalLight3D

const COLOR_GRADES_PATH = "res://story/assets/lighting/color_grades/"
const LIGHTING_PROFILES_PATH = "res://story/assets/lighting/profiles/"

func apply_color_grade(act_name: String) -> void:
	var path = COLOR_GRADES_PATH + act_name + ".tres"
	if ResourceLoader.exists(path):
		var grade: ColorGrade = load(path)
		if current_environment and grade:
			grade.apply_to_environment(current_environment.environment, current_environment)
			print("Applied Color Grade: " + act_name)
	else:
		printerr("Color Grade not found: " + path)

func apply_lighting_profile(profile_name: String) -> void:
	var path = LIGHTING_PROFILES_PATH + profile_name + ".tres"
	if ResourceLoader.exists(path):
		var profile: LightingProfile = load(path)
		if profile:
			if current_environment:
				profile.apply_to_environment(current_environment.environment)
			if current_directional_light:
				profile.apply_to_directional_light(current_directional_light)
			print("Applied Lighting Profile: " + profile_name)
	else:
		printerr("Lighting Profile not found: " + path)

func setup_from_scene(env: WorldEnvironment, dlight: DirectionalLight3D) -> void:
	current_environment = env
	current_directional_light = dlight
