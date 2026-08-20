## DevHeroPreviewTest — Automated validation for Phase 9C Hero Character Production.
##
## Tests:
##   1. Hero Scene & Skeleton integrity
##   2. All 8 animation states present (IDLE, WALK, RUN, WORK, LOOK, INTERACT, REACT, HEROIC_STANCE)
##   3. PBR Material Overrides mapping (Skin SSS, Body, Hair transparent)
##   4. Preview Lab Environment, lights, and Camera Markers
##   5. Cinematic playback and manager integration
##
## Expected: All tests PASS, exit code 0.

extends Node3D

var _pass_count: int = 0
var _fail_count: int = 0

func _ready() -> void:
	await get_tree().process_frame
	await _run_tests()

func _run_tests() -> void:
	print("\n====================================================")
	print("  THE LAST PROTOCOL - HERO CHARACTER PRODUCTION VALIDATION")
	print("====================================================\n")

	_test_hero_scene_integrity()
	_test_hero_animations()
	_test_hero_materials()
	_test_preview_scene_infrastructure()
	await _test_runtime_cinematic_playback()

	print("\n====================================================")
	print("  RESULTS: %d PASSED   %d FAILED" % [_pass_count, _fail_count])
	print("====================================================\n")
	get_tree().quit(_fail_count)

func _check(condition: bool, label: String) -> void:
	if condition:
		_pass_count += 1
		print("  [PASS] " + label)
	else:
		_fail_count += 1
		print("  [FAIL] " + label)

# ── TEST HERO INTEGRITY ────────────────────────────────────────────────────────

func _test_hero_scene_integrity() -> void:
	var hero_scene = load("res://story/cinematics/characters/cinematic_hero.tscn")
	_check(hero_scene != null, "01 CinematicHero scene exists at path")
	if not hero_scene: return
	
	var inst = hero_scene.instantiate()
	_check(inst != null, "02 CinematicHero scene can be instantiated")
	if not inst: return
	
	var model = inst.get_node_or_null("HeroModel")
	_check(model != null, "03 HeroModel child exists under CinematicHero")
	if not model: 
		inst.free()
		return
		
	var skeleton = model.get_node_or_null("Skeleton3D")
	_check(skeleton != null, "04 Skeleton3D child exists under HeroModel")
	
	var anim_player = model.get_node_or_null("AnimationPlayer")
	_check(anim_player != null, "05 AnimationPlayer child exists under HeroModel")
	
	inst.free()

func _test_hero_animations() -> void:
	var hero_scene = load("res://story/cinematics/characters/cinematic_hero.tscn")
	if not hero_scene: return
	var inst = hero_scene.instantiate()
	var anim_player: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	
	if anim_player:
		var states = ["IDLE", "WALK", "RUN", "WORK", "LOOK", "INTERACT", "REACT", "HEROIC_STANCE"]
		for s in states:
			_check(anim_player.has_animation(s), "06 Animation state '%s' exists in library" % s)
	else:
		_check(false, "06 AnimationPlayer is missing, cannot test animations")
		
	inst.free()

func _test_hero_materials() -> void:
	var hero_scene = load("res://story/cinematics/characters/cinematic_hero.tscn")
	if not hero_scene: return
	var inst = hero_scene.instantiate()
	var skeleton: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	if skeleton:
		var body_mesh: MeshInstance3D = skeleton.find_child("Ch33_Body", true, false)
		_check(body_mesh != null and body_mesh.material_override != null, "07 Body skin has material override assigned")
		if body_mesh and body_mesh.material_override:
			_check(body_mesh.material_override.resource_path.ends_with("hero_skin.tres"), "08 Body skin uses skin.tres with Subsurface Scattering")
			_check(body_mesh.material_override.subsurf_scatter_enabled, "09 Skin material has subsurface scattering enabled")
			
		var suit_mesh: MeshInstance3D = skeleton.find_child("Ch33_Suit", true, false)
		_check(suit_mesh != null and suit_mesh.material_override != null, "10 Clothing suit has material override assigned")
		if suit_mesh and suit_mesh.material_override:
			_check(suit_mesh.material_override.resource_path.ends_with("hero_body.tres"), "11 Clothing uses hero_body.tres")
			
		var hair_mesh: MeshInstance3D = skeleton.find_child("Ch33_Hair", true, false)
		_check(hair_mesh != null and hair_mesh.material_override != null, "12 Hair has material override assigned")
		if hair_mesh and hair_mesh.material_override:
			_check(hair_mesh.material_override.resource_path.ends_with("hero_hair.tres"), "13 Hair uses hero_hair.tres with transparency")
			_check(hair_mesh.material_override.transparency == StandardMaterial3D.TRANSPARENCY_ALPHA, "14 Hair material uses alpha transparency")
	else:
		_check(false, "07 Skeleton missing, cannot check PBR materials")
		
	inst.free()

# ── TEST PREVIEW SCENE INFRASTRUCTURE ─────────────────────────────────────────

func _test_preview_scene_infrastructure() -> void:
	var preview_scene = load("res://story/cinematics/hero_preview_cinematic.tscn")
	_check(preview_scene != null, "15 Preview scene exists at path")
	if not preview_scene: return
	
	var inst = preview_scene.instantiate()
	_check(inst != null, "16 Preview scene instantiates successfully")
	if not inst: return
	
	var camera_controller = inst.get_node_or_null("CinematicCameraController")
	_check(camera_controller != null, "17 CinematicCameraController exists in preview scene")
	
	var cam = inst.get_node_or_null("CinematicCamera")
	_check(cam != null, "18 CinematicCamera exists in preview scene")
	
	var environment = inst.get_node_or_null("Environment")
	_check(environment != null, "19 Environment node exists in preview scene")
	
	if environment:
		var markers = ["MarkerEntrance", "MarkerDeskWide", "MarkerDeskMCU", "MarkerDeskCU", "MarkerRobotView", "MarkerHeroic"]
		var markers_node = environment.get_node_or_null("CameraMarkers")
		_check(markers_node != null, "20 CameraMarkers folder node exists")
		if markers_node:
			var all_markers_present = true
			for m in markers:
				if markers_node.get_node_or_null(m) == null:
					all_markers_present = false
					break
			_check(all_markers_present, "21 All 6 camera markers present in Markers folder")
			
		var robot = environment.get_node_or_null("RobotPrototype")
		_check(robot != null, "22 RobotPrototype frame exists in laboratory")
		
	var hero_node = inst.get_node_or_null("CinematicHero")
	_check(hero_node != null, "23 CinematicHero instance present in preview scene")
	
	inst.free()

# ── TEST RUNTIME PLAYBACK ─────────────────────────────────────────────────────

func _test_runtime_cinematic_playback() -> void:
	var preview_scene = load("res://story/cinematics/hero_preview_cinematic.tscn")
	if not preview_scene: return
	
	var original_scene = get_tree().current_scene
	var inst = preview_scene.instantiate()
	get_tree().root.add_child(inst)
	get_tree().current_scene = inst
	
	for i in range(10):
		await get_tree().process_frame
		print("Frame ", i, " - CinematicManager.is_active: ", CinematicManager.is_active)
		
	# Verify that CinematicManager is running the sequence
	_check(CinematicManager.is_active, "24 CinematicManager is active playing hero preview sequence")
	
	# Stop cinematic playback and clean up
	CinematicManager.stop()
	await get_tree().process_frame
	_check(not CinematicManager.is_active, "25 CinematicManager resets safely to inactive after stop()")
	
	get_tree().current_scene = original_scene
	get_tree().root.remove_child(inst)
	inst.queue_free()
