extends Node
class_name CinematicCameraManager

signal cinematic_started
signal cinematic_ended

@export var gameplay_camera: Camera3D

var _active_cinematic_camera: Camera3D
var _is_playing: bool = false
var _original_fov: float = 75.0

func _ready():
	if gameplay_camera:
		_original_fov = gameplay_camera.fov

func play_cinematic(cinematic_camera: Camera3D, duration: float = 0.0):
	if _is_playing or not gameplay_camera:
		return
		
	_is_playing = true
	_active_cinematic_camera = cinematic_camera
	
	# Transition control to cinematic camera
	cinematic_camera.current = true
	emit_signal("cinematic_started")
	
	if duration > 0.0:
		var timer = get_tree().create_timer(duration)
		timer.timeout.connect(end_cinematic)

func end_cinematic():
	if not _is_playing or not gameplay_camera:
		return
		
	# Restore gameplay camera
	gameplay_camera.current = true
	_is_playing = false
	_active_cinematic_camera = null
	
	emit_signal("cinematic_ended")
