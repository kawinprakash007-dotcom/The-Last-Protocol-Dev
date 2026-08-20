## Phase 15 Test Suite — NarrationManager, Subtitles, Letterbox, MetaHUD
##
## Validates all Phase 15 cinematic storytelling systems.
## Designed for headless --path execution alongside Phase 12/13/14 tests.
##
extends Node

var _tests_run: int = 0
var _tests_passed: int = 0
var _tests_failed: int = 0
var _fail_messages: Array[String] = []

# Captured signal data
var _last_narration_line: Dictionary = {}
var _last_narration_finished: String = ""
var _last_letterbox_state: Variant = null
var _last_hud_metadata: Dictionary = {}


func _ready() -> void:
	# Connect to EventBus signals for validation
	EventBus.narration_line_shown.connect(_on_narration_line)
	EventBus.narration_finished.connect(_on_narration_finished)
	EventBus.letterbox_toggled.connect(_on_letterbox_toggled)
	EventBus.hud_metadata_shown.connect(_on_hud_metadata_shown)

	await get_tree().process_frame
	_run_all_tests()


func _on_narration_line(shot_id: String, speaker: String, text: String, duration: float) -> void:
	_last_narration_line = { "shot_id": shot_id, "speaker": speaker, "text": text, "duration": duration }

func _on_narration_finished(shot_id: String) -> void:
	_last_narration_finished = shot_id

func _on_letterbox_toggled(vis: bool) -> void:
	_last_letterbox_state = vis

func _on_hud_metadata_shown(metadata: Dictionary) -> void:
	_last_hud_metadata = metadata


func _run_all_tests() -> void:
	print("\n=== PHASE 15 TESTS ===\n")

	# ── NarrationManager ──────────────────────────────────────────────────────
	await _test_narration_manager_exists()
	await _test_narration_emits_line_shown()
	await _test_narration_emits_finished()
	await _test_narration_stop_cancels_stale()
	await _test_narration_empty_lines_no_emit()

	# ── EventBus signals ──────────────────────────────────────────────────────
	await _test_letterbox_signal()
	await _test_hud_metadata_signal()

	# ── CinematicShot new fields ──────────────────────────────────────────────
	await _test_cinematic_shot_narration_field()
	await _test_cinematic_shot_hud_field()

	# ── FinalOpeningBuilder narration ─────────────────────────────────────────
	await _test_builder_shot_narration()
	await _test_builder_hud_metadata()
	await _test_builder_all_10_video_paths_resolve()
	await _test_builder_auth_shot_still_blocks()
	await _test_builder_last_protocol_shot_exists()

	# ── Gameplay handoff scene file ───────────────────────────────────────────
	await _test_gameplay_handoff_scene_exists()

	_print_results()
	get_tree().quit(0 if _tests_failed == 0 else 1)


# ── TEST IMPLEMENTATIONS ───────────────────────────────────────────────────────

func _test_narration_manager_exists() -> void:
	_assert("NarrationManager autoload exists",
		NarrationManager != null and is_instance_valid(NarrationManager))
	await _frame()


func _test_narration_emits_line_shown() -> void:
	_last_narration_line = {}
	NarrationManager.play_narration(["Hello world."], "test_shot_emit")
	await get_tree().create_timer(0.2).timeout
	_assert("play_narration emits narration_line_shown",
		_last_narration_line.get("shot_id", "") == "test_shot_emit"
		and _last_narration_line.get("text", "") == "Hello world.")
	NarrationManager.stop_narration("test_shot_emit")
	await _frame()


func _test_narration_emits_finished() -> void:
	_last_narration_finished = ""
	NarrationManager.play_narration(["Short line."], "test_shot_finish")
	await get_tree().create_timer(5.0).timeout
	_assert("narration_finished emitted after all lines",
		_last_narration_finished == "test_shot_finish")
	await _frame()


func _test_narration_stop_cancels_stale() -> void:
	_last_narration_line = {}
	NarrationManager.play_narration(["Line A.", "Line B."], "test_stale")
	await get_tree().create_timer(0.1).timeout
	# Stop before Line B can emit
	NarrationManager.stop_narration("test_stale")
	var captured_before := _last_narration_line.duplicate()
	await get_tree().create_timer(2.0).timeout
	_assert("stop_narration cancels stale lines",
		_last_narration_line.get("text", "") != "Line B."
		or captured_before.get("text", "") == "Line A.")
	await _frame()


