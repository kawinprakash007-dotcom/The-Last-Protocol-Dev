@tool
extends RefCounted

const CG_PATH = "res://story/assets/lighting/color_grades/"
const LP_PATH = "res://story/assets/lighting/profiles/"

func _run():
	print("Starting Lighting Preset Generator...")
	
	# === COLOR GRADES ===
	# NOTE: exposure < 1.0 prevents white clipping.
	# tonemap_exposure maps to env.tonemap_exposure (range ~0.5-2.0).
	# contrast + saturation are adjustment values (1.0 = neutral).
	
	# ACT 1: warm amber optimism — lab origin, golden hour
	var act1 = ColorGrade.new()
	act1.exposure = 0.82
	act1.contrast = 1.08
	act1.saturation = 1.15
	act1.brightness = 1.0
	act1.glow_enabled = true
	act1.glow_intensity = 0.6
	act1.glow_bloom = 0.04
	_save_res(act1, CG_PATH + "ACT_1.tres")
	
	# ACT 2: cyan-gold futuristic — robot awakens, assembly montage
	var act2 = ColorGrade.new()
	act2.exposure = 0.80
	act2.contrast = 1.10
	act2.saturation = 1.20
	act2.brightness = 0.97
	act2.glow_enabled = true
	act2.glow_intensity = 0.9
	act2.glow_bloom = 0.08
	_save_res(act2, CG_PATH + "ACT_2.tres")
	
	# ACT 3: vibrant sky-blue city day — robot civilisation peak
	var act3 = ColorGrade.new()
	act3.exposure = 0.78
	act3.contrast = 1.15
	act3.saturation = 1.30
	act3.brightness = 0.95
	act3.glow_enabled = true
	act3.glow_intensity = 0.7
	act3.glow_bloom = 0.06
	_save_res(act3, CG_PATH + "ACT_3.tres")
	
	# ACT 4: cold blue authority — lab night, decision scene
	var act4 = ColorGrade.new()
	act4.exposure = 0.72
	act4.contrast = 1.12
	act4.saturation = 0.90
	act4.brightness = 0.90
	act4.glow_enabled = true
	act4.glow_intensity = 1.1
	act4.glow_bloom = 0.10
	_save_res(act4, CG_PATH + "ACT_4.tres")
	
	# ACT 5: red emergency — malfunction, system failure
	var act5 = ColorGrade.new()
	act5.exposure = 0.68
	act5.contrast = 1.35
	act5.saturation = 1.60
	act5.brightness = 0.85
	act5.glow_enabled = true
	act5.glow_intensity = 1.4
	act5.glow_bloom = 0.15
	_save_res(act5, CG_PATH + "ACT_5.tres")
	
	# ACT 6: near-monochrome ash — ruins aftermath
	var act6 = ColorGrade.new()
	act6.exposure = 0.65
	act6.contrast = 1.40
	act6.saturation = 0.30
	act6.brightness = 0.85
	act6.glow_enabled = false
	_save_res(act6, CG_PATH + "ACT_6.tres")
	
	# ACT 7: cold blue-grey — realization, underground resistance
	var act7 = ColorGrade.new()
	act7.exposure = 0.70
	act7.contrast = 1.15
	act7.saturation = 0.55
	act7.brightness = 0.88
	act7.glow_enabled = true
	act7.glow_intensity = 0.5
	act7.glow_bloom = 0.03
	_save_res(act7, CG_PATH + "ACT_7.tres")
	
	# ACT 8: warm determined neutral — hero rising
	var act8 = ColorGrade.new()
	act8.exposure = 0.80
	act8.contrast = 1.12
	act8.saturation = 1.05
	act8.brightness = 0.96
	act8.glow_enabled = true
	act8.glow_intensity = 0.8
	act8.glow_bloom = 0.05
	_save_res(act8, CG_PATH + "ACT_8.tres")

	# === LIGHTING PROFILES ===
	
	var p_lab_day = LightingProfile.new()
	p_lab_day.dir_light_color = Color(1.0, 0.92, 0.78)   # warm amber ceiling key
	p_lab_day.dir_light_energy = 0.80
	p_lab_day.ambient_light_energy = 0.30
	p_lab_day.ambient_light_color = Color(0.7, 0.85, 1.0) # cool blue fill
	p_lab_day.volumetric_fog_enabled = true
	p_lab_day.volumetric_fog_density = 0.008
	_save_res(p_lab_day, LP_PATH + "LAB_DAY.tres")
	
	var p_lab_night = LightingProfile.new()
	p_lab_night.dir_light_energy = 0.12
	p_lab_night.dir_light_color = Color(0.25, 0.40, 0.90)
	p_lab_night.ambient_light_energy = 0.15
	p_lab_night.ambient_light_color = Color(0.10, 0.20, 0.50)
	p_lab_night.volumetric_fog_enabled = true
	p_lab_night.volumetric_fog_density = 0.018
	p_lab_night.volumetric_fog_albedo = Color(0.05, 0.10, 0.30)
	_save_res(p_lab_night, LP_PATH + "LAB_NIGHT.tres")
	
	var p_city_day = LightingProfile.new()
	p_city_day.dir_light_energy = 0.90
	p_city_day.dir_light_color = Color(1.0, 0.96, 0.90)
	p_city_day.ambient_light_energy = 0.40
	p_city_day.ambient_light_color = Color(0.60, 0.80, 1.0) # sky-blue ambient
	p_city_day.volumetric_fog_enabled = true
	p_city_day.volumetric_fog_density = 0.004
	_save_res(p_city_day, LP_PATH + "CITY_DAY.tres")
	
	var p_city_night = LightingProfile.new()
	p_city_night.dir_light_energy = 0.08
	p_city_night.dir_light_color = Color(0.20, 0.25, 0.60)
	p_city_night.ambient_light_energy = 0.12
	p_city_night.ambient_light_color = Color(0.10, 0.12, 0.35)
	p_city_night.volumetric_fog_enabled = true
	p_city_night.volumetric_fog_density = 0.04
	p_city_night.volumetric_fog_albedo = Color(0.08, 0.08, 0.18)
	_save_res(p_city_night, LP_PATH + "CITY_NIGHT.tres")
	
	var p_city_collapse = LightingProfile.new()
	p_city_collapse.dir_light_energy = 0.30
	p_city_collapse.dir_light_color = Color(0.95, 0.40, 0.20) # orange fire glow
	p_city_collapse.ambient_light_energy = 0.08
	p_city_collapse.ambient_light_color = Color(0.40, 0.10, 0.05)
	p_city_collapse.volumetric_fog_enabled = true
	p_city_collapse.volumetric_fog_density = 0.14 # thick smoke
	p_city_collapse.volumetric_fog_albedo = Color(0.35, 0.22, 0.18)
	_save_res(p_city_collapse, LP_PATH + "CITY_COLLAPSE.tres")
	
	var p_emergency = LightingProfile.new()
	p_emergency.dir_light_energy = 0.15
	p_emergency.dir_light_color = Color(0.80, 0.10, 0.10)
	p_emergency.ambient_light_energy = 0.08
	p_emergency.ambient_light_color = Color(0.50, 0.05, 0.05)
	p_emergency.volumetric_fog_enabled = true
	p_emergency.volumetric_fog_density = 0.06
	p_emergency.volumetric_fog_emission = Color(0.80, 0.0, 0.0)
	p_emergency.volumetric_fog_emission_energy = 0.35
	_save_res(p_emergency, LP_PATH + "EMERGENCY.tres")
	
	var p_hero_reveal = LightingProfile.new()
	p_hero_reveal.dir_light_energy = 1.0
	p_hero_reveal.dir_light_color = Color(1.0, 0.90, 0.80)
	p_hero_reveal.dir_light_rotation = Vector3(-35, 160, 0) # dramatic rim from behind
	p_hero_reveal.ambient_light_energy = 0.50
	p_hero_reveal.ambient_light_color = Color(0.50, 0.60, 0.80)
	p_hero_reveal.volumetric_fog_enabled = true
	p_hero_reveal.volumetric_fog_density = 0.025
	_save_res(p_hero_reveal, LP_PATH + "HERO_REVEAL.tres")
	
	print("Lighting generation complete!")

func _save_res(res: Resource, path: String) -> void:
	var err = ResourceSaver.save(res, path)
	if err != OK:
		printerr("Failed to save resource to: " + path)

