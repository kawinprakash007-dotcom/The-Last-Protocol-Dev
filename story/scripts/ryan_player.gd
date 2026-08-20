## RyanPlayer — Simple 2D CharacterBody2D for the first gameplay segment.
##
## Controls:
##   Left / Right  → A/D or Arrow keys
##   No jump, no combat — this is a cinematic walking sequence.
##
## The player locks/unlocks via EventBus.cinematic_mode_toggled.
## Interaction is proximity-based; the GameplayController triggers it.
##
## Team Ownership: Gameplay Team
##
class_name RyanPlayer
extends CharacterBody2D


const SPEED: float     = 180.0
const GRAVITY: float   = 900.0

var _locked: bool = false

## Set externally by GameplayController to face correct direction.
var facing_right: bool = true


func _ready() -> void:
	EventBus.cinematic_mode_toggled.connect(_on_lock_changed)


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	if _locked:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		move_and_slide()
		return

	# Horizontal input
	var dir: float = 0.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		dir = 1.0
	elif Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		dir = -1.0

	velocity.x = dir * SPEED

	# Flip visual
	var visual := get_node_or_null("PlayerVisual")
	if visual and dir != 0.0:
		visual.scale.x = sign(dir)

	move_and_slide()


func _on_lock_changed(locked: bool) -> void:
	_locked = locked
	if locked:
		velocity.x = 0.0


## Returns current world x position.
func get_x() -> float:
	return global_position.x
