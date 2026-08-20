extends Node3D

const NEXT_SCENE := "res://main.tscn"
const FIRST_OBJECTIVE := "Reach the communications hub on Sub-Level Two\nbefore the lockdown seals the corridor."
const TRANSITION_FADE_DURATION := 0.8

# Spawner scenes
const HERO_SCENE := "res://story/cinematics/characters/cinematic_hero.tscn"
const ROBOT_SCENE := "res://story/cinematics/characters/cinematic_robot.tscn"
const LAB_SCENE := "res://story/cinematics/laboratory_preview.tscn"
const CITY_SCENE := "res://story/cinematics/city_preview.tscn"

# Visual plates
const IMG_CAR_FRONT := "res://story/assets/vehicles/flying_car_front.jpg"
const IMG_CAR_BACK := "res://story/assets/vehicles/flying_car_back.jpg"
const IMG_CROWD := "res://story/assets/characters/npcs/civilian_crowd_running.jpg"
const IMG_HOLO_AD := "res://story/assets/ui/holographic_advertisement.jpg"

@onready var _fade: CinematicFade = $CinematicFade
@onready var _objective_hud: Node = $ObjectiveHUD
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _video_player: VideoStreamPlayer = $VideoLayer/VideoStreamPlayer

var _transitioning: bool = false
var _ui_master: CanvasLayer = null
var _lighting_master: CinematicLightingMaster = null

# Spawned human/robot node references for programmatic animations
var _hero_lab: Node3D = null
var _robot_assembly: Node3D = null
var _hero_control: Node3D = null
var _robot_police: Node3D = null
var _civilian_run: Node3D = null
var _hero_ruins: Node3D = null
var _robot_broken: Node3D = null

# True 3D Population references
var _city_npcs: Array[Node3D] = []
var _city_robots: Array[Node3D] = []
var _lab_npcs: Array[Node3D] = []
var _lab_robots: Array[Node3D] = []
var _disaster_npcs: Array[Node3D] = []
var _disaster_robots: Array[Node3D] = []
var _flying_cars: Array[Node3D] = []
var _flying_car_tweens: Array[Tween] = []

const VEHICLE_SCENE := "res://story/cinematics/vehicles/flying_car_3d.tscn"

func _ready() -> void:
	if _video_player != null:
		_video_player.modulate.a = 0.0
		_video_player.stop()

	if _fade != null:
		_fade.fade_to_black(0.0)

	if _objective_hud != null:
		_objective_hud.visible = false

	# Wire story events and cinematic completion.
	EventBus.story_event_triggered.connect(_on_story_event_triggered)
	EventBus.cinematic_ui_event.connect(_on_ui_event)
	EventBus.cinematic_finished.connect(_on_cinematic_finished, CONNECT_ONE_SHOT)

	# Replace visuals
	_replace_visuals()

	# Wait one frame so all nodes have finished _ready()
	await get_tree().process_frame

	# Mount screenshot helper if environment variable is set
	if OS.get_environment("CAPTURE_SCREENSHOTS") == "true":
		var helper_script = load("res://story/scripts/tools/screenshot_helper.gd")
		if helper_script:
			var helper = Node.new()
			helper.set_script(helper_script)
			add_child(helper)

	# Play the final canonical movie timeline sequence
	var final_builder_script = load("res://story/cinematics/final_opening_builder.gd")
	var sequence: CinematicSequence = final_builder_script.build()
	sequence.on_end_scene = "" # Do not destroy main.tscn
	CinematicManager.play_sequence(sequence)
	# Show cinematic letterbox bars
	EventBus.letterbox_toggled.emit(true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		if event.is_action_pressed("ui_cancel") or event.keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]:
			_skip_cinematic()

func _skip_cinematic() -> void:
	if _transitioning:
		return
	if CinematicManager.is_waiting_for_authorization():
		print("  [SKIP] Ignored: Creator authorization required.")
		return
	CinematicManager.stop()

