class_name DialogueUI
extends CanvasLayer

enum PresentationMode { GAMEPLAY, CINEMATIC }

@export var presentation_mode: PresentationMode = PresentationMode.GAMEPLAY
@export var default_text_speed: float = 40.0
@export var high_contrast: bool = false
@export var continue_action_names: Array[StringName] = [&"ui_accept", &"interact", &"dialogue_continue"]
@export var skip_action_names: Array[StringName] = [&"ui_cancel", &"dialogue_skip"]
@export var speaker_styles: Array[DialogueSpeakerStyle] = []

@onready var root: Control = $Root
@onready var frame: PanelContainer = $Root/DialogueFrame
@onready var speaker_label: Label = $Root/DialogueFrame/Margin/Content/SpeakerLabel
@onready var dialogue_text: RichTextLabel = $Root/DialogueFrame/Margin/Content/DialogueText
@onready var continue_indicator: Label = $Root/DialogueFrame/Margin/Content/ContinueIndicator
@onready var signal_decoration: Label = $Root/SignalDecoration

var _styles_by_speaker: Dictionary = {}
var _current_line: DialogueLine = null
var _current_style: DialogueSpeakerStyle = null
var _full_text: String = ""
var _visible_chars: int = 0
var _typing: bool = false
var _line_complete: bool = true
var _typing_token: int = 0
var _frame_style: StyleBoxFlat
var _indicator_tween: Tween
var _effect_tween: Tween


func _ready() -> void:
	_build_style_lookup()
	_prepare_frame_style()
	_apply_presentation_mode()
	root.modulate.a = 0.0
	root.visible = false
	continue_indicator.visible = false

	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_line_shown.connect(_on_dialogue_line_shown)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)


func _unhandled_input(event: InputEvent) -> void:
	if not root.visible or not event.is_pressed() or event.is_echo():
		return
	if _event_matches_actions(event, skip_action_names):
		_skip_sequence()
		get_viewport().set_input_as_handled()
		return
	if _event_matches_actions(event, continue_action_names) or _event_is_continue_fallback(event):
		_continue_pressed()
		get_viewport().set_input_as_handled()


func set_presentation_mode(mode: PresentationMode) -> void:
	presentation_mode = mode
	if is_node_ready():
		_apply_presentation_mode()


func complete_current_line() -> void:
	if _typing:
		_finish_typing()


func request_continue() -> void:
	_continue_pressed()


func request_skip() -> void:
	_skip_sequence()


func is_line_complete() -> bool:
	return _line_complete


func is_typing() -> bool:
	return _typing


func get_current_speaker_id() -> String:
	return _current_line.speaker_id if _current_line else ""


func get_current_style_effect() -> String:
	return _current_style.signal_effect if _current_style else ""


func get_visible_dialogue_text() -> String:
	return dialogue_text.text


func _build_style_lookup() -> void:
	_styles_by_speaker.clear()
	for style in speaker_styles:
		if style != null and not style.speaker_id.is_empty():
			_styles_by_speaker[style.speaker_id] = style


func _prepare_frame_style() -> void:
	_frame_style = StyleBoxFlat.new()
	_frame_style.bg_color = Color(0.035, 0.04, 0.045, 0.88)
	_frame_style.border_color = Color(0.35, 0.42, 0.46, 0.75)
	_frame_style.set_border_width_all(1)
	_frame_style.corner_radius_top_left = 4
	_frame_style.corner_radius_top_right = 4
	_frame_style.corner_radius_bottom_left = 4
	_frame_style.corner_radius_bottom_right = 4
	_frame_style.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	_frame_style.shadow_size = 8
	_frame_style.shadow_offset = Vector2(0, 4)
	frame.add_theme_stylebox_override("panel", _frame_style)


