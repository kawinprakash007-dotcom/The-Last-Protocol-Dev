extends Node

@onready var dialogue_ui: DialogueUI = $DialogueUI

var _pass_count: int = 0
var _fail_count: int = 0
var _finished_count: int = 0


func _ready() -> void:
	await get_tree().process_frame
	EventBus.dialogue_finished.connect(func(_sequence_id: String): _finished_count += 1)
	await _run_tests()


func _run_tests() -> void:
	print("\n====================================================")
	print("  THE LAST PROTOCOL - DIALOGUE UI VALIDATION")
	print("====================================================\n")

	_check(dialogue_ui != null, "01 DialogueUI loads")
	_check(dialogue_ui is CanvasLayer, "02 DialogueUI is CanvasLayer based")

	dialogue_ui.set_presentation_mode(DialogueUI.PresentationMode.CINEMATIC)
	_check(dialogue_ui.presentation_mode == DialogueUI.PresentationMode.CINEMATIC, "03 cinematic mode can be selected")
	dialogue_ui.set_presentation_mode(DialogueUI.PresentationMode.GAMEPLAY)
	_check(dialogue_ui.presentation_mode == DialogueUI.PresentationMode.GAMEPLAY, "04 gameplay mode can be selected")

	var sequence := _make_demo_sequence()
	DialogueManager.start_sequence(sequence)
	await get_tree().process_frame

	_check(DialogueManager.is_active, "05 DialogueManager starts sequence")
	_check(dialogue_ui.get_current_speaker_id() == "GENESIS", "06 GENESIS style applied")
	_check(dialogue_ui.get_current_style_effect() == "diagnostic", "07 GENESIS diagnostic presentation active")
	_check(dialogue_ui.is_typing(), "08 text begins typing")
	_check(not dialogue_ui.is_line_complete(), "09 continue indicator hidden while typing")

	dialogue_ui.request_continue()
	await get_tree().process_frame
	_check(dialogue_ui.is_line_complete(), "10 continue instantly completes current line")
	_check(dialogue_ui.get_visible_dialogue_text() == "Identity verification complete.", "11 typewriter completes without losing characters")

	dialogue_ui.request_continue()
	await get_tree().process_frame
	_check(dialogue_ui.get_current_speaker_id() == "VANCE", "12 second continue advances to VANCE")
	_check(dialogue_ui.get_current_style_effect() == "human", "13 VANCE presentation active")
	dialogue_ui.request_continue()
	await get_tree().process_frame
	dialogue_ui.request_continue()
	await get_tree().process_frame
	_check(dialogue_ui.get_current_speaker_id() == "RADIO", "14 continue advances to RADIO")
	_check(dialogue_ui.get_current_style_effect() == "radio", "15 RADIO transmission presentation active")
	dialogue_ui.request_continue()
	await get_tree().process_frame
	dialogue_ui.request_continue()
	await get_tree().process_frame
	_check(dialogue_ui.get_current_speaker_id() == "GENESIS", "16 sequence advances back to GENESIS")

	dialogue_ui.request_continue()
	await get_tree().process_frame
	dialogue_ui.request_continue()
	await get_tree().process_frame
	_check(not DialogueManager.is_active, "17 dialogue completion emits and manager resets")
	_check(_finished_count == 1, "18 dialogue completion emitted once")

	var warden_sequence := _make_warden_sequence()
	DialogueManager.start_sequence(warden_sequence)
	await get_tree().process_frame
	_check(dialogue_ui.get_current_speaker_id() == "WARDEN", "19 WARDEN presentation active")
	_check(dialogue_ui.get_current_style_effect() == "corruption", "20 WARDEN corruption treatment active")
	dialogue_ui.request_skip()
	await get_tree().process_frame
	_check(dialogue_ui.is_line_complete(), "21 deliberate skip first completes typing")
	dialogue_ui.request_skip()
	await get_tree().process_frame
	_check(not DialogueManager.is_active, "22 deliberate skip can end active sequence")

	_check(ResourceLoader.exists("res://story/ui/objective_hud.tscn"), "23 ObjectiveHUD remains separate")
	_check(dialogue_ui.frame.anchor_left > 0.0 and dialogue_ui.frame.anchor_right < 1.0, "24 UI uses responsive anchored frame")

	print("\n====================================================")
	print("  RESULTS: %d PASSED   %d FAILED" % [_pass_count, _fail_count])
	print("====================================================\n")
	get_tree().quit(_fail_count)


func _make_demo_sequence() -> DialogueSequence:
	var sequence := DialogueSequence.new()
	sequence.sequence_id = "dev_dialogue_ui_demo"
	sequence.lines = [
		_make_line("GENESIS", "Identity verification complete."),
		_make_line("VANCE", "...Where am I?"),
		_make_line("RADIO", "Vance. If you can hear me, do not answer the system."),
		_make_line("GENESIS", "Unauthorized communication detected."),
	]
	return sequence


func _make_warden_sequence() -> DialogueSequence:
	var sequence := DialogueSequence.new()
	sequence.sequence_id = "dev_dialogue_ui_warden_check"
	sequence.lines = [_make_line("WARDEN", "Compliance is no longer optional.")]
	return sequence


func _make_line(speaker_id: String, text: String) -> DialogueLine:
	var line := DialogueLine.new()
	line.speaker_id = speaker_id
	line.text = text
	return line


func _check(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		print("  [PASS] %s" % test_name)
	else:
		_fail_count += 1
		print("  [FAIL] %s" % test_name)
