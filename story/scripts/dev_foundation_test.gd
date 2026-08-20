## =====================================================================
## DEVELOPMENT TEST ONLY — DO NOT INTEGRATE INTO THE FINAL GAME
## =====================================================================
##
## Attach this script to any Node in a test scene, or temporarily attach
## it to the StoryIntro root to run validation on startup.
##
## Remove or delete this file before final submission.
## File path: res://story/scripts/dev_foundation_test.gd
##
## Run by pressing F5 with story_intro.tscn as the main scene.
## Check the Output panel for PASS / FAIL / WARNING lines.
##
## Tests covered:
##   01 — EventBus autoload present
##   02 — StoryManager autoload present
##   03 — CinematicManager autoload present
##   04 — DialogueManager autoload present
##   05 — StoryAudioManager autoload present
##   06 — DialogueLine can be instantiated
##   07 — DialogueSequence can be instantiated and contain a DialogueLine
##   08 — CinematicShot can be instantiated
##   09 — CinematicSequence can be instantiated and contain a CinematicShot
##   10 — EventBus signals emit without error
##   11 — DialogueManager resets safely without sequence
##   12 — CinematicManager resets safely without sequence
##   13 — StoryManager handles unregistered event without crash
##   14 — StoryAudioManager handles missing key without crash
##   15 — story_intro.tscn is accessible (not destroyed by this test)
##
extends Node

var _pass_count: int = 0
var _fail_count: int = 0


func _ready() -> void:
	# Slight delay so all autoloads finish _ready() before we test them
	await get_tree().create_timer(0.1).timeout
	_run_all_tests()


func _run_all_tests() -> void:
	print("\n====================================================")
	print("  THE LAST PROTOCOL — FOUNDATION VALIDATION")
	print("====================================================\n")

	_test_01_event_bus_loaded()
	_test_02_story_manager_loaded()
	_test_03_cinematic_manager_loaded()
	_test_04_dialogue_manager_loaded()
	_test_05_audio_manager_loaded()
	_test_06_dialogue_line_resource()
	_test_07_dialogue_sequence_resource()
	_test_08_cinematic_shot_resource()
	_test_09_cinematic_sequence_resource()
	await _test_10_event_bus_signals()
	_test_11_dialogue_manager_safe_reset()
	_test_12_cinematic_manager_safe_reset()
	await _test_13_story_manager_unregistered_event()
	_test_14_audio_manager_missing_key()
	_test_15_story_intro_accessible()

	print("\n====================================================")
	print("  RESULTS: %d PASSED   %d FAILED" % [_pass_count, _fail_count])
	print("====================================================\n")
	get_tree().quit(_fail_count)


# ── HELPERS ────────────────────────────────────────────────────────────────────

func _pass(test_name: String) -> void:
	_pass_count += 1
	print("  [PASS] %s" % test_name)


func _fail(test_name: String, reason: String) -> void:
	_fail_count += 1
	print("  [FAIL] %s — %s" % [test_name, reason])


# ── TESTS ──────────────────────────────────────────────────────────────────────

func _test_01_event_bus_loaded() -> void:
	if Engine.has_singleton("EventBus") or is_instance_valid(get_node_or_null("/root/EventBus")):
		_pass("01 EventBus autoload present")
	else:
		_fail("01 EventBus autoload present", "Not found at /root/EventBus")


func _test_02_story_manager_loaded() -> void:
	if is_instance_valid(get_node_or_null("/root/StoryManager")):
		_pass("02 StoryManager autoload present")
	else:
		_fail("02 StoryManager autoload present", "Not found at /root/StoryManager")


func _test_03_cinematic_manager_loaded() -> void:
	if is_instance_valid(get_node_or_null("/root/CinematicManager")):
		_pass("03 CinematicManager autoload present")
	else:
		_fail("03 CinematicManager autoload present", "Not found at /root/CinematicManager")


func _test_04_dialogue_manager_loaded() -> void:
	if is_instance_valid(get_node_or_null("/root/DialogueManager")):
		_pass("04 DialogueManager autoload present")
	else:
		_fail("04 DialogueManager autoload present", "Not found at /root/DialogueManager")


func _test_05_audio_manager_loaded() -> void:
	if is_instance_valid(get_node_or_null("/root/StoryAudioManager")):
		_pass("05 StoryAudioManager autoload present")
	else:
		_fail("05 StoryAudioManager autoload present", "Not found at /root/StoryAudioManager")


