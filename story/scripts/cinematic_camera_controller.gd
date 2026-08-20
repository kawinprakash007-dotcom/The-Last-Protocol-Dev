class_name CinematicCameraController
extends Node

@export var gameplay_camera_path: NodePath = NodePath("")
@export var cinematic_camera_path: NodePath = NodePath("")

var _gameplay_camera: Node = null
var _cinematic_camera: Node = null
var _active_tween: Tween = null
var _original_cinematic_position: Variant
var _original_cinematic_rotation: float = 0.0
var _had_original_state: bool = false
var _began: bool = false


func _ready() -> void:
	add_to_group("cinematic_camera_controller")
	_gameplay_camera = _resolve_camera(gameplay_camera_path, "gameplay_camera")
	_cinematic_camera = _resolve_camera(cinematic_camera_path, "cinematic_camera")
	if _cinematic_camera != null:
		_original_cinematic_position = _get_camera_position(_cinematic_camera)
		_original_cinematic_rotation = _get_camera_rotation(_cinematic_camera)
		_had_original_state = true


func begin_cinematic() -> void:
	_began = true
	if _gameplay_camera == null:
		_gameplay_camera = _resolve_camera(gameplay_camera_path, "gameplay_camera")
	if _cinematic_camera == null:
		_cinematic_camera = _resolve_camera(cinematic_camera_path, "cinematic_camera")
	if _gameplay_camera != null:
		_set_camera_current(_gameplay_camera, false)
	if _cinematic_camera != null:
		_set_camera_current(_cinematic_camera, true)
	else:
		push_warning("CinematicCameraController: No cinematic camera available.")


func execute_shot(shot: CinematicShot) -> void:
	if _cinematic_camera == null:
		push_warning("CinematicCameraController: Cannot execute shot '%s' without a cinematic camera." % shot.shot_id)
		return
	match shot.camera_action:
		"STATIC", "":
			return
		"CUT":
			_apply_target(shot, true)
		"MOVE_TO", "LOOK_AT", "MOVE_AND_LOOK":
			await _move_camera(shot)
		_:
			push_warning("CinematicCameraController: Unsupported camera action '%s'." % shot.camera_action)


func end_cinematic() -> void:
	_cancel_tween()
	if _had_original_state and _cinematic_camera != null:
		_set_camera_position(_cinematic_camera, _original_cinematic_position)
		_set_camera_rotation(_cinematic_camera, _original_cinematic_rotation)
	if _cinematic_camera != null:
		_set_camera_current(_cinematic_camera, false)
	if _gameplay_camera != null:
		_set_camera_current(_gameplay_camera, true)
	_began = false


func is_cinematic_camera_current() -> bool:
	return _is_camera_current(_cinematic_camera)


func is_gameplay_camera_current() -> bool:
	return _is_camera_current(_gameplay_camera)


func get_cinematic_camera() -> Node:
	return _cinematic_camera


func _move_camera(shot: CinematicShot) -> void:
	var target := _resolve_target(shot.camera_target)
	if target == null and shot.camera_action in ["MOVE_TO", "MOVE_AND_LOOK"]:
		push_warning("CinematicCameraController: Shot '%s' requested movement but camera_target was missing." % shot.shot_id)
		return
	var look_target := _resolve_target(shot.look_target)
	if look_target == null and shot.camera_action in ["LOOK_AT", "MOVE_AND_LOOK"] and not shot.look_target.is_empty():
		push_warning("CinematicCameraController: Shot '%s' requested look target but look_target was missing." % shot.shot_id)

	_cancel_tween()
	var duration: float = max(shot.camera_transition_duration, 0.0)
	if duration <= 0.0 or shot.camera_transition == "CUT":
		_apply_target(shot, true)
		return

	_active_tween = create_tween()
	_configure_transition(_active_tween, shot.camera_transition)
	if target != null:
		_active_tween.tween_property(_cinematic_camera, "global_position", _get_node_position(target), duration)
	if look_target != null:
		_active_tween.parallel().tween_property(_cinematic_camera, "rotation", _rotation_to_target(look_target), duration)
	await _active_tween.finished
	_active_tween = null


