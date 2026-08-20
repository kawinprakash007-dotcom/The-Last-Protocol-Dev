class_name Door
extends Interactable

@export var is_open: bool = false

@onready var collision: CollisionShape3D = $CollisionShape3D

# Stops polling once we have acted on the state.
var _listening: bool = true

func _process(_delta: float) -> void:
	if _listening and GameState.terminal_activated and not is_open:
		_listening = false
		open()

func open() -> void:
	if is_open:
		return
	is_open = true
	position.x += 1.2
	collision.disabled = true
	print("DOOR OPENED")
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("door_open")

func close() -> void:
	if not is_open:
		return
	is_open = false
	position.x -= 1.2
	collision.disabled = false
	print("DOOR CLOSED")
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("door_close")

func interact() -> void:
	if is_open:
		close()
	else:
		open()
