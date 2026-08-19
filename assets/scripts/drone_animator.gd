extends Node3D

@export var bob_amplitude: float = 0.08
@export var bob_frequency: float = 1.2
@export var tilt_amplitude: float = 0.04
@export var wander_radius: float = 0.3

var _initial_pos: Vector3
var _time: float = 0.0

func _ready() -> void:
	_initial_pos = position

func _process(delta: float) -> void:
	_time += delta
	var bob_offset := sin(_time * bob_frequency) * bob_amplitude
	var wander_x := sin(_time * bob_frequency * 0.7) * wander_radius
	var wander_z := cos(_time * bob_frequency * 0.5) * wander_radius * 0.5
	
	position = _initial_pos + Vector3(wander_x, bob_offset, wander_z)
	rotation.z = sin(_time * bob_frequency * 0.7) * tilt_amplitude
	rotation.x = cos(_time * bob_frequency * 0.5) * (tilt_amplitude * 0.6)
