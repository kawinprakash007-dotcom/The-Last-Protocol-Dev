## DevOpeningTest — Automated validation for the Phase 6 opening cinematic.
##
## Tests are organized in three groups:
##   A. Sequence Structure (pure GDScript, no scene dependency)
##   B. Scene Infrastructure (nodes, markers, UI loads)
##   C. Runtime Behaviour (play, signal, skip safety)
##
## Expected: 19/19 PASS, 0 FAIL, exit code 0.
## All warnings about missing audio keys are expected (placeholder keys).

extends Node3D

@onready var camera_controller: Node = $CinematicCameraController
@onready var cinematic_camera: Camera3D = $CinematicCamera
@onready var gameplay_camera: Camera3D = $GameplayCamera
@onready var fade: Node = $CinematicFade
@onready var dialogue_ui: DialogueUI = $DialogueUI
@onready var objective_hud: Node = $ObjectiveHUD

var _pass_count: int = 0
var _fail_count: int = 0
var _cinematic_started_count: int = 0
var _cinematic_finished_count: int = 0
var _lock_count: int = 0
var _unlock_count: int = 0
var _story_event_received: String = ""
var _objective_received: String = ""


func _ready() -> void:
	EventBus.cinematic_started.connect(func(_id: String): _cinematic_started_count += 1)
	EventBus.cinematic_finished.connect(func(_id: String): _cinematic_finished_count += 1)
	EventBus.cinematic_mode_toggled.connect(func(locked: bool):
		if locked: _lock_count += 1 else: _unlock_count += 1
	)
	EventBus.story_event_triggered.connect(func(ev: String): _story_event_received = ev)
	EventBus.objective_started.connect(func(txt: String): _objective_received = txt)

	await get_tree().process_frame
	await _run_tests()


func _run_tests() -> void:
	print("\n====================================================")
	print("  THE LAST PROTOCOL - OPENING CINEMATIC VALIDATION")
	print("====================================================\n")

	await _group_a_sequence_structure()
	await _group_b_scene_infrastructure()
	await _group_c_runtime_behaviour()

	print("\n====================================================")
	print("  RESULTS: %d PASSED   %d FAILED" % [_pass_count, _fail_count])
	print("====================================================\n")
	get_tree().quit(_fail_count)


# ── GROUP A — SEQUENCE STRUCTURE ──────────────────────────────────────────────
# Pure GDScript. No scene nodes needed.

func _group_a_sequence_structure() -> void:
	var sequence: CinematicSequence = OpeningSequenceBuilder.build()

	_check(sequence != null,
		"01 OpeningSequenceBuilder.build() returns a CinematicSequence")

	_check(sequence.sequence_id == "opening_protocol",
		"02 sequence_id is 'opening_protocol'")

	_check(sequence.shots.size() == 8,
		"03 sequence has exactly 8 shots")

	# All shot IDs are non-empty and unique
	var ids: Array[String] = []
	var all_ids_ok := true
	for s in sequence.shots:
		if s.shot_id.is_empty() or ids.has(s.shot_id):
			all_ids_ok = false
			break
		ids.append(s.shot_id)
	_check(all_ids_ok, "04 all shot IDs are non-empty and unique")

	# Shot 01 — Hero Working
	var s01: CinematicShot = sequence.shots[0]
	_check(s01.music_key == "curiosity_theme",
		"05 shot 01 music_key is curiosity_theme")

	# Shot 02 — Robot Construction
	var s02: CinematicShot = sequence.shots[1]
	_check(s02.sfx_keys.has("welding_sparks") and s02.sfx_keys.has("steam_release"),
		"06 shot 02 has welding and steam SFX hooks")
	_check(_first_speaker(s02) == "NARRATION",
		"07 shot 02 narration speaker is NARRATION")

	# Shot 05 — Year 5
	var s05: CinematicShot = sequence.shots[4]
	_check(s05.ui_event == "SHOW_YEAR5",
		"08 shot 05 ui_event is SHOW_YEAR5")

	# Shot 07 — Year 10
	var s07: CinematicShot = sequence.shots[6]
	_check(s07.ui_event == "SHOW_YEAR10",
		"09 shot 07 ui_event is SHOW_YEAR10")
	_check(_first_speaker(s07) == "NARRATION",
		"10 shot 07 speaker is NARRATION")

	# Shot 08 — The Authority
	var s08: CinematicShot = sequence.shots[7]
	_check(s08.music_key == "decision_theme",
		"11 shot 08 music_key is decision_theme")
	_check(s08.ui_event == "SHOW_AUTHORIZATION",
		"12 shot 08 ui_event is SHOW_AUTHORIZATION")
	_check(s08.story_event_on_start == "authority_activate_start",
		"13 shot 08 story_event_on_start is authority_activate_start")
	_check(not s08.lock_player,
		"14 shot 08 lock_player is false")
	_check(s08.duration == 8.0,
		"15 shot 08 duration is 8.0 seconds")