func _replace_visuals() -> void:
	# 1. Instantiate modular environment preview scenes (which contain layout + cameras)
	var lab_res = load(LAB_SCENE)
	var lab_inst = null
	if lab_res:
		lab_inst = lab_res.instantiate()
		$Environment/Zone1.add_child(lab_inst)
		# Hide primitive desk/hologram
		if $Environment/Zone1.has_node("EngineeringTable"):
			$Environment/Zone1/EngineeringTable.visible = false
		if $Environment/Zone1.has_node("HoloBlueprint"):
			$Environment/Zone1/HoloBlueprint.visible = false
		if $Environment/Zone1.has_node("AssemblyPlatform"):
			$Environment/Zone1/AssemblyPlatform.visible = false

	var city_res = load(CITY_SCENE)
	var city_inst = null
	if city_res:
		city_inst = city_res.instantiate()
		$Environment/Zone3.add_child(city_inst)
		# Hide primitive city geometry
		if $Environment/Zone3.has_node("Skyscraper1"):
			$Environment/Zone3/Skyscraper1.visible = false
		if $Environment/Zone3.has_node("Skyscraper2"):
			$Environment/Zone3/Skyscraper2.visible = false
		if $Environment/Zone3.has_node("FlyingCar1"):
			$Environment/Zone3/FlyingCar1.visible = false
		if $Environment/Zone3.has_node("FlyingCar2"):
			$Environment/Zone3/FlyingCar2.visible = false

	# Reparent camera nodes from preview scenes to CinematicMarkers
	var markers_parent = get_node_or_null("CinematicMarkers")
	if markers_parent:
		if lab_inst:
			var lab_cameras = lab_inst.get_node_or_null("Cameras")
			if lab_cameras:
				for cam in lab_cameras.get_children():
					cam.reparent(markers_parent)
		if city_inst:
			var city_cameras = city_inst.get_node_or_null("Cameras")
			if city_cameras:
				for cam in city_cameras.get_children():
					cam.reparent(markers_parent)

		# Ensure all required markers are present (create dynamically if missing)
		var defaults = {
			# Legacy markers (kept for backward compatibility)
			"MarkerDeskCU": Vector3(-1.0, 1.5, -0.2),
			"MarkerDeskMCU": Vector3(-1.2, 1.6, 0.2),
			"MarkerDeskWide": Vector3(-2.5, 2.0, 1.5),
			"MarkerEntrance": Vector3(0.0, 2.0, 5.0),
			"MarkerHeroic": Vector3(150.0, 2.0, 2.0),
			# ── Phase 14B premium camera markers ──────────────────────────────
			# SHOT 01: City aerial — very high above the skyline, looking down at 15°
			"Cam_CityAerial":        Vector3(0.0,  80.0, 40.0),
			# SHOT 02: City street — low-angle dolly along boulevard (Zone3)
			"Cam_CityStreet":        Vector3(-8.0,  2.5, 18.0),
			# SHOT 03: Lab wide — elevated view into lab interior from Zone1
			"Cam_LabWide":           Vector3(-10.0,  8.0, 12.0),
			# SHOT 04: Hero tracking — side angle, camera tracks hero walk
			"Cam_HeroTrack":         Vector3(3.0,   1.6,  5.0),
			# SHOT 05: Hero face CU — MCU pushed in from the front
			"Cam_HeroFaceCU":        Vector3(-0.5,  1.7,  1.8),
			# SHOT 06: Assembly wide — elevated crane view over robot assembly
			"Cam_AssemblyWide":      Vector3(8.0,   5.0,  8.0),
			# SHOT 07: Weld CU — extreme macro on robotic arm
			"Cam_WeldCU":            Vector3(5.0,   2.0,  1.5),
			# SHOT 08: Activation CU — push-in toward robot face
			"Cam_ActivationCU":      Vector3(4.0,   1.8,  3.5),
			# SHOT 09: Handshake orbit — start of orbit arc around hero+robot
			"Cam_HandshakeOrbit":    Vector3(2.0,   1.5,  3.0),
			# SHOT 10: Montage city — high wide city view for revolution montage
			"Cam_MontageA":          Vector3(0.0,  12.0, 30.0),
			# SHOT 11: Observation platform — camera behind hero (Zone3 elevated)
			"Cam_ObservationBehind": Vector3(0.0,   5.0,  8.0),
			"Cam_ObservationFront":  Vector3(0.0,   5.0, -5.0)
		}
		for m_name in defaults:
			if not markers_parent.has_node(m_name):
				var m = Marker3D.new()
				m.name = m_name
				m.position = defaults[m_name]
				markers_parent.add_child(m)

	# 2. Hide CSG Box humanoids
	for path in [
		"Environment/Zone1/HeroLab",
		"Environment/Zone1/Scientist1",
		"Environment/Zone1/RobotAssembly",
		"Environment/Zone4/HeroControl",
		"Environment/Zone5/CivilianRun",
		"Environment/Zone5/RobotPoliceAttack",
		"Environment/Zone6/RobotBroken",
		"Environment/Zone6/HeroRuins"
	]:
		var n = get_node_or_null(path)
		if n:
			n.visible = false

	# 3. Spawn real human/robot characters
	var hero_res = load(HERO_SCENE)
	var robot_res = load(ROBOT_SCENE)

	if hero_res:
		_hero_lab = hero_res.instantiate()
		_hero_lab.position = Vector3(0, 0, -0.6)
		$Environment/Zone1.add_child(_hero_lab)

		_hero_control = hero_res.instantiate()
		_hero_control.position = Vector3(0, 0, -0.8)
		$Environment/Zone4.add_child(_hero_control)

		_hero_ruins = hero_res.instantiate()
		_hero_ruins.position = Vector3(0, 0, 0)
		$Environment/Zone6.add_child(_hero_ruins)

		# Civilian running NPC
		_civilian_run = hero_res.instantiate()
		_civilian_run.position = Vector3(-2, 0, 3)
		_civilian_run.rotation_degrees.y = -135
		$Environment/Zone5.add_child(_civilian_run)

	if robot_res:
		_robot_assembly = robot_res.instantiate()
		_robot_assembly.position = Vector3(5, 1.0, 0.2)
		$Environment/Zone1.add_child(_robot_assembly)

		_robot_police = robot_res.instantiate()
		_robot_police.position = Vector3(3, 0, 1)
		_robot_police.rotation_degrees.y = 30
		$Environment/Zone5.add_child(_robot_police)

		_robot_broken = robot_res.instantiate()
		_robot_broken.position = Vector3(-2, 0.2, 1)
		_robot_broken.rotation_degrees.y = 45
		$Environment/Zone6.add_child(_robot_broken)

	# 4. Set up 3D prologue population and vehicles
	_setup_3d_prologue()

	# 5. Set up UI master dynamically
	var ui_master_script = load("res://story/scripts/cinematic_ui_master.gd")
	if ui_master_script:
		_ui_master = CanvasLayer.new()
		_ui_master.set_script(ui_master_script)
		_ui_master.name = "CinematicUI"
		add_child(_ui_master)

	# 6. Set up Lighting master dynamically
	var lighting_script = load("res://story/scripts/cinematic_lighting_master.gd")
	if lighting_script:
		_lighting_master = CinematicLightingMaster.new()
		_lighting_master.name = "LightingMaster"
		add_child(_lighting_master)
		_lighting_master.setup_from_scene($WorldEnvironment, $Environment/Lights/FillLight)
		_lighting_master.apply_color_grade("ACT_1")
		_lighting_master.apply_lighting_profile("LAB_DAY")

