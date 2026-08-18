extends Area3D

## SurvivorTrigger — fires once when player enters the shelter zone.
## Calls GameState.complete_rescue() which emits survivors_rescued signal.

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _triggered:
		return
	if body.name == "Player":
		_triggered = true
		print("RESCUE TRIGGER: PLAYER REACHED SURVIVORS")
		if GameState.has_method("complete_rescue"):
			GameState.complete_rescue()