# ── GROUP B — SCENE INFRASTRUCTURE ────────────────────────────────────────────
# Verifies required nodes, markers, and UI are present and ready.

func _group_b_scene_infrastructure() -> void:
	_check(camera_controller != null,
		"16 CinematicCameraController loads")
	_check(fade != null,
		"17 CinematicFade loads")
	_check(dialogue_ui != null,
		"18 DialogueUI loads")
	_check(objective_hud != null,
		"19 ObjectiveHUD loads")

	# All markers used by the sequence must exist in the test scene
	var required_markers := [
		"CinematicMarkers/Lab_HeroFocus",
		"CinematicMarkers/Assembly_Close",
		"CinematicMarkers/Lab_WalkTrack",
		"CinematicMarkers/Year3_Dolly",
		"CinematicMarkers/Year5_City",
		"CinematicMarkers/Year7_Traffic",
		"CinematicMarkers/Year10_HighPoint",
		"CinematicMarkers/Control_Authorize",
	]
	var all_markers_ok := true
	for marker_path in required_markers:
		if get_node_or_null(marker_path) == null:
			all_markers_ok = false
			push_warning("DevOpeningTest: Required marker missing: " + marker_path)
			break
	_check(all_markers_ok,
		"20 all 8 required camera markers exist in test scene")


# ── GROUP C — RUNTIME BEHAVIOUR ────────────────────────────────────────────────
# Brief play test followed by a safe stop.

func _group_c_runtime_behaviour() -> void:
	# Reset counters from any earlier interference
	_cinematic_started_count = 0
	_cinematic_finished_count = 0
	_lock_count = 0
	_unlock_count = 0
	_story_event_received = ""

	var sequence := OpeningSequenceBuilder.build()
	CinematicManager.play_sequence(sequence)

	# Wait long enough for shot 01 and 02 to begin
	await get_tree().create_timer(0.6).timeout
	await get_tree().process_frame

	_check(_cinematic_started_count == 1,
		"21 cinematic_started emitted when opening plays")
	_check(_lock_count >= 1,
		"22 player is locked during opening cinematic")
	_check(CinematicManager.is_active,
		"23 CinematicManager reports active during opening")

	# Safe stop — must not crash and must restore all state
	CinematicManager.stop()
	await get_tree().create_timer(0.3).timeout
	await get_tree().process_frame

	_check(not CinematicManager.is_active,
		"24 CinematicManager is inactive after stop()")
	_check(_unlock_count >= 1,
		"25 player unlocked after stop()")
	_check(camera_controller.is_gameplay_camera_current(),
		"26 gameplay camera restored after stop()")
	_check(not cinematic_camera.current,
		"27 cinematic camera released after stop()")


# ── HELPERS ───────────────────────────────────────────────────────────────────

func _check(condition: bool, label: String) -> void:
	if condition:
		_pass_count += 1
		print("  [PASS] " + label)
	else:
		_fail_count += 1
		print("  [FAIL] " + label)


func _first_speaker(shot: CinematicShot) -> String:
	if shot.dialogue_sequence == null or shot.dialogue_sequence.lines.is_empty():
		return ""
	return shot.dialogue_sequence.lines[0].speaker_id


func _has_speaker(shot: CinematicShot, speaker_id: String) -> bool:
	if shot.dialogue_sequence == null:
		return false
	for line in shot.dialogue_sequence.lines:
		if line.speaker_id == speaker_id:
			return true
	return false
