
extends Node

var terminal_activated: bool = false

func activate_terminal() -> void:
	if terminal_activated:
		return
	terminal_activated = true
	print("GAME STATE: TERMINAL ACTIVATED")
