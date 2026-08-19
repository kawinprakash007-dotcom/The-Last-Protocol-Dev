extends Node3D

@export var rotation_speed: float = 4.0
@export var axis: Vector3 = Vector3.UP

func _process(delta: float) -> void:
	rotate(axis.normalized(), rotation_speed * delta)
