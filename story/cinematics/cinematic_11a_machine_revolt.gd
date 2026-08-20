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
		_lighting_master.apply_lighting_profile("CITY_DAY")

	await get_tree().process_frame

	var sequence: CinematicSequence = Cinematic11ABuilder.build()
	CinematicManager.play_sequence(sequence)


func _on_story_event(event_id: String) -> void:
	match event_id:
		"peaceful_city":
			_grade("ACT_3"); _lighting("CITY_DAY")
		"robot_eye_glitch":
			_vfx("ElectricalArcVFX", Vector3(0, 1.5, 0), 0.5)
			_shake_camera("impact")
		"second_robot_turns":
			_vfx("MediumSparkBurst", Vector3(0, 1, 0), 0.5)
		"human_panic":
			_grade("ACT_5"); _lighting("EMERGENCY")
			_vfx("EmergencyPulseVFX", Vector3(0, 5, 0), 2.0)
		"robot_attack":
			_vfx("HeavySparkBurst", Vector3(0, 1, 0), 1.0)
			_shake_camera("impact")
		"vehicle_crash":
			_vfx("MediumExplosion", Vector3(2, 3, 0), 1.5)
			_vfx("DebrisVFX", Vector3(2, 3, 0), 1.0)
			_shake_camera("explosion")
		"city_security_failure":
			_lighting("CITY_COLLAPSE")
			_vfx("SystemFailureVFX", Vector3(0, 2, 0), 2.0) if _vfx_exists("SystemFailureVFX") else _vfx("ElectricalArcVFX", Vector3(0, 2, 0), 2.0)
		"robot_swarm":
			_vfx("HeavySmoke", Vector3(0, 0, 0), 3.0)
			_vfx("FireVFX", Vector3(3, 0, -2), 2.0)
		"hero_watches_revolt":
			_grade("ACT_5")
		"lab_malfunctions":
			_lighting("EMERGENCY")
			_vfx("MediumSparkBurst", Vector3(-2, 2, 0), 1.0)
		"world_falls":
			_grade("ACT_6"); _lighting("CITY_COLLAPSE")
			_vfx("HeavyExplosion", Vector3(5, 5, 5), 2.0) if _vfx_exists("HeavyExplosion") else _vfx("MediumExplosion", Vector3(5,5,5), 2.0)
			_vfx("HeavySmoke", Vector3(-5, 0, 5), 4.0)
			_shake_camera("explosion")
		"destroyed_street":
			_grade("ACT_7"); _lighting("CITY_COLLAPSE")
			_vfx("SmallSmoke", Vector3(0, 0, 0), 1.5)
		"hero_realization_revolt":
			_grade("ACT_7")
		"final_world_shot":
			_grade("ACT_8")

func _on_ui_event(event: String) -> void:
	if not _ui_master: return
	match event:
		"NETWORK_ERROR_SHOW":
			_ui_master.call("show_warning", "MACHINE NETWORK: CONNECTION ERROR")
		"SECURITY_OVERRIDE_SHOW":
			_ui_master.call("show_authorization") # Similar visual for override
		"CITY_FAILURE_SHOW":
			_ui_master.call("show_system_failure")
		"GLOBAL_CRITICAL_SHOW":
			_ui_master.call("show_critical_failure")

func _on_cinematic_finished(sequence_id: String) -> void:
	if sequence_id != "cinematic_11a_machine_revolt": return
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