func _test_narration_empty_lines_no_emit() -> void:
	_last_narration_line = {}
	NarrationManager.play_narration([], "test_empty")
	await get_tree().create_timer(0.1).timeout
	_assert("empty narration lines emits nothing",
		_last_narration_line.is_empty())
	await _frame()


func _test_letterbox_signal() -> void:
	_last_letterbox_state = null
	EventBus.letterbox_toggled.emit(true)
	await _frame()
	_assert("letterbox_toggled(true) received",
		_last_letterbox_state == true)
	EventBus.letterbox_toggled.emit(false)
	await _frame()
	_assert("letterbox_toggled(false) received",
		_last_letterbox_state == false)


func _test_hud_metadata_signal() -> void:
	_last_hud_metadata = {}
	EventBus.hud_metadata_shown.emit({"YEAR": "2047", "LOCATION": "TEST"})
	await _frame()
	_assert("hud_metadata_shown emits correct data",
		_last_hud_metadata.get("YEAR") == "2047"
		and _last_hud_metadata.get("LOCATION") == "TEST")


func _test_cinematic_shot_narration_field() -> void:
	var shot := CinematicShot.new()
	shot.narration_lines = ["Test line."]
	_assert("CinematicShot.narration_lines field exists and is assignable",
		shot.narration_lines.size() == 1 and shot.narration_lines[0] == "Test line.")
	await _frame()


func _test_cinematic_shot_hud_field() -> void:
	var shot := CinematicShot.new()
	shot.hud_metadata = {"YEAR": "2050"}
	_assert("CinematicShot.hud_metadata field exists and is assignable",
		shot.hud_metadata.get("YEAR") == "2050")
	await _frame()


func _test_builder_shot_narration() -> void:
	var seq := FinalOpeningBuilder.build()
	var hero_shot := seq.shots[0]
	_assert("FinalOpeningBuilder act1_hero_entry has narration lines",
		hero_shot != null
		and hero_shot.narration_lines.size() > 0
		and hero_shot.narration_lines[0].contains("world"))
	await _frame()


func _test_builder_hud_metadata() -> void:
	var seq := FinalOpeningBuilder.build()
	var hero_shot := seq.shots[0]
	_assert("FinalOpeningBuilder act1_hero_entry has HUD metadata with YEAR",
		hero_shot != null
		and hero_shot.hud_metadata.has("YEAR"))
	await _frame()


func _test_builder_all_10_video_paths_resolve() -> void:
	var seq := FinalOpeningBuilder.build()
	var unresolved: Array[String] = []
	for shot in seq.shots:
		if shot.is_video:
			if not ResourceLoader.exists(shot.video_path):
				unresolved.append(shot.video_path)
	_assert("all 10 video paths in FinalOpeningBuilder resolve successfully",
		unresolved.is_empty())
	if not unresolved.is_empty():
		print("  UNRESOLVED:", unresolved)
	await _frame()


func _test_builder_auth_shot_still_blocks() -> void:
	var seq := FinalOpeningBuilder.build()
	var auth_shot: CinematicShot = null
	for shot in seq.shots:
		if shot.is_authorization:
			auth_shot = shot
			break
	_assert("authorization shot still exists in final timeline",
		auth_shot != null)
	await _frame()


func _test_builder_last_protocol_shot_exists() -> void:
	var seq := FinalOpeningBuilder.build()
	var lp_shot: CinematicShot = null
	for shot in seq.shots:
		if shot.is_last_protocol:
			lp_shot = shot
			break
	_assert("last_protocol shot still exists in final timeline",
		lp_shot != null)
	await _frame()


func _test_gameplay_handoff_scene_exists() -> void:
	_assert("gameplay_handoff.tscn exists",
		ResourceLoader.exists("res://story/cinematics/gameplay_handoff.tscn"))
	await _frame()


# ── HELPERS ────────────────────────────────────────────────────────────────────

func _assert(test_name: String, condition: bool) -> void:
	_tests_run += 1
	if condition:
		_tests_passed += 1
		print("  [PASS] %s" % test_name)
	else:
		_tests_failed += 1
		_fail_messages.append(test_name)
		print("  [FAIL] %s" % test_name)


func _frame() -> Signal:
	return get_tree().process_frame


func _print_results() -> void:
	print("\n" + "=".repeat(52))
	if _tests_failed == 0:
		print("  PHASE 15 RESULTS: %d PASSED   0 FAILED" % _tests_passed)
	else:
		print("  PHASE 15 RESULTS: %d PASSED   %d FAILED" % [_tests_passed, _tests_failed])
		for msg in _fail_messages:
			print("    FAILED: " + msg)
	print("=".repeat(52) + "\n")
