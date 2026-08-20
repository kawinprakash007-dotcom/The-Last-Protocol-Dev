@tool
extends RefCounted

const SCIFI_PATH = "res://story/assets/environments/laboratory/modular_scifi/glTF/"
const OUTPUT_PATH = "res://story/cinematics/environments/laboratory.tscn"

func _run():
	print("Starting Laboratory Generator...")
	var root = Node3D.new()
	root.name = "LaboratoryEnvironment"

	# Build Main Lab Floor
	_build_floor(root, "Platform_Squares.gltf", Vector3(0, 0, 0), 10, 10, 4.0)

	# Build Observation Area (Raised)
	_build_floor(root, "Platform_Metal.gltf", Vector3(-20, 4, 0), 4, 10, 4.0)

	# Build Walls (Simple perimeter)
	_build_walls(root, "WallAstra_Straight.gltf", Vector3(0, 0, 0), 10, 10, 4.0)

	# Engineering Bay (Lots of cables, pipes, vents)
	_populate_area(root, "EngineeringBay", Vector3(10, 0, -10), [
		{"model": "Prop_Vent_Big.gltf", "count": 2, "spacing": 3.0},
		{"model": "Prop_Cable_1.gltf", "count": 5, "spacing": 1.5},
		{"model": "Column_Pipes.gltf", "count": 3, "spacing": 2.5}
	])

	# Robot Assembly Area
	_populate_area(root, "RobotAssemblyArea", Vector3(0, 0, 0), [
		{"model": "Platform_CenterPlate.gltf", "count": 1, "spacing": 0.0},
		{"model": "Prop_Rail_Incline_Long_R.gltf", "count": 2, "spacing": 4.0},
		{"model": "Prop_Light_Floor.gltf", "count": 4, "spacing": 2.0}
	])

	# Holographic Workstation
	_populate_area(root, "HolographicWorkstation", Vector3(-10, 0, 10), [
		{"model": "Prop_Computer.gltf", "count": 3, "spacing": 1.5},
		{"model": "Prop_ItemHolder.gltf", "count": 1, "spacing": 0.0}
	])
	
	# Robot Storage
	_populate_area(root, "RobotStorage", Vector3(10, 0, 10), [
		{"model": "Prop_Crate3.gltf", "count": 4, "spacing": 2.0},
		{"model": "Prop_Crate4.gltf", "count": 3, "spacing": 2.0},
		{"model": "Prop_Barrel_Large.gltf", "count": 5, "spacing": 1.0}
	])

	# Lighting
	_add_lighting(root)

	var packed_scene = PackedScene.new()
	packed_scene.pack(root)
	ResourceSaver.save(packed_scene, OUTPUT_PATH)
	
	_generate_preview_scene()
	
	print("Laboratory environment saved to " + OUTPUT_PATH)

func _load_model(model_name: String) -> PackedScene:
	var subfolders = {
		"Platform_Squares.gltf": "Platforms/",
		"Platform_Metal.gltf": "Platforms/",
		"Platform_CenterPlate.gltf": "Platforms/",
		"WallAstra_Straight.gltf": "Walls/",
		"Column_Pipes.gltf": "Columns/",
		"Prop_Vent_Big.gltf": "Props/",
		"Prop_Cable_1.gltf": "Props/",
		"Prop_Rail_Incline_Long_R.gltf": "Props/",
		"Prop_Light_Floor.gltf": "Props/",
		"Prop_Computer.gltf": "Props/",
		"Prop_ItemHolder.gltf": "Props/",
		"Prop_Crate3.gltf": "Props/",
		"Prop_Crate4.gltf": "Props/",
		"Prop_Barrel_Large.gltf": "Props/",
	}
	var folder = subfolders.get(model_name, "")
	var path = SCIFI_PATH + folder + model_name
	if not ResourceLoader.exists(path):
		print("Warning: Model not found at " + path)
		return null
	return load(path)

func _build_floor(parent: Node3D, model_name: String, start_pos: Vector3, width: int, depth: int, size: float):
	var model = _load_model(model_name)
	if not model: return
	
	var floor_node = Node3D.new()
	floor_node.name = "Floor_" + model_name.replace(".gltf", "")
	parent.add_child(floor_node)
	floor_node.owner = parent
	
	for x in range(-width/2, width/2):
		for z in range(-depth/2, depth/2):
			var inst = model.instantiate()
			floor_node.add_child(inst)
			inst.owner = parent
			inst.position = start_pos + Vector3(x * size, 0, z * size)