func _setup_3d_prologue() -> void:
	var hero_res = load(HERO_SCENE)
	var robot_res = load(ROBOT_SCENE)
	var car_res = load(VEHICLE_SCENE)

	# 1. Spawn 3D Flying Cars in Zone 3 (City Skyline)
	if car_res:
		var parent_city = $Environment/Zone3
		# Traffic lane positions
		var lanes = [
			{"start": Vector3(-25, 8, 4), "end": Vector3(25, 8, 4), "rot": 0.0},
			{"start": Vector3(25, 6, -2), "end": Vector3(-25, 6, -2), "rot": 180.0},
			{"start": Vector3(-20, 10, -5), "end": Vector3(20, 10, -5), "rot": 0.0},
			{"start": Vector3(20, 11, 2), "end": Vector3(-20, 11, 2), "rot": 180.0},
			{"start": Vector3(-15, 5, 8), "end": Vector3(15, 9, -8), "rot": -25.0}
		]
		for i in range(lanes.size()):
			var lane = lanes[i]
			var car = car_res.instantiate() as Node3D
			car.position = lane.start
			car.rotation_degrees.y = lane.rot
			parent_city.add_child(car)
			_flying_cars.append(car)
			_animate_vehicle(car, i, lane.start, lane.end, lane.rot)

	# 2. Spawn Laboratory 3D Population
	if hero_res:
		var parent_lab = $Environment/Zone1
		# Assistant scientists
		var lab_npc_positions = [
			Vector3(-2.2, 0.0, -1.5),
			Vector3(-3.5, 0.0, 0.8)
		]
		for pos in lab_npc_positions:
			var npc = hero_res.instantiate() as Node3D
			npc.position = pos
			npc.rotation_degrees.y = randf_range(0, 360)
			parent_lab.add_child(npc)
			_lab_npcs.append(npc)
			_randomize_npc_visuals(npc)
			_play_hero_anim(npc, "WORK" if randf() > 0.5 else "LOOK")

	if robot_res:
		var parent_lab = $Environment/Zone1
		# Assembly helper robots
		var lab_robot_positions = [
			Vector3(3.8, 1.0, 0.5),
			Vector3(5.5, 1.0, -0.5)
		]
		for pos in lab_robot_positions:
			var robot = robot_res.instantiate() as Node3D
			robot.position = pos
			parent_lab.add_child(robot)
			_lab_robots.append(robot)
			_play_robot_anim(robot, "INTERACT" if randf() > 0.5 else "IDLE")

	# 3. Spawn City 3D Population (Zone 3)
	if hero_res:
		var parent_city = $Environment/Zone3
		var city_npc_positions = [
			Vector3(-12, 0, 4),
			Vector3(-6, 0, -3),
			Vector3(2, 0, 5),
			Vector3(8, 0, -2),
			Vector3(14, 0, 2),
			Vector3(-2, 0, -5)
		]
		for i in range(city_npc_positions.size()):
			var pos = city_npc_positions[i]
			var npc = hero_res.instantiate() as Node3D
			npc.position = pos
			parent_city.add_child(npc)
			_city_npcs.append(npc)
			_randomize_npc_visuals(npc)
			
			# Walk some pedestrians back and forth
			if i % 2 == 0:
				_animate_pedestrian(npc, pos, pos + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)))
			else:
				npc.rotation_degrees.y = randf_range(0, 360)
				_play_hero_anim(npc, "LOOK" if randf() > 0.5 else "IDLE")

	if robot_res:
		var parent_city = $Environment/Zone3
		var city_robot_positions = [
			Vector3(-10, 0, -2),
			Vector3(0, 0, 3),
			Vector3(6, 0, -4),
			Vector3(12, 0, 1)
		]
		for i in range(city_robot_positions.size()):
			var pos = city_robot_positions[i]
			var robot = robot_res.instantiate() as Node3D
			robot.position = pos
			parent_city.add_child(robot)
			_city_robots.append(robot)
			
			# Walk some robots alongside humans
			if i % 2 == 0:
				_animate_robot_walk(robot, pos, pos + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)))
			else:
				robot.rotation_degrees.y = randf_range(0, 360)
				_play_robot_anim(robot, "IDLE")

	# 4. Spawn Disaster 3D Population (Zone 5)
	if hero_res:
		var parent_disaster = $Environment/Zone5
		var disaster_npc_positions = [
			Vector3(-2, 0, 2),
			Vector3(1, 0, -2),
			Vector3(-4, 0, 4),
			Vector3(3, 0, 0)
		]
		for pos in disaster_npc_positions:
			var npc = hero_res.instantiate() as Node3D
			npc.position = pos
			parent_disaster.add_child(npc)
			_disaster_npcs.append(npc)
			_randomize_npc_visuals(npc)
			_play_hero_anim(npc, "IDLE")

	if robot_res:
		var parent_disaster = $Environment/Zone5
		var disaster_robot_positions = [
			Vector3(4, 0, 1),
			Vector3(6, 0, -2)
		]
		for pos in disaster_robot_positions:
			var robot = robot_res.instantiate() as Node3D
			robot.position = pos
			parent_disaster.add_child(robot)
			_disaster_robots.append(robot)
			_play_robot_anim(robot, "IDLE")

	# 5. Spawn Deactivated Broken Robots in Zone 6 (Ruins)
	if robot_res:
		var parent_ruins = $Environment/Zone6
		var ruins_robot_positions = [
			Vector3(-4, 0.1, -1),
			Vector3(3, 0.1, 2)
		]
		for pos in ruins_robot_positions:
			var robot = robot_res.instantiate() as Node3D
			robot.position = pos
			robot.rotation_degrees = Vector3(80, randf_range(0, 360), 10)
			parent_ruins.add_child(robot)
			_play_robot_anim(robot, "OFF")

