class_name Terminal
extends Interactable

@export var is_activated: bool = false

func interact() -> void:
	if is_activated:
		return
	is_activated = true
	print("TERMINAL ACTIVATED")
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("terminal_confirm")
	GameState.activate_terminal()
