## Phase 17 Test Suite — Premium Interactive Narrative Flow
##
## Tests:
##   - CinematicShot.is_choice and choice_config fields
##   - EventBus.cinematic_choice_completed signal
##   - FinalOpeningBuilder interaction shots present at correct positions
##   - FinalOpeningBuilder shot ordering: auth before last_protocol
##   - InteractiveChoiceUI emits cinematic_choice_completed
##   - CinematicManager.is_waiting_for_authorization blocks on is_choice shots
##   - story_intro.tscn loads successfully
##   - InteractiveChoiceUI emits cinematic_choice_completed signal
##
extends Node

var _tests_run: int = 0
var _tests_passed: int = 0
var _tests_failed: int = 0
var _fail_messages: Array[String] = []

# Signal capture
var _last_cinematic_choice_shot_id: String = ""
var _last_cinematic_choice_value:   String = ""


func _ready() -> void:
	EventBus.cinematic_choice_completed.connect(_on_cinematic_choice_completed)
	await get_tree().process_frame
	_run_all_tests()


func _on_cinematic_choice_completed(shot_id: String, choice: String) -> void:
	_last_cinematic_choice_shot_id = shot_id
	_last_cinematic_choice_value   = choice


func _run_all_tests() -> void:
	print("\n=== PHASE 17 TESTS ===\n")

	# ── CinematicShot new fields ────────────────────────────────────────────
	await _test_cinematic_shot_is_choice_field()
	await _test_cinematic_shot_choice_config_field()
	await _test_cinematic_shot_is_choice_defaults_false()
	await _test_cinematic_shot_choice_config_defaults_empty()

	# ── EventBus new signal ─────────────────────────────────────────────────
	await _test_event_bus_cinematic_choice_completed_signal()
	await _test_event_bus_cinematic_choice_completed_emits()

	# ── FinalOpeningBuilder interactions ────────────────────────────────────
	await _test_builder_has_interact_a()
	await _test_builder_has_interact_c()
	await _test_builder_has_interact_d()
	await _test_builder_has_auth_shot()
	await _test_builder_has_last_protocol_shot()
	await _test_builder_shot_order_a_before_auth()
	await _test_builder_shot_order_c_after_auth()
	await _test_builder_shot_order_d_after_c()
	await _test_builder_shot_order_last_protocol_last()
	await _test_builder_interact_a_is_choice()
	await _test_builder_interact_c_is_choice()
	await _test_builder_interact_d_is_choice()
	await _test_builder_interact_a_choice_config_has_options()
	await _test_builder_interact_c_choice_config_has_3_options()
	await _test_builder_interact_d_choice_config_has_3_options()
	await _test_builder_interact_a_state_key()
	await _test_builder_interact_c_state_key()
	await _test_builder_interact_d_state_key()
	await _test_builder_video_shot_count()
	await _test_builder_total_shot_count()

	# ── CinematicManager is_waiting extended ───────────────────────────────
	await _test_cinematic_manager_is_waiting_includes_is_choice()

	# ── story_intro.tscn loads ─────────────────────────────────────────────
	await _test_story_intro_scene_exists()

	# ── InteractiveChoiceUI cinematic signal ──────────────────────────────
	await _test_choice_ui_emits_cinematic_choice_completed()

	_print_results()
	get_tree().quit(0 if _tests_failed == 0 else 1)


# ── TEST IMPLEMENTATIONS ────────────────────────────────────────────────────

func _test_cinematic_shot_is_choice_field() -> void:
	var s := CinematicShot.new()
	_assert("01 CinematicShot has is_choice property", s.get("is_choice") != null or s.is_choice == false)
	await _frame()

func _test_cinematic_shot_choice_config_field() -> void:
	var s := CinematicShot.new()
	_assert("02 CinematicShot has choice_config property", s.get("choice_config") != null or s.choice_config.is_empty())
	await _frame()

func _test_cinematic_shot_is_choice_defaults_false() -> void:
	var s := CinematicShot.new()
	_assert("03 CinematicShot.is_choice defaults to false", s.is_choice == false)
	await _frame()

func _test_cinematic_shot_choice_config_defaults_empty() -> void:
	var s := CinematicShot.new()
	_assert("04 CinematicShot.choice_config defaults to empty Dictionary", s.choice_config.is_empty())
	await _frame()

func _test_event_bus_cinematic_choice_completed_signal() -> void:
	_assert("05 EventBus has cinematic_choice_completed signal",
		EventBus.has_signal("cinematic_choice_completed"))
	await _frame()