func _randomize_npc_visuals(npc: Node3D) -> void:
	var s = randf_range(0.9, 1.1)
	npc.scale = Vector3(s, s, s)
	
	# Randomize mesh instance colors to make them look distinct
	for child in npc.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst = child as MeshInstance3D
		if mesh_inst:
			for surface_idx in range(mesh_inst.get_surface_override_material_count()):
				var mat = mesh_inst.get_surface_override_material(surface_idx)
				if mat is StandardMaterial3D:
					var dup = mat.duplicate() as StandardMaterial3D
					dup.albedo_color = Color(randf_range(0.2, 0.9), randf_range(0.2, 0.9), randf_range(0.2, 0.9))
					mesh_inst.set_surface_override_material(surface_idx, dup)
				else:
					var mesh_mat = mesh_inst.mesh.surface_get_material(surface_idx) if mesh_inst.mesh else null
					if mesh_mat is StandardMaterial3D:
						var dup = mesh_mat.duplicate() as StandardMaterial3D
						dup.albedo_color = Color(randf_range(0.2, 0.9), randf_range(0.2, 0.9), randf_range(0.2, 0.9))
						mesh_inst.set_surface_override_material(surface_idx, dup)

func _animate_vehicle(vehicle: Node3D, lane_idx: int, start_pos: Vector3, end_pos: Vector3, base_rot: float) -> void:
	var tween = create_tween().set_loops()
	_flying_car_tweens.append(tween)
	
	# Smooth round-trip flight paths
	var dur = randf_range(5.0, 8.0)
	tween.tween_property(vehicle, "position", end_pos, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(vehicle, "rotation_degrees:y", base_rot + 180.0, 0.4)
	tween.tween_property(vehicle, "position", start_pos, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(vehicle, "rotation_degrees:y", base_rot, 0.4)

func _animate_pedestrian(npc: Node3D, start: Vector3, end: Vector3) -> void:
	var tween = create_tween().set_loops()
	_flying_car_tweens.append(tween) # Reuse tween registry for clean shutdown
	
	var dur = randf_range(4.0, 7.0)
	tween.tween_callback(func(): _play_hero_anim(npc, "WALK"))
	tween.tween_callback(func(): npc.look_at(Vector3(end.x, npc.position.y, end.z), Vector3.UP))
	tween.tween_property(npc, "position", end, dur)
	tween.tween_callback(func(): _play_hero_anim(npc, "IDLE"))
	tween.tween_interval(randf_range(1.0, 3.0))
	tween.tween_callback(func(): _play_hero_anim(npc, "WALK"))
	tween.tween_callback(func(): npc.look_at(Vector3(start.x, npc.position.y, start.z), Vector3.UP))
	tween.tween_property(npc, "position", start, dur)
	tween.tween_callback(func(): _play_hero_anim(npc, "IDLE"))
	tween.tween_interval(randf_range(1.0, 3.0))

func _animate_robot_walk(robot: Node3D, start: Vector3, end: Vector3) -> void:
	var tween = create_tween().set_loops()
	_flying_car_tweens.append(tween)
	
	var dur = randf_range(5.0, 8.0)
	tween.tween_callback(func(): _play_robot_anim(robot, "WALK"))
	tween.tween_callback(func(): robot.look_at(Vector3(end.x, robot.position.y, end.z), Vector3.UP))
	tween.tween_property(robot, "position", end, dur)
	tween.tween_callback(func(): _play_robot_anim(robot, "IDLE"))
	tween.tween_interval(randf_range(1.0, 3.0))
	tween.tween_callback(func(): _play_robot_anim(robot, "WALK"))
	tween.tween_callback(func(): robot.look_at(Vector3(start.x, robot.position.y, start.z), Vector3.UP))
	tween.tween_property(robot, "position", start, dur)
	tween.tween_callback(func(): _play_robot_anim(robot, "IDLE"))
	tween.tween_interval(randf_range(1.0, 3.0))

func _play_hero_anim(hero: Node, anim_name: String) -> void:
	if hero != null:
		var anim_player: AnimationPlayer = hero.find_child("AnimationPlayer", true, false)
		if anim_player != null and anim_player.has_animation(anim_name):
			anim_player.play(anim_name, 0.3)

func _play_robot_anim(robot: Node, anim_name: String) -> void:
	if robot != null:
		if robot.has_method("play_state"):
			# Maps String state names to CinematicRobot.State enum integers.
			# "HOSTILE" and "HOSTILE_MOVEMENT" both map to State.HOSTILE (7).
			var state_map: Dictionary = {
				"OFF": 0,
				"BOOTING": 1,
				"IDLE": 2,
				"WALK": 3,
				"TURN": 4,
				"INTERACT": 5,
				"MALFUNCTION": 6,
				"HOSTILE": 7,
				"HOSTILE_MOVEMENT": 7  # alias — same State.HOSTILE
			}
			if state_map.has(anim_name):
				robot.play_state(state_map[anim_name])
			else:
				push_warning("_play_robot_anim: unknown state name '" + anim_name + "'")
		else:
			var anim_player: AnimationPlayer = robot.find_child("AnimationPlayer", true, false)
			if anim_player != null and anim_player.has_animation(anim_name):
				anim_player.play(anim_name, 0.3)

func _on_story_event_triggered(event_id: String) -> void:
	if event_id == "opening_objective_set":
		_show_first_objective()
		return

	# Trigger AnimationPlayer track animations if they exist
	if _animation_player != null and _animation_player.has_animation(event_id):
		_animation_player.play(event_id)

	# Route act lighting / color grades
	match event_id:
		# ── Phase 14B new events ─────────────────────────────────────────
		"city_dawn_aerial":
			# SHOT 01: City dawn aerial — warm amber sun, sky-blue ambient, no clip.
			_grade("ACT_1")
			_lighting("CITY_DAWN")
			# Position camera high for crane-down start — CinematicCameraController
			# will then tween it to Cam_CityAerial marker over 4 s.
			var cam = get_viewport().get_camera_3d()
			if cam:
				cam.global_position = Vector3(0.0, 120.0, 60.0)
			# Ensure city population is alive
			for npc in _city_npcs:
				if is_instance_valid(npc):
					_animate_pedestrian(npc, npc.position,
						npc.position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5)))
			for robot in _city_robots:
				if is_instance_valid(robot):
					_play_robot_anim(robot, "WALK")

		"city_street_life":
			# SHOT 02: City street dolly — pedestrians walk, robots patrol.
			_grade("ACT_1")
			_lighting("CITY_DAWN")
			for npc in _city_npcs:
				if is_instance_valid(npc):
					_play_hero_anim(npc, "WALK")
			for robot in _city_robots:
				if is_instance_valid(robot):
					_play_robot_anim(robot, "WALK")

		"lab_establishing":
			# SHOT 03: Lab wide — ambient, scientists working, assembly robots active.
			_grade("ACT_1")
			_lighting("LAB_DAY")
			for npc in _lab_npcs:
				if is_instance_valid(npc):
					_play_hero_anim(npc, "WORK")
			for robot in _lab_robots:
				if is_instance_valid(robot):
					_play_robot_anim(robot, "INTERACT")
			_play_hero_anim(_hero_lab, "IDLE")

		"hero_walks_lab":
			# SHOT 04: Hero tracking — hero walks from entrance to workstation.
			_grade("ACT_1")
			_lighting("LAB_DAY")
			_hero_walk_to_workstation()

		"hero_face_cu":
			# SHOT 05: Hero face CU — looks at workstation, subtle LOOK animation.
			_grade("ACT_1")
			_play_hero_anim(_hero_lab, "LOOK")

		"welding_detail":
			# SHOT 07: Weld CU — assembly robots active, sparks VFX node on.
			_grade("ACT_2")
			_lighting("LAB_DAY")
			for robot in _lab_robots:
				if is_instance_valid(robot):
					_play_robot_anim(robot, "INTERACT")

		"hero_robot_first_contact":
			# SHOT 09: Handshake orbit — hero INTERACT + robot INTERACT.
			# Lighting brightens slightly (warm light enters from above).
			_grade("ACT_1")
			_lighting("LAB_DAY")
			_play_hero_anim(_hero_lab, "INTERACT")
			_play_robot_anim(_robot_assembly, "INTERACT")
			# Orbit the camera around the pair over the 3 s shot duration.
			_orbit_camera_around(
				_hero_lab.global_position if is_instance_valid(_hero_lab) else Vector3(0, 1, 0),
				3.0, 2.5
			)

		"montage_revolution_a":
			# SHOT 10: Revolution montage — all city NPCs + robots active, cars fly.
			_grade("ACT_2")
			_lighting("CITY_DAY")
			for npc in _city_npcs:
				if is_instance_valid(npc):
					_play_hero_anim(npc, "WALK")
			for robot in _city_robots:
				if is_instance_valid(robot):
					_play_robot_anim(robot, "WALK")
			for robot in _lab_robots:
				if is_instance_valid(robot):
					_play_robot_anim(robot, "INTERACT")

		"hero_observation_platform":
			# SHOT 11: Hero observation — hero on Zone3 elevated point, heroic stance.
			_grade("ACT_3")
			_lighting("OBSERVATION_PLATFORM")
			# Teleport hero to elevated observation position in Zone3.
			if is_instance_valid(_hero_lab):
				_hero_lab.global_position = Vector3(0.0, 4.0, 0.0)
				_play_hero_anim(_hero_lab, "HEROIC_STANCE")
			# Orbit camera to reveal hero face over 3 s.
			_orbit_camera_around(
				Vector3(0.0, 4.5, 0.0),
				3.0, 5.0
			)
			# City population alive behind him.
			for npc in _city_npcs:
				if is_instance_valid(npc):
					_play_hero_anim(npc, "WALK")
			for robot in _city_robots:
				if is_instance_valid(robot):
					_play_robot_anim(robot, "WALK")

		# ── Legacy events (kept for backward compatibility) ────────────────
		"lab_hero_working":
			_grade("ACT_1")
			_lighting("LAB_DAY")
			_play_hero_anim(_hero_lab, "WORK")
			_play_robot_anim(_robot_assembly, "OFF")
		"hero_closeup_eyes", "hero_closeup_hands":
			_grade("ACT_1")
			_play_hero_anim(_hero_lab, "WORK")
		"robot_arm_welding":
			_grade("ACT_1")
			if _animation_player != null and _animation_player.has_animation("assembly_weld_start"):
				_animation_player.play("assembly_weld_start")
		"robot_assembly_start":
			_grade("ACT_2")
			_lighting("LAB_DAY")
			_play_hero_anim(_hero_lab, "INTERACT")
			_play_robot_anim(_robot_assembly, "BOOTING")
		"robot_activation":
			# Phase 14B: now uses LAB_ROBOT_ACTIVATE — dark room, cyan rim, controlled.
			_grade("ACT_2")
			_lighting("LAB_ROBOT_ACTIVATE")
			_play_hero_anim(_hero_lab, "LOOK")
			# Robot boots up sequentially: OFF → BOOTING → IDLE
			_play_robot_anim(_robot_assembly, "BOOTING")
			var act_t = create_tween()
			act_t.tween_interval(2.0)
			act_t.tween_callback(func():
				if is_instance_valid(_robot_assembly):
					_play_robot_anim(_robot_assembly, "IDLE")
			)
		"robot_calculate":
			_grade("ACT_2")
			_play_robot_anim(_robot_assembly, "INTERACT")
		"robot_build":
			_grade("ACT_2")
			_play_robot_anim(_robot_assembly, "WALK")
		"robot_protect":
			_grade("ACT_2")
			_play_robot_anim(_robot_assembly, "IDLE")

		# acts / temporal montage
		"montage_year_03":
			_grade("ACT_2")
			_lighting("LAB_DAY")
			_play_robot_anim(_robot_assembly, "WALK")
		"montage_year_05":
			_grade("ACT_2")
			_lighting("CITY_DAY")
			_play_robot_anim(_robot_assembly, "INTERACT")
		"montage_year_07":
			_grade("ACT_3")
			_lighting("CITY_DAY")
			_play_robot_anim(_robot_assembly, "WALK")
		"montage_year_10":
			_grade("ACT_3")
			_lighting("CITY_NIGHT")
			_play_hero_anim(_hero_lab, "HEROIC_STANCE")

		# decision
		"hero_at_control":
			_grade("ACT_4")
			_lighting("LAB_NIGHT")
			_play_hero_anim(_hero_control, "WORK")
		"hero_hesitate":
			_grade("ACT_4")
			_play_hero_anim(_hero_control, "LOOK")
		"authority_authorized":
			_grade("ACT_4")
			_lighting("LAB_NIGHT")
			_play_hero_anim(_hero_control, "INTERACT")
			_robots_look_at_camera()

		# perfect world
		"perfect_world_start":
			_grade("ACT_2")
			_lighting("CITY_DAY")
			_play_robot_anim(_robot_assembly, "IDLE")
		"perfect_world_hero":
			_grade("ACT_2")
			_lighting("CITY_DAY")
			_play_hero_anim(_hero_control, "WALK")

		# malfunction
		"robot_freeze":
			_grade("ACT_5")
			_lighting("EMERGENCY")
			_play_robot_anim(_robot_assembly, "IDLE")
			_robots_reset_look()
			_make_robots_malfunction()
		"robot_eye_red":
			_play_robot_anim(_robot_assembly, "MALFUNCTION")
		"city_glitch_start":
			_grade("ACT_5")
			_lighting("EMERGENCY")
			if _animation_player != null and _animation_player.has_animation("night_glitch_start"):
				_animation_player.play("night_glitch_start")

		# chaos
		"robots_turn_hostile":
			_grade("ACT_5")
			_lighting("CITY_COLLAPSE")
			_play_robot_anim(_robot_police, "HOSTILE_MOVEMENT")
			_play_hero_anim(_civilian_run, "RUN")
			_make_robots_hostile()
			_npcs_panic_run()
			_vehicles_lose_control()
		"hero_shocked":
			_grade("ACT_5")
			_lighting("EMERGENCY")
			_play_hero_anim(_hero_control, "REACT")
			if _animation_player != null and _animation_player.has_animation("control_failure_start"):
				_animation_player.play("control_failure_start")
		"chaos_erupts":
			_grade("ACT_5")
			_lighting("CITY_COLLAPSE")
			_play_robot_anim(_robot_police, "HOSTILE_MOVEMENT")
			_play_hero_anim(_civilian_run, "RUN")
			if _animation_player != null and _animation_player.has_animation("disaster_chaos_start"):
				_animation_player.play("disaster_chaos_start")

		# ruins / realization
		"hero_walks_ruins":
			_grade("ACT_6")
			_lighting("CITY_COLLAPSE")
			_play_hero_anim(_hero_ruins, "WALK")
		"hero_touches_robot":
			_play_hero_anim(_hero_ruins, "INTERACT")
			_play_robot_anim(_robot_broken, "MALFUNCTION")
		"hero_realization":
			_grade("ACT_6")
			_lighting("CITY_COLLAPSE")
			_play_hero_anim(_hero_ruins, "LOOK")
		"hero_resolve_start":
			_grade("ACT_7")
			_lighting("CITY_COLLAPSE")
			_play_hero_anim(_hero_ruins, "LOOK")

		# rises & prep
		"hero_enters_underground":
			_grade("ACT_7")
			_lighting("LAB_NIGHT")
			_play_hero_anim(_hero_ruins, "WALK")
		"hero_types_solution":
			_play_hero_anim(_hero_ruins, "WORK")
		"hero_equips_tool":
			_play_hero_anim(_hero_ruins, "INTERACT")
		"hero_prepares":
			_grade("ACT_7")
			_lighting("HERO_REVEAL")
			_play_hero_anim(_hero_ruins, "HEROIC_STANCE")
		"hero_walks_toward_city":
			_grade("ACT_7")
			_lighting("HERO_REVEAL")
			_play_hero_anim(_hero_ruins, "WALK")

	# Spawn VFX particles reactive to story cues
	_spawn_story_vfx(event_id)

