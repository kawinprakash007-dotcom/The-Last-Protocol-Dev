extends Control

enum AuthState {
	WAITING_FOR_INPUT,
	DENIED,
	VERIFYING,
	AUTHORIZED,
	CANCELLED
}

var current_state: AuthState = AuthState.WAITING_FOR_INPUT

@onready var main_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var sub_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatusArea/SubLabel
@onready var deny_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/ButtonBox/DenyButton
@onready var authorize_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/ButtonBox/AuthorizeButton

func _ready() -> void:
	# Hide / reset initial state
	deny_btn.pressed.connect(_on_deny_pressed)
	authorize_btn.pressed.connect(_on_authorize_pressed)
	
	# Default focus
	authorize_btn.grab_focus()
	
	# Setup initial text
	sub_label.text = "AWAITING CREATOR AUTHORIZATION"
	sub_label.add_theme_color_override("font_color", Color(0.0, 0.67, 1.0))

func initialize_interactive() -> void:
	modulate.a = 0.0
	var t = create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.4)
	authorize_btn.grab_focus()

func _on_deny_pressed() -> void:
	if current_state != AuthState.WAITING_FOR_INPUT:
		return
		
	current_state = AuthState.DENIED
	deny_btn.disabled = true
	authorize_btn.disabled = true
	
	# Restrained rejection tone
	StoryAudioManager.play_sfx("ui_dialogue_radio_interference")
	
	# Play rejection animation sequence
	sub_label.text = "AUTHORIZATION DECLINED\n\nAUTONOMOUS AUTHORITY REQUIRED\nFOR SYSTEM DEPLOYMENT\n\nAWAITING CREATOR AUTHORIZATION"
	sub_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.1))
	
	var tween = create_tween()
	# Pulse text color red
	tween.tween_property(sub_label, "modulate:a", 0.4, 0.3)
	tween.tween_property(sub_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	
	await tween.finished
	
	# Restore state if still denied
	if current_state == AuthState.DENIED:
		current_state = AuthState.WAITING_FOR_INPUT
		deny_btn.disabled = false
		authorize_btn.disabled = false
		sub_label.text = "AWAITING CREATOR AUTHORIZATION"
		sub_label.add_theme_color_override("font_color", Color(0.0, 0.67, 1.0))
		authorize_btn.grab_focus()

func _on_authorize_pressed() -> void:
	if current_state != AuthState.WAITING_FOR_INPUT:
		return
		
	current_state = AuthState.VERIFYING
	deny_btn.disabled = true
	authorize_btn.disabled = true
	
	# low-frequency system pulse
	StoryAudioManager.play_sfx("ui_dialogue_confirm")
	
	var steps = [
		{"text": "CREATOR IDENTITY VERIFIED", "color": Color(0.0, 0.67, 1.0)},
		{"text": "AUTHORITY TRANSFER REQUESTED", "color": Color(0.0, 0.67, 1.0)},
		{"text": "VERIFYING CREATOR SIGNATURE", "color": Color(0.0, 0.67, 1.0)},
		{"text": "SIGNATURE ACCEPTED", "color": Color(0.2, 1.0, 0.55)},
		{"text": "AUTONOMOUS AUTHORITY TRANSFERRING...", "color": Color(0.0, 0.67, 1.0)},
		{"text": "GLOBAL NETWORK CONNECTED", "color": Color(0.2, 1.0, 0.55)},
		{"text": "AUTONOMOUS AUTHORITY ONLINE", "color": Color(0.2, 1.0, 0.55)}
	]
	
	for step in steps:
		# Double check if scene changed or got cancelled during verification
		if not is_inside_tree() or current_state == AuthState.CANCELLED:
			return
		sub_label.text = step["text"]
		sub_label.add_theme_color_override("font_color", step["color"])
		
		# verification tone
		StoryAudioManager.play_sfx("ui_dialogue_speaker_transition")
		
		# Short delay per step
		await get_tree().create_timer(0.4).timeout
		
	if not is_inside_tree() or current_state == AuthState.CANCELLED:
		return
		
	current_state = AuthState.AUTHORIZED
	
	# Emit canonical event
	EventBus.story_event_triggered.emit("player_authorized")
	
	# Fade screen out
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await fade_tween.finished
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	# Ignore ui_cancel (Escape) so it doesn't close or skip automatically
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if current_state != AuthState.AUTHORIZED:
		current_state = AuthState.CANCELLED