func _build_walls(parent: Node3D, model_name: String, center: Vector3, width: int, depth: int, size: float):
	var model = _load_model(model_name)
	if not model: return
	
	var walls_node = Node3D.new()
	walls_node.name = "Walls"
	parent.add_child(walls_node)
	walls_node.owner = parent
	
	# simplified wall perimeter
	var w2 = width / 2.0
	var d2 = depth / 2.0
	
	for x in range(-width/2, width/2):
		# Back wall
		var inst1 = model.instantiate()
		walls_node.add_child(inst1)
		inst1.owner = parent
		inst1.position = center + Vector3(x * size, 0, -d2 * size)
		# Front wall
		var inst2 = model.instantiate()
		walls_node.add_child(inst2)
		inst2.owner = parent
		inst2.position = center + Vector3(x * size, 0, d2 * size)
		inst2.rotation_degrees.y = 180

	for z in range(-depth/2, depth/2):
		# Left wall
		var inst3 = model.instantiate()
		walls_node.add_child(inst3)
		inst3.owner = parent
		inst3.position = center + Vector3(-w2 * size, 0, z * size)
		inst3.rotation_degrees.y = 90
		# Right wall
		var inst4 = model.instantiate()
		walls_node.add_child(inst4)
		inst4.owner = parent
		inst4.position = center + Vector3(w2 * size, 0, z * size)
		inst4.rotation_degrees.y = -90

func _populate_area(parent: Node3D, area_name: String, pos: Vector3, items: Array):
	var area_node = Node3D.new()
	area_node.name = area_name
	parent.add_child(area_node)
	area_node.owner = parent
	area_node.position = pos
	
	var offset_x = 0.0
	for item in items:
		var model = _load_model(item["model"])
		if not model: continue
		for i in range(item["count"]):
			var inst = model.instantiate()
			area_node.add_child(inst)
			inst.owner = parent
			inst.position = Vector3(offset_x, 0, (randf() - 0.5) * item["spacing"] * 2.0)
			inst.rotation_degrees.y = randf() * 360.0
			offset_x += item["spacing"]

func _add_lighting(parent: Node3D):
	var lights = Node3D.new()
	lights.name = "Lighting"
	parent.add_child(lights)
	lights.owner = parent
	
	# Main overhead cool light
	var omni = OmniLight3D.new()
	omni.name = "MainOverheadLight"
	omni.light_color = Color(0.8, 0.9, 1.0)
	omni.light_energy = 2.0
	omni.omni_range = 30.0
	omni.position = Vector3(0, 10, 0)
	omni.shadow_enabled = true
	lights.add_child(omni)
	omni.owner = parent

	# Workstation screen illumination
	var spot = SpotLight3D.new()
	spot.name = "WorkstationScreenLight"
	spot.light_color = Color(0.2, 0.8, 1.0)
	spot.light_energy = 5.0
	spot.position = Vector3(-10, 2, 10)
	spot.spot_range = 10.0
	spot.shadow_enabled = true
	lights.add_child(spot)
	spot.owner = parent

	# Assembly localized warm light
	var assembly_light = SpotLight3D.new()
	assembly_light.name = "AssemblyWorkLight"
	assembly_light.light_color = Color(1.0, 0.8, 0.6)
	assembly_light.light_energy = 4.0
	assembly_light.position = Vector3(0, 6, 0)
	assembly_light.rotation_degrees.x = -90
	assembly_light.spot_range = 15.0
	assembly_light.shadow_enabled = true
	lights.add_child(assembly_light)
	assembly_light.owner = parent
func _generate_preview_scene():
	var root = Node3D.new()
	root.name = "LaboratoryPreview"
	
	var env_scene = load(OUTPUT_PATH)
	if env_scene:
		var env_inst = env_scene.instantiate()
		root.add_child(env_inst)
		env_inst.owner = root
	
	var cameras = Node3D.new()
	cameras.name = "Cameras"
	root.add_child(cameras)
	cameras.owner = root
	
	# wide establishing
	var cam1 = Camera3D.new()
	cam1.name = "Cam_WideEstablishing"
	cam1.position = Vector3(0, 8, 12)
	cam1.rotation_degrees.x = -15
	cameras.add_child(cam1)
	cam1.owner = root
	
	# hero workstation
	var cam2 = Camera3D.new()
	cam2.name = "Cam_HeroWorkstation"
	cam2.position = Vector3(-8, 2, 8)
	cam2.rotation_degrees.y = 45
	cameras.add_child(cam2)
	cam2.owner = root
	
	# robot assembly
	var cam3 = Camera3D.new()
	cam3.name = "Cam_RobotAssembly"
	cam3.position = Vector3(2, 2, 2)
	cam3.rotation_degrees.y = 135
	cameras.add_child(cam3)
	cam3.owner = root
	
	# close-up machinery
	var cam4 = Camera3D.new()
	cam4.name = "Cam_CloseUpMachinery"
	cam4.position = Vector3(10, 1.5, -9)
	cam4.rotation_degrees.y = -45
	cameras.add_child(cam4)
	cam4.owner = root
	
	# hero face
	var cam5 = Camera3D.new()
	cam5.name = "Cam_HeroFace"
	cam5.position = Vector3(-10, 1.7, 9)
	cam5.rotation_degrees.y = -135
	cameras.add_child(cam5)
	cam5.owner = root
	
	# robot face
	var cam6 = Camera3D.new()
	cam6.name = "Cam_RobotFace"
	cam6.position = Vector3(0, 1.8, 1)
	cam6.rotation_degrees.y = 180
	cameras.add_child(cam6)
	cam6.owner = root
	
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://story/cinematics/laboratory_preview.tscn")