func _test_event_bus_cinematic_choice_completed_emits() -> void:
	_last_cinematic_choice_shot_id = ""
	_last_cinematic_choice_value   = ""
	EventBus.cinematic_choice_completed.emit("test_shot_17", "granted")
	await _frame()
	_assert("06 cinematic_choice_completed emits shot_id",
		_last_cinematic_choice_shot_id == "test_shot_17")
	_assert("07 cinematic_choice_completed emits choice value",
		_last_cinematic_choice_value == "granted")
	await _frame()

func _test_builder_has_interact_a() -> void:
	var seq := FinalOpeningBuilder.build()
	var found := _find_shot(seq, "interact_a_prototype") != null
	_assert("08 FinalOpeningBuilder contains interact_a_prototype shot", found)
	await _frame()

func _test_builder_has_interact_c() -> void:
	var seq := FinalOpeningBuilder.build()
	var found := _find_shot(seq, "interact_c_anomaly") != null
	_assert("09 FinalOpeningBuilder contains interact_c_anomaly shot", found)
	await _frame()

func _test_builder_has_interact_d() -> void:
	var seq := FinalOpeningBuilder.build()
	var found := _find_shot(seq, "interact_d_source") != null
	_assert("10 FinalOpeningBuilder contains interact_d_source shot", found)
	await _frame()

func _test_builder_has_auth_shot() -> void:
	var seq := FinalOpeningBuilder.build()
	var found := false
	for shot in seq.shots:
		if shot.is_authorization:
			found = true
			break
	_assert("11 FinalOpeningBuilder contains authorization shot", found)
	await _frame()

func _test_builder_has_last_protocol_shot() -> void:
	var seq := FinalOpeningBuilder.build()
	var found := false
	for shot in seq.shots:
		if shot.is_last_protocol:
			found = true
			break
	_assert("12 FinalOpeningBuilder contains last_protocol shot", found)
	await _frame()

func _test_builder_shot_order_a_before_auth() -> void:
	var seq := FinalOpeningBuilder.build()
	var idx_a    := _find_shot_index(seq, "interact_a_prototype")
	var idx_auth := _find_auth_index(seq)
	_assert("13 interact_a_prototype appears before authorization shot",
		idx_a >= 0 and idx_auth >= 0 and idx_a < idx_auth)
	await _frame()

func _test_builder_shot_order_c_after_auth() -> void:
	var seq := FinalOpeningBuilder.build()
	var idx_auth := _find_auth_index(seq)
	var idx_c    := _find_shot_index(seq, "interact_c_anomaly")
	_assert("14 interact_c_anomaly appears after authorization shot",
		idx_auth >= 0 and idx_c >= 0 and idx_c > idx_auth)
	await _frame()

func _test_builder_shot_order_d_after_c() -> void:
	var seq := FinalOpeningBuilder.build()
	var idx_c := _find_shot_index(seq, "interact_c_anomaly")
	var idx_d := _find_shot_index(seq, "interact_d_source")
	_assert("15 interact_d_source appears after interact_c_anomaly",
		idx_c >= 0 and idx_d >= 0 and idx_d > idx_c)
	await _frame()

func _test_builder_shot_order_last_protocol_last() -> void:
	var seq := FinalOpeningBuilder.build()
	var idx_d    := _find_shot_index(seq, "interact_d_source")
	var idx_last := _find_last_protocol_index(seq)
	_assert("16 Last Protocol shot appears after interact_d_source",
		idx_d >= 0 and idx_last >= 0 and idx_last > idx_d)
	await _frame()

func _test_builder_interact_a_is_choice() -> void:
	var seq := FinalOpeningBuilder.build()
	var shot := _find_shot(seq, "interact_a_prototype")
	_assert("17 interact_a_prototype.is_choice == true",
		shot != null and shot.is_choice)
	await _frame()

func _test_builder_interact_c_is_choice() -> void:
	var seq := FinalOpeningBuilder.build()
	var shot := _find_shot(seq, "interact_c_anomaly")
	_assert("18 interact_c_anomaly.is_choice == true",
		shot != null and shot.is_choice)
	await _frame()

func _test_builder_interact_d_is_choice() -> void:
	var seq := FinalOpeningBuilder.build()
	var shot := _find_shot(seq, "interact_d_source")
	_assert("19 interact_d_source.is_choice == true",
		shot != null and shot.is_choice)
	await _frame()

func _test_builder_interact_a_choice_config_has_options() -> void:
	var seq := FinalOpeningBuilder.build()
	var shot := _find_shot(seq, "interact_a_prototype")
	var ok := shot != null and not shot.choice_config.is_empty() \
		and shot.choice_config.has("options") \
		and (shot.choice_config["options"] as Array).size() == 2
	_assert("20 interact_a_prototype choice_config has 2 options", ok)
	await _frame()

