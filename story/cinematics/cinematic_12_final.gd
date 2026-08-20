extends Node3D

@onready var _fade: Node               = $CinematicFade
@onready var _camera: Node             = $CinematicCameraController
@onready var _ui_master: Node          = get_node_or_null("CinematicUI")
@onready var _vfx_master: Node         = get_node_or_null("VFXMaster")
@onready var _audio_master: Node       = get_node_or_null("AudioMaster")
@onready var _lighting_master: Node    = get_node_or_null("LightingMaster")

var _transitioning: bool = false

func _ready() -> void:
	for hud_node in ["ObjectiveHUD", "PlayerHUD"]:
		var n = get_node_or_null(hud_node)
		if n: n.visible = false

	if _fade and _fade.has_method("fade_to_black"):
		_fade.fade_to_black(0.0)

	EventBus.story_event_triggered.connect(_on_story_event)
	EventBus.cinematic_ui_event.connect(_on_ui_event)
	EventBus.cinematic_finished.connect(_on_cinematic_finished, CONNECT_ONE_SHOT)

	if _lighting_master and _lighting_master.has_method("apply_color_grade"):
		_lighting_master.apply_color_grade("ACT_1")
		_lighting_master.apply_lighting_profile("LAB_DAY")

	await get_tree().process_frame

	var sequence: CinematicSequence = Cinematic12FinalBuilder.build()
	CinematicManager.play_sequence(sequence)

func _on_story_event(event_id: String) -> void:
	match event_id:
		# Act 1
		"act1_lab_working", "act1_hero_hand", "act1_hero_eyes":
			_vfx("HolographicParticleVFX", Vector3(-1, 1, 0), 0.5)
		"act1_hero_activates", "act1_hero_success":
			_vfx("EnergyPulseVFX", Vector3(0, 0, 0), 0.8)
			_vfx("ElectricalArcVFX", Vector3(0, 1, 0), 0.5)
		
		# Act 2
		"act2_assembly", "act2_torso", "act2_head", "act2_hands":
			_vfx("SteamVFX", Vector3(0, 0.5, 0), 1.0)
			_vfx("SmallSparkBurst", Vector3(0, 1, 0), 0.5)
		"act2_eyes":
			_lighting("LAB_NIGHT"); _grade("ACT_2")
			_vfx("RobotActivationVFX", Vector3(0, 0, 0), 1.0)
		"act2_looks", "act2_touch":
			pass

		# Act 3
		"act3_year1":
			_lighting("LAB_DAY"); _grade("ACT_3")
		"act3_year3":
			_lighting("CITY_DAY"); _vfx("DustVFX", Vector3(0, 1, 0), 1.5)
		"act3_year5", "act3_year7", "act3_year10":
			_vfx("HolographicParticleVFX", Vector3(0, 3, 0), 2.0)

		# Act 4
		"act4_elderly", "act4_medical", "act4_children", "act4_flying_cars", "act4_robot_workers", "act4_hero_proud":
			_grade("ACT_4"); _lighting("CITY_DAY")

		# Act 5
		"act5_hero_enters":
			_grade("ACT_4"); _lighting("LAB_NIGHT")
		"act5_system_activates":
			_vfx("EnergyPulseVFX", Vector3(0, 0, 0), 2.0)
		"act5_hero_confirms":
			_vfx("HolographicParticleVFX", Vector3(-0.5, 1.5, 0), 0.8)

		# Act 6
		"act6_first_failure", "act6_another_stops", "act6_traffic_glitch", "act6_car_glitch", "act6_hospital_stops", "act6_city_flicker":
			_grade("ACT_5"); _lighting("EMERGENCY")
			_vfx("ElectricalArcVFX", Vector3(0, 2, 0), 0.5)

		# Act 7
		"act7_robot_turns", "act7_people_run", "act7_robots_move":
			_vfx("MediumSparkBurst", Vector3(0, 1, 0), 1.0)
		"act7_vehicles_crash":
			_vfx("MediumExplosion", Vector3(2, 3, 0), 1.5)
			_shake_camera("explosion")
		"act7_robots_attack", "act7_chaos":
			_lighting("CITY_COLLAPSE")
			_vfx("HeavySmoke", Vector3(0, 0, 0), 3.0)
			_vfx("FireVFX", Vector3(3, 0, -2), 2.0)

		# Act 8
		"act8_hero_watches", "act8_attempt_shutdown", "act8_access_denied", "act8_guilt":
			_grade("ACT_6"); _lighting("EMERGENCY")

		# Act 9
		"act9_skyscraper_fall", "act9_car_fall", "act9_robot_fall", "act9_collapse":
			_grade("ACT_6"); _lighting("CITY_COLLAPSE")
			_vfx("HeavyExplosion", Vector3(5, 5, 5), 2.0) if _vfx_exists("HeavyExplosion") else _vfx("MediumExplosion", Vector3(5,5,5), 2.0)
			_shake_camera("explosion")

		# Act 10
		"act10_silence", "act10_hero_enters", "act10_touches_machine":
			_grade("ACT_7"); _lighting("CITY_COLLAPSE")
			_vfx("SmallSmoke", Vector3(0, 0, 0), 1.5)
			_vfx("DustVFX", Vector3(0, 0.2, 0), 0.5)

		# Act 11
		"act11_hero_equips", "act11_hero_looks":
			_grade("ACT_8"); _lighting("HERO_REVEAL")

		# Final
		"act12_final_walk":
			_vfx("HeavySmoke", Vector3(5, 0, 5), 3.0)