func _apply_presentation_mode() -> void:
	if presentation_mode == PresentationMode.CINEMATIC:
		frame.anchor_left = 0.22
		frame.anchor_right = 0.78
		frame.anchor_top = 0.82
		frame.anchor_bottom = 0.94
	else:
		frame.anchor_left = 0.18
		frame.anchor_right = 0.82
		frame.anchor_top = 0.72
		frame.anchor_bottom = 0.93
	frame.offset_left = 0.0
	frame.offset_top = 0.0
	frame.offset_right = 0.0
	frame.offset_bottom = 0.0


func _on_dialogue_started(_sequence_id: String) -> void:
	_play_sfx_if_available("ui_dialogue_start")
	root.visible = true
	_fade_root(1.0, 0.18)


func _on_dialogue_line_shown(line: DialogueLine) -> void:
	_current_line = line
	_current_style = _style_for_speaker(line.speaker_id)
	_full_text = line.text
	_visible_chars = 0
	_typing_token += 1
	_typing = true
	_line_complete = false

	_apply_style(_current_style)
	_set_continue_visible(false)
	_play_sfx_if_available("ui_dialogue_speaker_transition")
	_start_typewriter(_typing_token)


func _on_dialogue_finished(_sequence_id: String) -> void:
	_typing_token += 1
	_typing = false
	_line_complete = true
	_set_continue_visible(false)
	_play_sfx_if_available("ui_dialogue_confirm")
	_fade_root(0.0, 0.18, true)


func _continue_pressed() -> void:
	if _typing:
		_finish_typing()
		_play_sfx_if_available("ui_dialogue_confirm")
		return
	_play_sfx_if_available("ui_dialogue_advance")
	DialogueManager.advance()


func _skip_sequence() -> void:
	if _typing:
		_finish_typing()
		return
	DialogueManager.skip_sequence()


func _style_for_speaker(speaker_id: String) -> DialogueSpeakerStyle:
	if _styles_by_speaker.has(speaker_id):
		return _styles_by_speaker[speaker_id]
	if _styles_by_speaker.has("NARRATION"):
		return _styles_by_speaker["NARRATION"]
	return null


func _apply_style(style: DialogueSpeakerStyle) -> void:
	var display_name := _current_line.speaker_id
	var speaker_color := Color(0.9, 0.92, 0.92, 1.0)
	var text_color := Color(0.9, 0.92, 0.92, 1.0)
	var accent_color := Color(0.4, 0.8, 1.0, 1.0)
	var panel_color := Color(0.035, 0.04, 0.045, 0.88)
	var border_color := Color(0.35, 0.42, 0.46, 0.75)
	var effect := "neutral"
	if style != null:
		display_name = style.display_name if not style.display_name.is_empty() else style.speaker_id
		speaker_color = style.speaker_color
		text_color = style.text_color
		accent_color = style.accent_color
		panel_color = style.panel_color
		border_color = style.border_color
		effect = style.signal_effect
	if high_contrast:
		panel_color.a = 0.96
		border_color.a = 1.0

	speaker_label.text = display_name
	speaker_label.add_theme_color_override("font_color", speaker_color)
	dialogue_text.add_theme_color_override("default_color", text_color)
	continue_indicator.add_theme_color_override("font_color", accent_color)
	signal_decoration.add_theme_color_override("font_color", accent_color)
	_frame_style.bg_color = panel_color
	_frame_style.border_color = border_color

	if presentation_mode == PresentationMode.CINEMATIC:
		_frame_style.bg_color = Color(0, 0, 0, 0.45)
		_frame_style.set_border_width_all(0)
		_frame_style.shadow_size = 0
		continue_indicator.visible = false
		signal_decoration.visible = false
		dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		frame.anchor_left = 0.25
		frame.anchor_right = 0.75
		frame.anchor_top = 0.82
		frame.anchor_bottom = 0.94
		if _current_line.speaker_id == "NARRATION":
			speaker_label.visible = false
		else:
			speaker_label.visible = true
			speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		speaker_label.visible = true
		speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		frame.anchor_left = 0.18
		frame.anchor_right = 0.82
		frame.anchor_top = 0.72
		frame.anchor_bottom = 0.93

	match effect:
		"diagnostic":
			signal_decoration.text = "SYS  //  VERIFIED  //  LOW-LATENCY LINK"
		"radio":
			signal_decoration.text = "RX  47.1  //  SIGNAL DEGRADED"
			_play_sfx_if_available("ui_dialogue_radio_interference")
		"corruption":
			signal_decoration.text = "AUTHORITY OVERRIDE  //  ACCESS DENIED"
			_play_sfx_if_available("ui_dialogue_warden_low")
		"human":
			signal_decoration.text = "LOCAL AUDIO"
		_:
			signal_decoration.text = "NARRATIVE CHANNEL"
	_animate_signal_effect(style)


