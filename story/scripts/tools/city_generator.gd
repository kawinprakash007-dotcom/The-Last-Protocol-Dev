@tool
extends RefCounted

const CITY_PATH = "res://story/assets/environments/city/GLB format/"
const OUTPUT_PATH = "res://story/cinematics/environments/base_city.tscn"

func _run():
	print("Starting City Generator...")
	var root = Node3D.new()
	root.name = "CityEnvironment"
	root.set_script(load("res://story/scripts/city_state_manager.gd"))

	# Create Main Structure
	var env = Node3D.new()
	env.name = "Environment"
	root.add_child(env)
	env.owner = root
	
	var we = WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var sky_mat = ProceduralSkyMaterial.new()
	var sky = Sky.new()
	sky.sky_material = sky_mat
	var env_res = Environment.new()
	env_res.sky = sky
	env_res.background_mode = Environment.BG_SKY
	we.environment = env_res
	env.add_child(we)
	we.owner = root

	var main_light = DirectionalLight3D.new()
	main_light.name = "MainLight"
	main_light.rotation_degrees.x = -45
	main_light.shadow_enabled = true
	env.add_child(main_light)
	main_light.owner = root

	var vfx = Node3D.new()
	vfx.name = "VFX"
	root.add_child(vfx)
	vfx.owner = root
	
	var collapse_particles = GPUParticles3D.new()
	collapse_particles.name = "CollapseParticles"
	vfx.add_child(collapse_particles)
	collapse_particles.owner = root

	var lighting = Node3D.new()
	lighting.name = "Lighting"
	root.add_child(lighting)
	lighting.owner = root
	
	var night_lights = Node3D.new()
	night_lights.name = "NightLights"
	lighting.add_child(night_lights)
	night_lights.owner = root

	var infra = Node3D.new()
	infra.name = "Infrastructure"
	root.add_child(infra)
	infra.owner = root

	var advanced_tech = Node3D.new()
	advanced_tech.name = "AdvancedTech"
	infra.add_child(advanced_tech)
	advanced_tech.owner = root

	var flying_cars = Node3D.new()
	flying_cars.name = "FlyingCars"
	infra.add_child(flying_cars)
	flying_cars.owner = root

	var robots = Node3D.new()
	robots.name = "Robots"
	infra.add_child(robots)
	robots.owner = root

	var construction = Node3D.new()
	construction.name = "Construction"
	infra.add_child(construction)
	construction.owner = root

	var details = Node3D.new()
	details.name = "Details"
	root.add_child(details)
	details.owner = root
	
	var holograms = Node3D.new()
	holograms.name = "Holograms"
	details.add_child(holograms)
	holograms.owner = root

	var skyscrapers = Node3D.new()
	skyscrapers.name = "Skyscrapers"
	root.add_child(skyscrapers)
	skyscrapers.owner = root

	# Populate City Grid
	var buildings = ["building-a.glb", "building-b.glb", "building-c.glb", "building-d.glb", "building-e.glb", "building-f.glb"]
	var grid_size = 5
	var spacing = 15.0
	for x in range(-grid_size, grid_size):
		for z in range(-grid_size, grid_size):
			var b = buildings[randi() % buildings.size()]
			var path = CITY_PATH + b
			if ResourceLoader.exists(path):
				var pscene = load(path)
				var inst = pscene.instantiate()
				inst.position = Vector3(x * spacing, 0, z * spacing)
				inst.rotation_degrees.y = (randi() % 4) * 90
				skyscrapers.add_child(inst)
				inst.owner = root

	var packed_scene = PackedScene.new()
	packed_scene.pack(root)
	ResourceSaver.save(packed_scene, OUTPUT_PATH)
	
	_generate_preview_scene()
	
	print("City environment saved to " + OUTPUT_PATH)

func _generate_preview_scene():
	var root = Node3D.new()
	root.name = "CityPreview"
	
	var env_scene = load(OUTPUT_PATH)
	if env_scene:
		var env_inst = env_scene.instantiate()
		root.add_child(env_inst)
		env_inst.owner = root
	
	var cameras = Node3D.new()
	cameras.name = "Cameras"
	root.add_child(cameras)
	cameras.owner = root
	
	var cam1 = Camera3D.new()
	cam1.name = "Cam_CityWide"
	cam1.position = Vector3(0, 50, 100)
	cam1.rotation_degrees.x = -15
	cameras.add_child(cam1)
	cam1.owner = root
	
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://story/cinematics/city_preview.tscn")