func _apply_target(shot: CinematicShot, include_look: bool) -> void:
	var target := _resolve_target(shot.camera_target)
	if target != null:
		_set_camera_position(_cinematic_camera, _get_node_position(target))
		_set_camera_rotation(_cinematic_camera, _get_node_rotation(target))
	elif not shot.camera_target.is_empty():
		push_warning("CinematicCameraController: Shot '%s' camera_target was missing." % shot.shot_id)

	if include_look:
		var look_target := _resolve_target(shot.look_target)
		if look_target != null:
			_set_camera_rotation(_cinematic_camera, _rotation_to_target(look_target))
		elif not shot.look_target.is_empty():
			push_warning("CinematicCameraController: Shot '%s' look_target was missing." % shot.shot_id)


func _configure_transition(tween: Tween, transition: String) -> void:
	match transition:
		"LINEAR":
			tween.set_trans(Tween.TRANS_LINEAR)
			tween.set_ease(Tween.EASE_IN_OUT)
		"EASE_IN":
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_IN)
		"EASE_OUT":
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_OUT)
		"EASE_IN_OUT":
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_IN_OUT)
		_:
			tween.set_trans(Tween.TRANS_LINEAR)
			tween.set_ease(Tween.EASE_IN_OUT)


func _resolve_camera(path: NodePath, group_name: String) -> Node:
	if not path.is_empty():
		var camera := get_node_or_null(path)
		if camera != null:
			return camera
	var nodes := get_tree().get_nodes_in_group(group_name)
	if not nodes.is_empty():
		return nodes[0]
	return null


func _resolve_target(path: NodePath) -> Node:
	if path.is_empty():
		return null
	var root := get_tree().current_scene
	if root != null:
		var target := root.get_node_or_null(path)
		if target != null:
			return target
	return get_node_or_null(path)


func _cancel_tween() -> void:
	if _active_tween != null:
		_active_tween.kill()
		_active_tween = null


func _set_camera_current(camera: Node, current: bool) -> void:
	if camera == null:
		return
	if camera is Camera2D:
		camera.enabled = current
	elif camera is Camera3D:
		camera.current = current


func _is_camera_current(camera: Node) -> bool:
	if camera == null:
		return false
	if camera is Camera2D:
		return camera.enabled
	if camera is Camera3D:
		return camera.current
	return false


func _get_camera_position(camera: Node) -> Variant:
	return camera.global_position


func _set_camera_position(camera: Node, value: Variant) -> void:
	camera.global_position = value


func _get_camera_rotation(camera: Node) -> float:
	if camera is Node2D:
		return camera.global_rotation
	if camera is Node3D:
		return camera.global_rotation.y
	return 0.0


func _set_camera_rotation(camera: Node, value: float) -> void:
	if camera is Node2D:
		camera.global_rotation = value
	elif camera is Node3D:
		var rotation: Vector3 = camera.global_rotation
		rotation.y = value
		camera.global_rotation = rotation


func _get_node_position(node: Node) -> Variant:
	return node.global_position


func _get_node_rotation(node: Node) -> float:
	if node is Node2D:
		return node.global_rotation
	if node is Node3D:
		return node.global_rotation.y
	return 0.0


func _rotation_to_target(target: Node) -> float:
	if _cinematic_camera is Node2D and target is Node2D:
		var direction: Vector2 = target.global_position - _cinematic_camera.global_position
		return direction.angle()
	if _cinematic_camera is Node3D and target is Node3D:
		var direction_3d: Vector3 = target.global_position - _cinematic_camera.global_position
		return atan2(direction_3d.x, direction_3d.z)
	return _get_camera_rotation(_cinematic_camera)