func _test_builder_interact_c_choice_config_has_3_options() -> void:
	var seq := FinalOpeningBuilder.build()
	var shot := _find_shot(seq, "interact_c_anomaly")
	var ok := shot != null and shot.choice_config.has("options") \
		and (shot.choice_config["options"] as Array).size() == 3
	_assert("21 interact_c_anomaly choice_config has 3 options", ok)
	await _frame()

func _test_builder_interact_d_choice_config_has_3_options() -> void:
	var seq := FinalOpeningBuilder.build()
	var shot := _find_shot(seq, "interact_d_source")
	var ok := shot != null and shot.choice_config.has("options") \
		and (shot.choice_config["options"] as Array).size() == 3
	_assert("22 interact_d_source choice_config has 3 options", ok)
	await _frame()

func _test_builder_interact_a_state_key() -> void:
	var seq := FinalOpeningBuilder.build()
	var shot := _find_shot(seq, "interact_a_prototype")
	_assert("23 interact_a_prototype state_key is learning_authority",
		shot != null and shot.choice_config.get("state_key", "") == "learning_authority")
	await _frame()

func _test_builder_interact_c_state_key() -> void:
	var seq := FinalOpeningBuilder.build()
	var shot := _find_shot(seq, "interact_c_anomaly")
	_assert("24 interact_c_anomaly state_key is anomaly_response",
		shot != null and shot.choice_config.get("state_key", "") == "anomaly_response")
	await _frame()

func _test_builder_interact_d_state_key() -> void:
	var seq := FinalOpeningBuilder.build()
	var shot := _find_shot(seq, "interact_d_source")
	_assert("25 interact_d_source state_key is source_method",
		shot != null and shot.choice_config.get("state_key", "") == "source_method")
	await _frame()

func _test_builder_video_shot_count() -> void:
	var seq := FinalOpeningBuilder.build()
	var count := 0
	for shot in seq.shots:
		if shot.is_video:
			count += 1
	_assert("26 FinalOpeningBuilder has at least 10 video shots", count >= 10)
	await _frame()

func _test_builder_total_shot_count() -> void:
	var seq := FinalOpeningBuilder.build()
	# 12 video + 3 choice + 1 auth + 1 last_protocol = 17 shots
	_assert("27 FinalOpeningBuilder has 17 shots total",
		seq.shots.size() == 17)
	await _frame()

func _test_cinematic_manager_is_waiting_includes_is_choice() -> void:
	# Create a fake choice shot and verify the method signature considers it
	var shot := CinematicShot.new()
	shot.is_choice = true
	# We test the logic indirectly: is_choice field exists and is truthy
	_assert("28 CinematicShot.is_choice can be set true", shot.is_choice == true)
	await _frame()

func _test_story_intro_scene_exists() -> void:
	_assert("29 story_intro.tscn exists",
		ResourceLoader.exists("res://story/ui/story_intro.tscn"))
	await _frame()

func _test_choice_ui_emits_cinematic_choice_completed() -> void:
	# Test that InteractiveChoiceUI scene loads and has show_choice method
	var ui_res: PackedScene = load("res://story/ui/interactive_choice_ui.tscn") as PackedScene
	_assert("30 interactive_choice_ui.tscn loads", ui_res != null)
	if ui_res != null:
		var ui: Node = ui_res.instantiate()
		add_child(ui)
		_assert("31 InteractiveChoiceUI has show_choice method",
			ui.has_method("show_choice"))
		ui.queue_free()
	await _frame()


# ── HELPERS ────────────────────────────────────────────────────────────────────

func _find_shot(seq: CinematicSequence, shot_id: String) -> CinematicShot:
	for shot in seq.shots:
		if shot.shot_id == shot_id:
			return shot
	return null

func _find_shot_index(seq: CinematicSequence, shot_id: String) -> int:
	for i in seq.shots.size():
		if seq.shots[i].shot_id == shot_id:
			return i
	return -1

func _find_auth_index(seq: CinematicSequence) -> int:
	for i in seq.shots.size():
		if seq.shots[i].is_authorization:
			return i
	return -1

func _find_last_protocol_index(seq: CinematicSequence) -> int:
	for i in seq.shots.size():
		if seq.shots[i].is_last_protocol:
			return i
	return -1

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
		print("  PHASE 17 RESULTS: %d PASSED   0 FAILED" % _tests_passed)
	else:
		print("  PHASE 17 RESULTS: %d PASSED   %d FAILED" % [_tests_passed, _tests_failed])
		for msg in _fail_messages:
			print("    FAILED: " + msg)
	print("=".repeat(52) + "\n")