func _spawn_story_vfx(event_id: String) -> void:
	match event_id:
		# ── Phase 14B VFX ──────────────────────────────────────────────
		"city_dawn_aerial":
			_vfx("HolographicParticleVFX", Vector3(0, 5, 0))
		"lab_establishing":
			_vfx("HolographicParticleVFX", Vector3(-1, 1.5, 0))
			_vfx("SteamVFX", Vector3(2, 0.5, 0))
		"welding_detail":
			_vfx("SmallSparkBurst", Vector3(5.0, 1.5, 0))
			_vfx("SteamVFX", Vector3(5.2, 1.0, 0))
		"robot_activation":
			_vfx("RobotActivationVFX", Vector3(4, 1.0, 2))
			_vfx("ElectricalArcVFX", Vector3(4, 1.5, 2))
			_vfx("EnergyPulseVFX", Vector3(4, 0.5, 2))
		"hero_robot_first_contact":
			_vfx("HolographicParticleVFX", Vector3(0, 1.2, 0))
		"montage_revolution_a":
			_vfx("HolographicParticleVFX", Vector3(0, 3, 0))
			_vfx("VehicleTrailVFX", Vector3(5, 8, 5))
		"hero_observation_platform":
			_vfx("HolographicParticleVFX", Vector3(0, 5, 0))
		# ── Legacy VFX ──────────────────────────────────────────────────
		"lab_hero_working":
			_vfx("RobotActivationVFX", Vector3(0, 0, 0))
			_vfx("HolographicParticleVFX", Vector3(-1, 1, 0))
		"hero_closeup_eyes", "hero_closeup_hands":
			_vfx("HolographicParticleVFX", Vector3(0, 1, 0))
		"robot_assembly_start":
			_vfx("SteamVFX", Vector3(0, 0.5, 0))
			_vfx("SmallSparkBurst", Vector3(0.3, 0.8, 0))
		"montage_year_05":
			_vfx("DustVFX", Vector3(0, 2, 0))
		"montage_year_08":
			_vfx("VehicleTrailVFX", Vector3(2, 5, 0))
		"montage_year_10":
			_vfx("HolographicParticleVFX", Vector3(0, 3, 0))
		"hero_at_control":
			_vfx("HolographicParticleVFX", Vector3(-0.5, 1.5, 0))
		"network_expand":
			_vfx("EnergyPulseVFX", Vector3(0, 0, 0))
		"robot_freeze":
			_vfx("ElectricalArcVFX", Vector3(0, 1, 0))
		"robot_eye_red":
			_vfx("EmergencyPulseVFX", Vector3(0, 1.2, 0))
		"robots_turn":
			_vfx("ElectricalArcVFX", Vector3(0, 0.5, 0))
			_vfx("MediumSparkBurst", Vector3(0.5, 0.5, 0))
		"vehicle_malfunction":
			_vfx("MediumSparkBurst", Vector3(2, 2, 0))
		"city_power_fail":
			_vfx("EmergencyPulseVFX", Vector3(0, 5, 0))
		"chaos_erupts":
			_vfx("MediumExplosion", Vector3(3, 0, 3))
			_vfx("HeavySmoke", Vector3(2, 0, 2))
			_vfx("FireVFX", Vector3(-2, 0, 1))
		"robots_attack":
			_vfx("HeavySparkBurst", Vector3(0, 0.5, 0))
		"vehicles_crash":
			_vfx("MediumExplosion", Vector3(0, 0, 0))
			_vfx("DebrisVFX", Vector3(0, 2, 0))
		"buildings_go_dark":
			_vfx("HeavySmoke", Vector3(5, 3, 5))
		"hero_walks_ruins":
			_vfx("DustVFX", Vector3(0, 0.2, 0))
			_vfx("SmallSmoke", Vector3(1, 0, 1))
		"hero_touches_robot":
			_vfx("SmallSparkBurst", Vector3(0, 1, 0))
		"hero_prepares":
			_vfx("HolographicParticleVFX", Vector3(-0.5, 1.5, 0))

