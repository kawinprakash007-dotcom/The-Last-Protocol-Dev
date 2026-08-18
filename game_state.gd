
extends Node

signal power_puzzle_reset
signal power_system_online
signal terminal_online
signal relay_activated(relay_index: int)
signal comms_online

var terminal_activated: bool = false
var power_restored: bool = false
var power_sequence_index: int = 0
var comms_activated: bool = false

func activate_terminal() -> void:
	if terminal_activated:
		return
	terminal_activated = true
	print("GAME STATE: TERMINAL ACTIVATED")
	emit_signal("terminal_online")

func advance_power_sequence(expected_index: int) -> bool:
	if power_restored:
		return false
	
	if power_sequence_index == expected_index:
		power_sequence_index += 1
		print("POWER PUZZLE: SEQUENCE ", power_sequence_index, "/3")
		emit_signal("relay_activated", expected_index)
		if power_sequence_index >= 3:
			restore_power()
		return true
	else:
		print("POWER PUZZLE: INCORRECT SEQUENCE! RESETTING...")
		power_sequence_index = 0
		emit_signal("power_puzzle_reset")
		return false

func restore_power() -> void:
	if power_restored:
		return
	power_restored = true
	print("POWER SYSTEM ONLINE")
	emit_signal("power_system_online")

func activate_comms() -> void:
	if comms_activated:
		return
	comms_activated = true
	print("COMMS ACTIVATED")
	emit_signal("comms_online")
