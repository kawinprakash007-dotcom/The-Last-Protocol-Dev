## cinematic_14_the_last_protocol.gd
## Scene controller for the 150-second final opening cinematic.
##
## This script follows the same structure as cinematic_01_the_birth.gd.
## Scene path: res://story/cinematics/cinematic_14_the_last_protocol.tscn
##
## Story event routing to VFX, Audio, and Lighting systems.

extends Node3D

# ── Scene node refs ──────────────────────────────────────────────
@onready var _fade: Node               = $CinematicFade
@onready var _camera: Node             = $CinematicCameraController
@onready var _ui_master: Node          = get_node_or_null("CinematicUI")
@onready var _vfx_master: Node         = get_node_or_null("VFXMaster")
@onready var _audio_master: Node       = get_node_or_null("AudioMaster")
@onready var _lighting_master: Node    = get_node_or_null("LightingMaster")

var _transitioning: bool = false

func _ready() -> void:
	# Hide any gameplay HUD nodes that may auto-show
	for hud_node in ["ObjectiveHUD", "PlayerHUD"]:
		var n = get_node_or_null(hud_node)
		if n: n.visible = false

	# Start fully black
	if _fade and _fade.has_method("fade_to_black"):
		_fade.fade_to_black(0.0)

	# Connect story event bus
	EventBus.story_event_triggered.connect(_on_story_event)
	EventBus.cinematic_ui_event.connect(_on_ui_event)
	EventBus.cinematic_finished.connect(_on_cinematic_finished, CONNECT_ONE_SHOT)

	# Apply opening color grade and lighting
	if _lighting_master and _lighting_master.has_method("apply_color_grade"):
		_lighting_master.apply_color_grade("ACT_1")
		_lighting_master.apply_lighting_profile("LAB_DAY")

	await get_tree().process_frame

	# Build and play the 150-second sequence
	var sequence: CinematicSequence = Cinematic14Builder.build()
	CinematicManager.play_sequence(sequence)


# ─────────────────────────────────────────────────────────────────
#  STORY EVENT ROUTING
# ─────────────────────────────────────────────────────────────────
func _on_story_event(event_id: String) -> void:
	match event_id:
		# ── Act 1: The Inventor ──────────────────────────────────────
		"lab_hero_working":
			_vfx("RobotActivationVFX",   Vector3(0, 0, 0),  0.3)
			_vfx("HolographicParticleVFX", Vector3(-1, 1, 0), 0.5)

		"hero_closeup_eyes", "hero_closeup_hands":
			_vfx("HolographicParticleVFX", Vector3(0, 1, 0), 0.3)

		# ── Act 2: The First Machine ─────────────────────────────────
		"robot_assembly_start":
			_vfx("SteamVFX", Vector3(0, 0.5, 0), 1.0)
			_vfx("SmallSparkBurst", Vector3(0.3, 0.8, 0), 0.5)

		"robot_activation":
			_vfx("RobotActivationVFX", Vector3(0, 0, 0), 1.0)
			_vfx("ElectricalArcVFX",   Vector3(0, 1, 0), 0.6)
			_vfx("EnergyPulseVFX",     Vector3(0, 0, 0), 1.0)
			_lighting("LAB_NIGHT")     # interior lights shift during activation
			_grade("ACT_2")

		"hero_approaches_robot":
			pass # subtle — no VFX, just camera and audio

		# ── Act 3: Ten Years ─────────────────────────────────────────
		"montage_year_01":
			_grade("ACT_1"); _lighting("LAB_DAY")
		"montage_year_03":
			_grade("ACT_2"); _lighting("LAB_DAY")
		"montage_year_05":
			_grade("ACT_2"); _lighting("CITY_DAY")
			_vfx("DustVFX",   Vector3(0, 2, 0), 2.0)
		"montage_year_07":
			_grade("ACT_3"); _lighting("CITY_DAY")
		"montage_year_08":
			_grade("ACT_3"); _lighting("CITY_DAY")
			_vfx("VehicleTrailVFX", Vector3(2, 5, 0), 1.0)
		"montage_year_09":
			_grade("ACT_3"); _lighting("CITY_NIGHT")
		"montage_year_10":
			_grade("ACT_3"); _lighting("CITY_NIGHT")
			_vfx("HolographicParticleVFX", Vector3(0, 3, 0), 2.0)

		# ── Act 4: The Decision ──────────────────────────────────────
		"hero_at_control":
			_grade("ACT_4"); _lighting("LAB_NIGHT")
			_vfx("HolographicParticleVFX", Vector3(-0.5, 1.5, 0), 0.8)
		"network_expand":
			_vfx("EnergyPulseVFX", Vector3(0, 0, 0), 1.5)
		"authorization_moment":
			_grade("ACT_4")

		# ── Act 5: The Night ─────────────────────────────────────────
		"robot_freeze":
			_grade("ACT_5"); _lighting("EMERGENCY")
			_vfx("ElectricalArcVFX", Vector3(0, 1, 0), 0.4)
		"robot_eye_red":
			_vfx("EmergencyPulseVFX", Vector3(0, 1.2, 0), 0.8)
		"robots_turn":
			_vfx("SystemFailureVFX",  Vector3(0, 0.5, 0), 1.0) if _vfx_exists("SystemFailureVFX") else _vfx("ElectricalArcVFX", Vector3(0, 0.5, 0), 1.0)
			_vfx("MediumSparkBurst",  Vector3(0.5, 0.5, 0), 0.5)
		"vehicle_malfunction":
			_grade("ACT_5"); _lighting("CITY_COLLAPSE")
			_vfx("MediumSparkBurst", Vector3(2, 2, 0), 0.8)
		"city_power_fail":
			_vfx("EmergencyPulseVFX", Vector3(0, 5, 0), 2.0)
		"chaos_erupts":
			_grade("ACT_5"); _lighting("CITY_COLLAPSE")
			_vfx("MediumExplosion", Vector3(3, 0, 3),  1.0)
			_vfx("HeavySmoke",      Vector3(2, 0, 2),  2.0)
			_vfx("FireVFX",         Vector3(-2, 0, 1), 1.0)
			_shake_camera("explosion")

		# ── Act 6: The Fall ──────────────────────────────────────────
		"robots_attack":
			_vfx("HeavySparkBurst", Vector3(0, 0.5, 0), 1.0)
			_shake_camera("impact")
		"vehicles_crash":
			_vfx("MediumExplosion", Vector3(0, 0, 0), 1.0)
			_vfx("DebrisVFX",       Vector3(0, 2, 0), 0.5)
			_shake_camera("explosion")
		"buildings_go_dark":
			_grade("ACT_6"); _lighting("CITY_COLLAPSE")
			_vfx("HeavySmoke", Vector3(5, 3, 5), 3.0)
		"hero_watches":
			_grade("ACT_6")
		"hero_face_change":
			_grade("ACT_7"); _lighting("HERO_REVEAL")

		# ── Act 7: The Realization ────────────────────────────────────
		"hero_walks_ruins":
			_grade("ACT_7"); _lighting("CITY_COLLAPSE")
			_vfx("DustVFX", Vector3(0, 0.2, 0), 0.5)
			_vfx("SmallSmoke", Vector3(1, 0, 1), 1.0)
		"hero_touches_robot":
			_vfx("SmallSparkBurst", Vector3(0, 1, 0), 0.3)
		"hero_realization":
			_grade("ACT_7")

		# ── Act 8: The Last Protocol ──────────────────────────────────
		"hero_prepares":
			_grade("ACT_8"); _lighting("HERO_REVEAL")
			_vfx("HolographicParticleVFX", Vector3(-0.5, 1.5, 0), 0.6)
		"final_resolve":
			_grade("ACT_8")
		"title_card":
			pass # handled by ui_event
		"gameplay_begin":
			pass # sequence ends, scene transition fires