func _vfx(name: String, pos: Vector3, scale: float = 1.0) -> void:
	CinematicVFXMaster.spawn_vfx(name, pos, self, scale)

func _grade(act: String) -> void:
	if _lighting_master:
		_lighting_master.apply_color_grade(act)

func _lighting(profile: String) -> void:
	if _lighting_master:
		_lighting_master.apply_lighting_profile(profile)

func _on_ui_event(event: String) -> void:
	if not _ui_master: return
	match event:
		# ── Phase 14B new UI events ────────────────────────────────────────
		"ROBOT_DIAGNOSTIC_SHOW":     _ui_master.call("show_robot_diagnostic", "ONLINE")
		"ROBOT_ACTIVATE_SHOW":       _ui_master.call("show_robot_diagnostic", "BOOTING")
		"CITY_STATUS_SHOW":          _ui_master.call("show_city_status")
		# ── Legacy events ──────────────────────────────────────────────────
		"YEAR_01_SHOW":              _ui_master.call("show_year", 1)
		"YEAR_03_SHOW":              _ui_master.call("show_year", 3)
		"YEAR_05_SHOW":              _ui_master.call("show_year", 5)
		"YEAR_07_SHOW":              _ui_master.call("show_year", 7)
		"YEAR_08_SHOW":              _ui_master.call("show_year", 8)
		"YEAR_09_SHOW":              _ui_master.call("show_year", 9)
		"YEAR_10_NETWORK_100":
			_ui_master.call("show_year", 10)
			_ui_master.call("show_network", 100, "GLOBAL MACHINE NETWORK")
		"SYSTEM_STATUS_ONLINE":      _ui_master.call("show_status", "SYSTEMS ONLINE")
		"NETWORK_EXPANDING":
			_ui_master.call("show_network", 73, "MACHINE NETWORK")
		"AUTHORIZATION_SHOW":        _ui_master.call("show_authorization")
		"LAST_PROTOCOL_SHOW":        _ui_master.call("show_last_protocol")
		"WARNING_SYSTEM_FAILURE":    _ui_master.call("show_system_failure")
		"WARNING_CRITICAL":          _ui_master.call("show_warning", "CRITICAL MALFUNCTION")
		"SYSTEM_FAILURE_SHOW":       _ui_master.call("show_system_failure")
		"CRITICAL_FAILURE_SHOW":     _ui_master.call("show_critical_failure")
		"SYSTEM_AUTHORITY_GRANTED":  _ui_master.call("show_status", "AUTHORITY GRANTED")
		"SYSTEM_RECOVERING":         _ui_master.call("show_status", "RECOVERING PROTOCOL")
		"TITLE_CARD_SHOW":           _ui_master.call("show_title", "THE LAST PROTOCOL")


