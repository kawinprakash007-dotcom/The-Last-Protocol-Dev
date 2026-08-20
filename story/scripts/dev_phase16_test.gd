## Phase 16 Test Suite — Interactive Gameplay Loop
##
## Tests StoryState, EventBus signals, InteractiveChoiceUI config,
## player locking, and story consequences.
## Runs headless alongside Phase 12-15 tests.
##
extends Node

var _tests_run: int = 0
var _tests_passed: int = 0
var _tests_failed: int = 0
var _fail_messages: Array[String] = []

# Signal capture state
var _last_choice_key: String = ""
var _last_choice_val: String = ""
var _last_interaction_started: String = ""
var _last_interaction_finished: String = ""
var _cinematic_locked: bool = false


func _ready() -> void:
	EventBus.story_choice_made.connect(_on_choice_made)
	EventBus.player_interaction_started.connect(_on_interaction_started)
	EventBus.player_interaction_finished.connect(_on_interaction_finished)
	EventBus.cinematic_mode_toggled.connect(_on_cinematic_mode_toggled)
	await get_tree().process_frame
	_run_all_tests()


func _on_choice_made(key: String, val: String) -> void:
	_last_choice_key = key
	_last_choice_val = val

func _on_interaction_started(id: String) -> void:
	_last_interaction_started = id

func _on_interaction_finished(id: String) -> void:
	_last_interaction_finished = id

func _on_cinematic_mode_toggled(locked: bool) -> void:
	_cinematic_locked = locked


func _run_all_tests() -> void:
	print("\n=== PHASE 16 TESTS ===\n")

	# ── StoryState ────────────────────────────────────────────────────────────
	await _test_story_state_exists()
	await _test_story_state_set_get()
	await _test_story_state_has()
	await _test_story_state_clear()
	await _test_story_state_default_value()

	# ── EventBus new signals ──────────────────────────────────────────────────
	await _test_story_choice_signal()
	await _test_player_interaction_started_signal()
	await _test_player_interaction_finished_signal()

	# ── InteractiveChoiceUI ───────────────────────────────────────────────────
	await _test_choice_ui_loads()
	await _test_choice_ui_show_hides()
	await _test_choice_ui_emits_story_choice()
	await _test_choice_ui_stores_in_story_state()
	await _test_choice_ui_locks_player()
	await _test_choice_ui_unlocks_after_selection()

	# ── Choice consequences recorded correctly ────────────────────────────────
	await _test_permission_granted_stored()
	await _test_permission_denied_stored()
	await _test_diagnostic_optimal_stored()
	await _test_diagnostic_alternate_stored()

	# ── Main scene sanity ─────────────────────────────────────────────────────
	await _test_main_scene_exists()
	await _test_interactive_choice_ui_in_main()

	_print_results()
	get_tree().quit(0 if _tests_failed == 0 else 1)


# ── TEST IMPLEMENTATIONS ───────────────────────────────────────────────────────

func _test_story_state_exists() -> void:
	_assert("StoryState autoload exists", StoryState != null and is_instance_valid(StoryState))
	await _frame()


func _test_story_state_set_get() -> void:
	StoryState.set_state("test_key", "test_value")
	_assert("StoryState.set_state / get_state works",
		StoryState.get_state("test_key") == "test_value")
	await _frame()


func _test_story_state_has() -> void:
	StoryState.set_state("has_key", 42)
	_assert("StoryState.has_state() returns true for set key",
		StoryState.has_state("has_key"))
	_assert("StoryState.has_state() returns false for unknown key",
		not StoryState.has_state("never_set_xyz"))
	await _frame()


func _test_story_state_clear() -> void:
	StoryState.set_state("clear_me", "bye")
	StoryState.clear_state("clear_me")
	_assert("StoryState.clear_state() removes key",
		not StoryState.has_state("clear_me"))
	await _frame()


func _test_story_state_default_value() -> void:
	var val = StoryState.get_state("missing_key_xyz", "default_fallback")
	_assert("StoryState.get_state() returns default for missing key",
		val == "default_fallback")
	await _frame()


