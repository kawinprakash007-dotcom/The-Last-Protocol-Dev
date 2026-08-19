
extends Node

signal power_puzzle_reset
signal power_system_online
signal terminal_online
signal relay_activated(relay_index: int)
signal comms_online
signal shelter_lock_released
signal survivors_rescued
signal robot_destroyed
signal entered_data_center
signal security_threat_detected
signal last_protocol_accessed
signal security_questions_passed
signal last_protocol_activated

var terminal_activated: bool = false
var data_center_entered: bool = false
var threat_detected: bool = false
var power_restored: bool = false
var power_sequence_index: int = 0
var comms_activated: bool = false
var shelter_unlocked: bool = false
var rescue_complete: bool = false

var is_last_protocol_active: bool = false
var is_city_shutdown: bool = false

func activate_terminal() -> void:
	if terminal_activated:
		return
	terminal_activated = true
	print("GAME STATE: TERMINAL ACTIVATED")
	emit_signal("terminal_online")

func enter_data_center() -> void:
	if data_center_entered: return
	data_center_entered = true
	print("GAME STATE: ENTERED DATA CENTER")
	emit_signal("entered_data_center")

func trigger_security_threat() -> void:
	if threat_detected: return
	threat_detected = true
	print("GAME STATE: SECURITY THREAT DETECTED")
	emit_signal("security_threat_detected")

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

func unlock_shelter() -> void:
	if shelter_unlocked:
		return
	shelter_unlocked = true
	print("GAME STATE: SHELTER 04 LOCK RELEASED")
	emit_signal("shelter_lock_released")

func complete_rescue() -> void:
	if rescue_complete:
		return
	rescue_complete = true
	print("GAME STATE: SURVIVORS RESCUED")
	emit_signal("survivors_rescued")

func trigger_robot_destroyed() -> void:
	print("GAME STATE: ROBOT DESTROYED")
	emit_signal("robot_destroyed")

func access_last_protocol() -> void:
	print("GAME STATE: LAST PROTOCOL ACCESSED")
	emit_signal("last_protocol_accessed")

func pass_security_questions() -> void:
	print("GAME STATE: SECURITY QUESTIONS PASSED")
	emit_signal("security_questions_passed")

func activate_last_protocol() -> void:
	if is_last_protocol_active:
		return
	is_last_protocol_active = true
	is_city_shutdown = true
	print("GAME STATE: LAST PROTOCOL ACTIVATED")
	emit_signal("last_protocol_activated")