func _test_06_dialogue_line_resource() -> void:
	var line := DialogueLine.new()
	line.speaker_id = "GENESIS"
	line.text = "Test line."
	line.auto_advance = true
	line.duration = 2.0
	if line.speaker_id == "GENESIS" and line.text == "Test line." and line.duration == 2.0:
		_pass("06 DialogueLine resource instantiation")
	else:
		_fail("06 DialogueLine resource instantiation", "Property values did not round-trip correctly")


func _test_07_dialogue_sequence_resource() -> void:
	var line := DialogueLine.new()
	line.speaker_id = "VANCE"
	line.text = "Can you hear me?"
	var seq := DialogueSequence.new()
	seq.sequence_id = "test_seq"
	seq.lines = [line]
	if seq.sequence_id == "test_seq" and seq.lines.size() == 1 and seq.lines[0].text == "Can you hear me?":
		_pass("07 DialogueSequence contains DialogueLine")
	else:
		_fail("07 DialogueSequence contains DialogueLine", "Lines array did not contain expected line")


func _test_08_cinematic_shot_resource() -> void:
	var shot := CinematicShot.new()
	shot.shot_id = "shot_test"
	shot.duration = 3.0
	shot.camera_action = "STATIC"
	shot.lock_player = true
	if shot.shot_id == "shot_test" and shot.duration == 3.0 and shot.lock_player == true:
		_pass("08 CinematicShot resource instantiation")
	else:
		_fail("08 CinematicShot resource instantiation", "Property values did not round-trip correctly")


func _test_09_cinematic_sequence_resource() -> void:
	var shot := CinematicShot.new()
	shot.shot_id = "test_shot"
	var cseq := CinematicSequence.new()
	cseq.sequence_id = "test_cinematic"
	cseq.shots = [shot]
	if cseq.sequence_id == "test_cinematic" and cseq.shots.size() == 1:
		_pass("09 CinematicSequence contains CinematicShot")
	else:
		_fail("09 CinematicSequence contains CinematicShot", "Shots array did not contain expected shot")


func _test_10_event_bus_signals() -> void:
	var received := {"value": false}
	var _cb := func(_id: String): received["value"] = true

	EventBus.cinematic_started.connect(_cb, CONNECT_ONE_SHOT)
	EventBus.cinematic_started.emit("test_cinematic_signal")

	await get_tree().process_frame
	if received["value"]:
		_pass("10 EventBus signal emit / receive")
	else:
		_fail("10 EventBus signal emit / receive", "Signal was not received")


func _test_11_dialogue_manager_safe_reset() -> void:
	# Call force_reset with no sequence active — must not crash
	DialogueManager.force_reset()
	DialogueManager.advance()
	DialogueManager.skip_sequence()
	_pass("11 DialogueManager safe reset with no active sequence")


func _test_12_cinematic_manager_safe_reset() -> void:
	# Call stop with no sequence active — must not crash
	CinematicManager.stop()
	_pass("12 CinematicManager safe stop with no active sequence")


func _test_13_story_manager_unregistered_event() -> void:
	# Trigger an event that has no registered sequence — must not crash
	StoryManager.trigger_event("__dev_test_unregistered_event__")
	await get_tree().process_frame
	_pass("13 StoryManager handles unregistered event without crash")


func _test_14_audio_manager_missing_key() -> void:
	# Call all audio APIs with a key that doesn't exist — must not crash
	StoryAudioManager.play_music("__nonexistent__")
	StoryAudioManager.play_ambience("__nonexistent__")
	StoryAudioManager.play_sfx("__nonexistent__")
	StoryAudioManager.play_voice("__nonexistent__")
	StoryAudioManager.stop_music(0.0)
	StoryAudioManager.stop_ambience(0.0)
	_pass("14 StoryAudioManager all methods safe with missing keys")


func _test_15_story_intro_accessible() -> void:
	# Verify story_intro.tscn resource exists and can be loaded
	if ResourceLoader.exists("res://story/ui/story_intro.tscn"):
		_pass("15 story_intro.tscn is accessible (not broken by foundation)")
	else:
		_fail("15 story_intro.tscn is accessible", "Resource path does not exist")