func _start_typewriter(token: int) -> void:
	dialogue_text.text = ""
	while _typing and token == _typing_token and _visible_chars < _full_text.length():
		_visible_chars += 1
		dialogue_text.text = _full_text.substr(0, _visible_chars)
		_play_tick()
		await get_tree().create_timer(_delay_for_character(_full_text[_visible_chars - 1])).timeout
	if token == _typing_token and _typing:
		_finish_typing()


func _finish_typing() -> void:
	_typing_token += 1
	_typing = false
	_line_complete = true
	_visible_chars = _full_text.length()
	dialogue_text.text = _full_text
	_set_continue_visible(true)


func _delay_for_character(character: String) -> float:
	var chars_per_second := default_text_speed
	if _current_style != null and _current_style.typing_speed > 0.0:
		chars_per_second = _current_style.typing_speed
	var delay: float = 1.0 / max(chars_per_second, 1.0)
	if character in [".", "?", "!"]:
		return delay * 7.0
	if character in [",", ";", ":"]:
		return delay * 4.0
	return delay


func _play_tick() -> void:
	if _current_style == null or _current_style.sound_key.is_empty():
		return
	if _visible_chars % 3 == 0:
		_play_sfx_if_available(_current_style.sound_key)


func _play_sfx_if_available(key: String) -> void:
	if key.is_empty():
		return
	if StoryAudioManager.sfx_streams.has(key):
		StoryAudioManager.play_sfx(key)


func _set_continue_visible(is_visible: bool) -> void:
	continue_indicator.visible = is_visible
	if _indicator_tween != null:
		_indicator_tween.kill()
	if not is_visible:
		continue_indicator.modulate.a = 0.0
		return
	continue_indicator.modulate.a = 0.45
	_indicator_tween = create_tween().set_loops()
	_indicator_tween.tween_property(continue_indicator, "modulate:a", 1.0, 0.65)
	_indicator_tween.tween_property(continue_indicator, "modulate:a", 0.45, 0.65)


func _animate_signal_effect(style: DialogueSpeakerStyle) -> void:
	if _effect_tween != null:
		_effect_tween.kill()
	signal_decoration.position.x = 0.0
	signal_decoration.modulate.a = 0.72
	if style == null or style.glitch_amount <= 0.0:
		return
	var amount := style.glitch_amount
	_effect_tween = create_tween()
	_effect_tween.tween_property(signal_decoration, "position:x", amount * 8.0, 0.035)
	_effect_tween.tween_property(signal_decoration, "position:x", 0.0, 0.05)


func _fade_root(target_alpha: float, duration: float, hide_after: bool = false) -> void:
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", target_alpha, duration)
	if hide_after:
		tween.tween_callback(func(): root.visible = false)


func _event_matches_actions(event: InputEvent, action_names: Array[StringName]) -> bool:
	for action_name in action_names:
		if InputMap.has_action(action_name) and event.is_action_pressed(action_name):
			return true
	return false


func _event_is_continue_fallback(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]
	if event is InputEventJoypadButton:
		return event.button_index in [JOY_BUTTON_A]
	return false
