extends Control

enum ScreenState {
	WAITING_FOR_INPUT,
	INITIALIZING,
	VERIFYING,
	COMPLETED
}

var current_state: ScreenState = ScreenState.WAITING_FOR_INPUT

@onready var sub_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatusArea/SubLabel
@onready var init_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/ButtonBox/InitializeButton

func _ready() -> void:
	init_btn.pressed.connect(_on_initialize_pressed)
	init_btn.grab_focus()
	
	# Initial status text
	sub_label.text = "AWAITING CREATOR CONFIRMATION"
	sub_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.1))

func initialize_interactive() -> void:
	modulate.a = 0.0
	var t = create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.4)
	init_btn.grab_focus()

func _on_initialize_pressed() -> void:
	if current_state != ScreenState.WAITING_FOR_INPUT:
		return
		
	current_state = ScreenState.INITIALIZING
	init_btn.disabled = true
	
	# Play low confirmation pulse sound
	StoryAudioManager.play_sfx("ui_dialogue_confirm")
	
	var steps = [
		{"text": "INITIALIZING...", "color": Color(1.0, 0.35, 0.1)},
		{"text": "VERIFYING CREATOR AUTHORITY", "color": Color(0.0, 0.67, 1.0)},
		{"text": "CREATOR VERIFIED", "color": Color(0.2, 1.0, 0.55)},
		{"text": "LOADING LAST PROTOCOL", "color": Color(0.0, 0.67, 1.0)},
		{"text": "LAST PROTOCOL ARMED", "color": Color(0.2, 1.0, 0.55)}
	]
	
	for step in steps:
		if not is_inside_tree():
			return
		sub_label.text = step["text"]
		sub_label.add_theme_color_override("font_color", step["color"])
		
		# Play beep transition sound
		StoryAudioManager.play_sfx("ui_dialogue_speaker_transition")
		
		await get_tree().create_timer(0.5).timeout
		
	if not is_inside_tree():
		return
		
	current_state = ScreenState.COMPLETED
	
	# Emit event to resume sequence and handoff to gameplay
	EventBus.story_event_triggered.emit("last_protocol_initialized")
	
	# Smooth fade out overlay
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await fade_tween.finished
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	# Ignore escape so it cannot bypass or close
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