func _test_story_choice_signal() -> void:
	_last_choice_key = ""
	_last_choice_val = ""
	EventBus.story_choice_made.emit("test_state", "test_choice")
	await _frame()
	_assert("story_choice_made signal received correctly",
		_last_choice_key == "test_state" and _last_choice_val == "test_choice")


func _test_player_interaction_started_signal() -> void:
	_last_interaction_started = ""
	EventBus.player_interaction_started.emit("my_terminal")
	await _frame()
	_assert("player_interaction_started signal received",
		_last_interaction_started == "my_terminal")


func _test_player_interaction_finished_signal() -> void:
	_last_interaction_finished = ""
	EventBus.player_interaction_finished.emit("my_terminal")
	await _frame()
	_assert("player_interaction_finished signal received",
		_last_interaction_finished == "my_terminal")


func _test_choice_ui_loads() -> void:
	var scene = load("res://story/ui/interactive_choice_ui.tscn")
	_assert("interactive_choice_ui.tscn loads successfully", scene != null)
	await _frame()


func _test_choice_ui_show_hides() -> void:
	var scene = load("res://story/ui/interactive_choice_ui.tscn")
	if scene == null:
		_assert("InteractiveChoiceUI show/hide skipped (scene missing)", false)
		return
	var ui = scene.instantiate()
	add_child(ui)
	_assert("InteractiveChoiceUI starts hidden", not ui.visible)
	ui.show_choice({
		"terminal_id": "test_terminal",
		"title": "TEST",
		"node_id": "NODE: TEST",
		"authority": "VERIFIED",
		"condition": "STABLE",
		"prompt": "Test prompt.",
		"state_key": "test_show_hide",
		"options": [{"label": "OK", "value": "ok"}],
		"results": {"ok": {"main": "OK", "sub": "", "color": "success"}},
	})
	await _frame()
	_assert("InteractiveChoiceUI becomes visible after show_choice()", ui.visible)
	ui.hide_panel()
	await _frame()
	_assert("InteractiveChoiceUI hidden after hide_panel()", not ui.visible)
	ui.queue_free()
	await _frame()


func _test_choice_ui_emits_story_choice() -> void:
	_last_choice_key = ""
	_last_choice_val = ""
	var scene = load("res://story/ui/interactive_choice_ui.tscn")
	if scene == null:
		_assert("story_choice_made emission skipped (scene missing)", false)
		return
	var ui = scene.instantiate()
	add_child(ui)
	ui.show_choice({
		"terminal_id": "emit_test",
		"title": "EMIT TEST",
		"node_id": "", "authority": "V", "condition": "S",
		"prompt": "Select one.",
		"state_key": "emit_key",
		"options": [{"label": "CHOICE A", "value": "choice_a"}],
		"results": {"choice_a": {"main": "DONE", "sub": "", "color": "success"}},
	})
	await _frame()
	# Reset the processing flag so the direct call works in tests
	ui._processing = false
	ui._on_option_selected("choice_a")
	# _on_option_selected awaits 0.75s before emitting — wait long enough
	await get_tree().create_timer(1.2).timeout
	_assert("story_choice_made emitted after option selected",
		_last_choice_key == "emit_key" and _last_choice_val == "choice_a")
	ui.queue_free()
	await _frame()


func _test_choice_ui_stores_in_story_state() -> void:
	StoryState.clear_state("store_test")
	var scene = load("res://story/ui/interactive_choice_ui.tscn")
	if scene == null:
		_assert("StoryState storage skipped", false)
		return
	var ui = scene.instantiate()
	add_child(ui)
	ui.show_choice({
		"terminal_id": "store_test_terminal",
		"title": "STORE TEST",
		"node_id": "", "authority": "V", "condition": "S",
		"prompt": "Store test.",
		"state_key": "store_test",
		"options": [{"label": "STORE", "value": "stored_value"}],
		"results": {"stored_value": {"main": "STORED", "sub": "", "color": "success"}},
	})
	await _frame()
	ui._processing = false
	ui._on_option_selected("stored_value")
	# _on_option_selected awaits 0.75s before emitting — wait long enough
	await get_tree().create_timer(1.2).timeout
	_assert("choice is stored in StoryState after selection",
		StoryState.get_state("store_test") == "stored_value")
	ui.queue_free()
	await _frame()


