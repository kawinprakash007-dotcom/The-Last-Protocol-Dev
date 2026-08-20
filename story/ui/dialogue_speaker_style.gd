class_name DialogueSpeakerStyle
extends Resource

@export var speaker_id: String = ""
@export var display_name: String = ""
@export var text_color: Color = Color(0.9, 0.92, 0.92, 1.0)
@export var speaker_color: Color = Color(0.9, 0.92, 0.92, 1.0)
@export var panel_color: Color = Color(0.04, 0.05, 0.06, 0.88)
@export var border_color: Color = Color(0.35, 0.42, 0.46, 0.75)
@export var accent_color: Color = Color(0.4, 0.8, 1.0, 1.0)
@export var typing_speed: float = 42.0
@export var sound_key: String = ""
@export var portrait: Texture2D
@export var signal_effect: String = ""
@export_range(0.0, 1.0, 0.01) var glitch_amount: float = 0.0