func _on_ui_event(event: String) -> void:
	if not _ui_master: return
	match event:
		"YEAR_01_SHOW":             _ui_master.call("show_year", 1)
		"YEAR_03_SHOW":             _ui_master.call("show_year", 3)
		"YEAR_05_SHOW":             _ui_master.call("show_year", 5)
		"YEAR_07_SHOW":             _ui_master.call("show_year", 7)
		"YEAR_08_SHOW":             _ui_master.call("show_year", 8)
		"YEAR_09_SHOW":             _ui_master.call("show_year", 9)
		"YEAR_10_NETWORK_100":
			_ui_master.call("show_year", 10)
			_ui_master.call("show_network", 100, "GLOBAL MACHINE NETWORK")
		"SYSTEM_STATUS_ONLINE":     _ui_master.call("show_status", "SYSTEMS ONLINE")
		"ROBOT_DIAGNOSTIC_SHOW":    pass # scene-level node toggling
		"HOLOGRAPHIC_TERMINAL_SHOW": pass
		"NETWORK_EXPANDING":
			_ui_master.call("show_network", 73, "MACHINE NETWORK")
		"AUTHORIZATION_SHOW":       _ui_master.call("show_authorization")
		"WARNING_SYSTEM_FAILURE":   _ui_master.call("show_system_failure")
		"WARNING_CRITICAL":         _ui_master.call("show_warning", "CRITICAL MALFUNCTION")
		"SYSTEM_FAILURE_SHOW":      _ui_master.call("show_system_failure")
		"CRITICAL_FAILURE_SHOW":    _ui_master.call("show_critical_failure")
		"TITLE_CARD_SHOW":          _ui_master.call("show_title", "THE LAST PROTOCOL")


func _on_cinematic_finished(sequence_id: String) -> void:
	if sequence_id != "cinematic_14_the_last_protocol": return
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
	get_tree().change_scene_to_file("res://main.tscn")


# ─────────────────────────────────────────────────────────────────
#  INTERNAL SHORTCUTS
# ─────────────────────────────────────────────────────────────────
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