func _test_choice_ui_locks_player() -> void:
	_cinematic_locked = false
	var scene = load("res://story/ui/interactive_choice_ui.tscn")
	if scene == null:
		_assert("lock test skipped", false)
		return
	var ui = scene.instantiate()
	add_child(ui)
	ui.show_choice({
		"terminal_id": "lock_test",
		"title": "LOCK TEST",
		"node_id": "", "authority": "V", "condition": "S",
		"prompt": "Lock test.",
		"state_key": "lock_test_key",
		"options": [{"label": "OK", "value": "ok"}],
		"results": {"ok": {"main": "OK", "sub": "", "color": "success"}},
	})
	await _frame()
	_assert("cinematic_mode_toggled(true) fired when UI shown",
		_cinematic_locked == true)
	ui.queue_free()
	await _frame()


func _test_choice_ui_unlocks_after_selection() -> void:
	_cinematic_locked = true
	var scene = load("res://story/ui/interactive_choice_ui.tscn")
	if scene == null:
		_assert("unlock test skipped", false)
		return
	var ui = scene.instantiate()
	add_child(ui)
	ui.show_choice({
		"terminal_id": "unlock_test",
		"title": "UNLOCK TEST",
		"node_id": "", "authority": "V", "condition": "S",
		"prompt": "Unlock test.",
		"state_key": "unlock_test_key",
		"options": [{"label": "OK", "value": "ok"}],
		"results": {"ok": {"main": "OK", "sub": "", "color": "success"}},
	})
	await _frame()
	ui._on_option_selected("ok")
	await get_tree().create_timer(3.0).timeout
	_assert("cinematic_mode_toggled(false) fired after interaction completes",
		_cinematic_locked == false)
	if is_instance_valid(ui):
		ui.queue_free()
	await _frame()


func _test_permission_granted_stored() -> void:
	StoryState.set_state("permission_choice", "granted")
	_assert("permission_choice=granted stored and retrievable",
		StoryState.get_state("permission_choice") == "granted")
	await _frame()


func _test_permission_denied_stored() -> void:
	StoryState.set_state("permission_choice", "denied")
	_assert("permission_choice=denied stored and retrievable",
		StoryState.get_state("permission_choice") == "denied")
	await _frame()


func _test_diagnostic_optimal_stored() -> void:
	StoryState.set_state("diagnostic_answer", "AUTONOMOUS AUTHORITY")
	_assert("diagnostic_answer=AUTONOMOUS AUTHORITY stored correctly",
		StoryState.get_state("diagnostic_answer") == "AUTONOMOUS AUTHORITY")
	await _frame()


func _test_diagnostic_alternate_stored() -> void:
	StoryState.set_state("diagnostic_answer", "POWER GRID")
	_assert("diagnostic_answer=POWER GRID stored for alternate route",
		StoryState.get_state("diagnostic_answer") == "POWER GRID")
	await _frame()


func _test_main_scene_exists() -> void:
	_assert("main.tscn exists", ResourceLoader.exists("res://main.tscn"))
	await _frame()


func _test_interactive_choice_ui_in_main() -> void:
	_assert("interactive_choice_ui.tscn exists",
		ResourceLoader.exists("res://story/ui/interactive_choice_ui.tscn"))
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
		print("  PHASE 16 RESULTS: %d PASSED   0 FAILED" % _tests_passed)
	else:
		print("  PHASE 16 RESULTS: %d PASSED   %d FAILED" % [_tests_passed, _tests_failed])
		for msg in _fail_messages:
			print("    FAILED: " + msg)
	print("=".repeat(52) + "\n")