func _on_cinematic_finished(sequence_id: String) -> void:
	if sequence_id not in ["opening_protocol", "cinematic_14_the_last_protocol", "final_opening_cinematic"]:
		return
	if _transitioning:
		return
	_transitioning = true
	
	if CutsceneManager.is_cutscene_playing:
		var handoff_scene = load("res://story/cinematics/gameplay_handoff.tscn")
		if handoff_scene:
			add_child(handoff_scene.instantiate())
	else:
		_begin_scene_transition()

func _begin_scene_transition() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)

	var overlay := ColorRect.new()
	overlay.color = Color.BLACK
	overlay.modulate.a = 0.0
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)

	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, TRANSITION_FADE_DURATION)
	await tween.finished

	if ResourceLoader.exists(NEXT_SCENE):
		get_tree().change_scene_to_file(NEXT_SCENE)
	else:
		push_warning("OpeningCinematic: NEXT_SCENE '%s' does not exist." % NEXT_SCENE)
		_transitioning = false

func _show_first_objective() -> void:
	EventBus.objective_started.emit(FIRST_OBJECTIVE)
	if _objective_hud != null and _objective_hud.has_method("show_objective"):
		_objective_hud.show_objective(FIRST_OBJECTIVE)

# ─── CHOREOGRAPHY HELPERS ────────────────────────────────────────────────────

