## DialogueManager — Controls playback of DialogueSequence resources.
##
## AUTOLOAD: Registered as "DialogueManager" in project.godot.
##
## Usage:
##   DialogueManager.start_sequence(my_sequence)
##   DialogueManager.advance()         # called by Continue button
##   DialogueManager.skip_sequence()   # called by Skip button or ESC
##
## The DialogueUI (dialogue_ui.gd) should connect to EventBus.dialogue_line_shown
## to receive new lines and update the display.
##
## Team Ownership: Story Team
##
extends Node


# ── STATE ──────────────────────────────────────────────────────────────────────
var _current_sequence: DialogueSequence = null
var _current_line_index: int = -1
var _is_active: bool = false
var _auto_advance_timer: SceneTreeTimer = null


# ── PUBLIC API ─────────────────────────────────────────────────────────────────

## Returns true if a dialogue sequence is currently playing.
var is_active: bool:
	get: return _is_active


## Start playing a DialogueSequence from the beginning.
## Safe to call with null — emits a warning and does nothing.
func start_sequence(sequence: DialogueSequence) -> void:
	if sequence == null:
		push_warning("DialogueManager: start_sequence() called with null sequence.")
		return
	if sequence.lines.is_empty():
		push_warning(
			"DialogueManager: Sequence '%s' has no lines. Nothing to play."
			% sequence.sequence_id
		)
		return

	_reset_state()
	_current_sequence = sequence
	_is_active = true
	EventBus.dialogue_started.emit(sequence.sequence_id)
	_show_line(0)


## Advance to the next dialogue line.
## Called by the Continue button in DialogueUI.
func advance() -> void:
	if not _is_active:
		return
	_cancel_auto_advance()
	_advance_to_next()


## Skip the entire current sequence immediately.
## Emits sequence_skipped and dialogue_finished.
func skip_sequence() -> void:
	if not _is_active:
		return
	var seq_id := _current_sequence.sequence_id if _current_sequence else ""
	_cancel_auto_advance()
	_reset_state()
	EventBus.sequence_skipped.emit(seq_id)
	EventBus.dialogue_finished.emit(seq_id)


## Force-stop and reset without emitting skip signals.
## Use during scene transitions to cleanly halt dialogue.
func force_reset() -> void:
	_cancel_auto_advance()
	_reset_state()


# ── INTERNAL ───────────────────────────────────────────────────────────────────

func _show_line(index: int) -> void:
	if _current_sequence == null:
		return
	if index < 0 or index >= _current_sequence.lines.size():
		push_warning(
			"DialogueManager: Line index %d is out of range for sequence '%s'."
			% [index, _current_sequence.sequence_id]
		)
		_finish_sequence()
		return

	_current_line_index = index
	var line: DialogueLine = _current_sequence.lines[index]

	if line == null:
		push_warning(
			"DialogueManager: Null DialogueLine at index %d in sequence '%s'."
			% [index, _current_sequence.sequence_id]
		)
		_advance_to_next()
		return

	# Play voice audio if key is assigned
	if not line.voice_key.is_empty():
		StoryAudioManager.play_voice(line.voice_key)

	# Notify UI
	EventBus.dialogue_line_shown.emit(line)

	# Emit story event if this line has one
	if not line.on_complete_event.is_empty():
		EventBus.story_event_triggered.emit(line.on_complete_event)

	# Handle auto-advance
	if line.auto_advance and line.duration > 0.0:
		_auto_advance_timer = get_tree().create_timer(line.duration)
		_auto_advance_timer.timeout.connect(_on_auto_advance_timeout, CONNECT_ONE_SHOT)


func _advance_to_next() -> void:
	if _current_sequence == null:
		return
	var next_index := _current_line_index + 1
	if next_index >= _current_sequence.lines.size():
		_finish_sequence()
	else:
		_show_line(next_index)


func _finish_sequence() -> void:
	if _current_sequence == null:
		_is_active = false
		return
	var seq_id := _current_sequence.sequence_id
	var end_event := _current_sequence.on_end_event
	_reset_state()
	EventBus.dialogue_finished.emit(seq_id)
	if not end_event.is_empty():
		EventBus.story_event_triggered.emit(end_event)


func _cancel_auto_advance() -> void:
	if _auto_advance_timer != null and is_instance_valid(_auto_advance_timer):
		# SceneTreeTimer cannot be cancelled directly; we disconnect the signal.
		if _auto_advance_timer.timeout.is_connected(_on_auto_advance_timeout):
			_auto_advance_timer.timeout.disconnect(_on_auto_advance_timeout)
	_auto_advance_timer = null


func _reset_state() -> void:
	_current_sequence = null
	_current_line_index = -1
	_is_active = false


func _on_auto_advance_timeout() -> void:
	_advance_to_next()