func _on_ui_event(event: String) -> void:
	if not _ui_master: return
	match event:
		"YEAR_01_SHOW": _ui_master.call("show_year", 1)
		"YEAR_03_SHOW": _ui_master.call("show_year", 3)
		"YEAR_05_SHOW": _ui_master.call("show_year", 5)
		"YEAR_07_SHOW": _ui_master.call("show_year", 7)
		"YEAR_10_SHOW": _ui_master.call("show_year", 10)
		"NETWORK_CONNECTED_SHOW": _ui_master.call("show_network", 100, "GLOBAL MACHINE NETWORK")
		"AUTONOMOUS_AUTHORITY_SHOW": _ui_master.call("show_authorization")
		"SYSTEM_ERROR_SHOW": _ui_master.call("show_system_failure")
		"AUTONOMOUS_CONTROL_LOST_SHOW": _ui_master.call("show_warning", "AUTONOMOUS CONTROL LOST")
		"CRITICAL_FAILURE_SHOW": _ui_master.call("show_critical_failure")
		"TITLE_CARD_SHOW": _ui_master.call("show_title", "THE LAST PROTOCOL")

func _on_cinematic_finished(sequence_id: String) -> void:
	if sequence_id != "cinematic_12_final": return
	if _transitioning: return
	_transitioning = true
	_begin_transition()

func _begin_transition() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	var overlay := ColorRect.new()
	overlay.color = Color.BLACK
	overlay.modulate.a = 0.0
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 1.0)
	await tween.finished
	get_tree().quit()

func _vfx(name: String, pos: Vector3, scale: float = 1.0):
	if not CinematicVFXMaster: return
	CinematicVFXMaster.spawn_vfx(name, pos, self, scale)

func _vfx_exists(name: String) -> bool:
	return ResourceLoader.exists("res://story/cinematics/vfx/" + name + ".tscn")

func _shake_camera(event_type: String):
	var cam = get_node_or_null("CinematicCamera")
	if cam and cam.has_method("trigger_" + event_type):
		cam.call("trigger_" + event_type)

func _grade(act: String):
	if _lighting_master and _lighting_master.has_method("apply_color_grade"):
		_lighting_master.apply_color_grade(act)

func _lighting(profile: String):
	if _lighting_master and _lighting_master.has_method("apply_lighting_profile"):
		_lighting_master.apply_lighting_profile(profile)