## Phase 14B: Tween the hero from his starting position to the lab workstation.
## Plays WALK animation, then transitions to INTERACT once he arrives.
func _hero_walk_to_workstation() -> void:
	if not is_instance_valid(_hero_lab):
		return
	_hero_lab.global_position = Vector3(4.0, 0.0, 4.0)  # entrance
	_hero_lab.look_at(Vector3(-1.0, 0.0, 0.0), Vector3.UP)
	_play_hero_anim(_hero_lab, "WALK")
	var tween = create_tween()
	tween.tween_property(_hero_lab, "global_position", Vector3(-1.0, 0.0, 0.0), 3.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		if is_instance_valid(_hero_lab):
			_play_hero_anim(_hero_lab, "INTERACT")
	)

## Phase 14B: Programmatic camera orbit over [duration] seconds around [center].
## Orbits from behind (angle 0) to front (angle PI) with [radius] units.
func _orbit_camera_around(center: Vector3, duration: float, radius: float) -> void:
	var cam = get_viewport().get_camera_3d()
	if not cam:
		return
	var start_angle: float = 0.0
	var end_angle: float = PI
	var height: float = center.y + 1.5
	var steps: int = 60
	var step_dur: float = duration / float(steps)
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var angle: float = lerp(start_angle, end_angle, t)
		var tx: float = center.x + sin(angle) * radius
		var tz: float = center.z + cos(angle) * radius
		var orbit_tween = create_tween()
		orbit_tween.tween_interval(float(i) * step_dur)
		orbit_tween.tween_callback(func():
			if cam:
				cam.global_position = Vector3(tx, height, tz)
				cam.look_at(Vector3(center.x, height, center.z), Vector3.UP)
		)

## All lab + city + disaster robots slowly rotate their heads toward the camera
## (simulated as a look_at toward the camera's global position).
func _robots_look_at_camera() -> void:
	var cam = get_viewport().get_camera_3d()
	if not cam:
		return
	var all_robots: Array[Node3D] = []
	all_robots.append_array(_lab_robots)
	all_robots.append_array(_city_robots)
	all_robots.append_array(_disaster_robots)
	for robot in all_robots:
		if is_instance_valid(robot):
			var look_target = Vector3(cam.global_position.x, robot.global_position.y, cam.global_position.z)
			var tween = create_tween()
			tween.tween_callback(func():
				if is_instance_valid(robot):
					robot.look_at(look_target, Vector3.UP)
			).set_delay(randf_range(0.0, 0.8))

## Stops any forced look direction — robots resume natural idle poses.
func _robots_reset_look() -> void:
	for robot in _city_robots + _lab_robots + _disaster_robots:
		if is_instance_valid(robot):
			_play_robot_anim(robot, "IDLE")

## Switches all background robots to MALFUNCTION state (eye blink, twitch).
func _make_robots_malfunction() -> void:
	var all_robots: Array[Node3D] = []
	all_robots.append_array(_city_robots)
	all_robots.append_array(_lab_robots)
	all_robots.append_array(_disaster_robots)
	for robot in all_robots:
		if is_instance_valid(robot):
			# Stagger the malfunctions for drama
			var tween = create_tween()
			tween.tween_interval(randf_range(0.0, 1.2))
			tween.tween_callback(func():
				if is_instance_valid(robot):
					_play_robot_anim(robot, "MALFUNCTION")
			)

## Switches all background robots to HOSTILE state (red eyes, aggressive posture).
func _make_robots_hostile() -> void:
	var all_robots: Array[Node3D] = []
	all_robots.append_array(_city_robots)
	all_robots.append_array(_lab_robots)
	all_robots.append_array(_disaster_robots)
	for robot in all_robots:
		if is_instance_valid(robot):
			var tween = create_tween()
			tween.tween_interval(randf_range(0.0, 0.6))
			tween.tween_callback(func():
				if is_instance_valid(robot):
					_play_robot_anim(robot, "HOSTILE")
			)

## NPC pedestrians break into a panicked run away from city robots.
func _npcs_panic_run() -> void:
	var all_npcs: Array[Node3D] = []
	all_npcs.append_array(_city_npcs)
	all_npcs.append_array(_disaster_npcs)
	for npc in all_npcs:
		if is_instance_valid(npc):
			# Stop any existing walk tweens by killing and replacing
			var escape_pos = npc.position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
			var tween = create_tween()
			tween.tween_interval(randf_range(0.0, 0.5))
			tween.tween_callback(func():
				if is_instance_valid(npc):
					_play_hero_anim(npc, "RUN")
					npc.look_at(Vector3(escape_pos.x, npc.position.y, escape_pos.z), Vector3.UP)
			)
			tween.tween_property(npc, "position", escape_pos, randf_range(3.0, 6.0))

## Flying cars stutter, veer off-lane, and spiral downward during the malfunction.
func _vehicles_lose_control() -> void:
	# Kill existing smooth flight tweens
	for t in _flying_car_tweens:
		if t is Tween and t.is_running():
			t.kill()
	_flying_car_tweens.clear()

	for car in _flying_cars:
		if not is_instance_valid(car):
			continue
		var spin_dir = 1.0 if randf() > 0.5 else -1.0
		var crash_pos = car.position + Vector3(
			randf_range(-8, 8),
			randf_range(-6, -2),
			randf_range(-8, 8)
		)
		var tween = create_tween()
		tween.tween_interval(randf_range(0.0, 1.0))
		# Spin and plunge
		tween.tween_property(car, "rotation_degrees:z", spin_dir * 720.0, 3.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(car, "position", crash_pos, 3.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		# Hide on impact
		tween.tween_callback(func():
			if is_instance_valid(car):
				car.visible = false
		)
