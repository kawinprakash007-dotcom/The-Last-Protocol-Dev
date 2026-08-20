## CinematicManager - Controls playback of CinematicSequence resources.
##
## AUTOLOAD: Registered as "CinematicManager" in project.godot.
##
## Usage:
##   CinematicManager.play_sequence(my_sequence)
##   CinematicManager.stop()
##
## Team Ownership: Story Team
##
extends Node


var _current_sequence: CinematicSequence = null
var _current_shot_index: int = -1
var _is_active: bool = false
var _shot_timer: SceneTreeTimer = null
var _player_locked: bool = false
var _camera_controller: Node = null
var _fade_layer: Node = null
var _play_token: int = 0
var _video_player: VideoStreamPlayer = null
var _active_choice_ui: Node = null


var is_active: bool:
	get: return _is_active


func play_sequence(sequence: CinematicSequence) -> void:
	if sequence == null:
		push_warning("CinematicManager: play_sequence() called with null sequence.")
		return
	if sequence.shots.is_empty():
		push_warning("CinematicManager: Sequence '%s' has no shots. Nothing to play." % sequence.sequence_id)
		return
	if _is_active:
		push_warning("CinematicManager: Restart requested while a cinematic is active. Stopping current sequence first.")
		stop()

	_reset_state()
	_play_token += 1
	_camera_controller = _find_node_in_group("cinematic_camera_controller")
	_fade_layer = _find_node_in_group("cinematic_fade")
	if _camera_controller != null and _camera_controller.has_method("begin_cinematic"):
		_camera_controller.begin_cinematic()

	_current_sequence = sequence
	_is_active = true
	EventBus.cinematic_started.emit(sequence.sequence_id)
	_play_shot(0, _play_token)


func stop() -> void:
	if not _is_active:
		return
	var seq_id := _current_sequence.sequence_id if _current_sequence else ""
	_play_token += 1
	_cancel_shot_timer()
	DialogueManager.force_reset()
	NarrationManager.stop_narration("")
	_restore_camera()
	_clear_fade()
	_unlock_player()
	
	if _video_player != null and is_instance_valid(_video_player):
		_video_player.stop()
		_video_player.stream = null
		_video_player.modulate.a = 0.0
		if _video_player.finished.is_connected(_on_video_finished):
			_video_player.finished.disconnect(_on_video_finished)

	if EventBus.story_event_triggered.is_connected(_on_authorization_event_received):
		EventBus.story_event_triggered.disconnect(_on_authorization_event_received)

	if EventBus.story_event_triggered.is_connected(_on_last_protocol_event_received):
		EventBus.story_event_triggered.disconnect(_on_last_protocol_event_received)
			
	_reset_state()
	EventBus.cinematic_finished.emit(seq_id)


func _play_shot(index: int, token: int) -> void:
	if token != _play_token or _current_sequence == null:
		return
	if index < 0 or index >= _current_sequence.shots.size():
		_finish_sequence()
		return

	_current_shot_index = index
	var shot: CinematicShot = _current_sequence.shots[index]
	if shot == null:
		push_warning("CinematicManager: Null CinematicShot at index %d in sequence '%s'. Skipping." % [index, _current_sequence.sequence_id])
		_advance_to_next_shot(token)
		return

	# Clear any previous active choice UI
	if _active_choice_ui != null and is_instance_valid(_active_choice_ui):
		_active_choice_ui.queue_free()
		_active_choice_ui = null

	# Stop any previous shot's narration before this shot starts
	NarrationManager.stop_narration("")

	# Emit HUD metadata if the shot has any
	if not shot.hud_metadata.is_empty():
		EventBus.hud_metadata_shown.emit(shot.hud_metadata)

	# Start narration for this shot (subtitle-only if no voice audio registered)
	if not shot.narration_lines.is_empty():
		NarrationManager.play_narration(shot.narration_lines, shot.shot_id)

	if shot.lock_player and not _player_locked:
		_lock_player()
	elif not shot.lock_player and _player_locked:
		_unlock_player()

	_request_audio(shot)
	_fire_shot_start_events(shot)

	if shot.is_last_protocol:
		if not EventBus.story_event_triggered.is_connected(_on_last_protocol_event_received):
			EventBus.story_event_triggered.connect(_on_last_protocol_event_received)
		if not shot.ui_event.is_empty():
			EventBus.cinematic_ui_event.emit(shot.ui_event)
		else:
			EventBus.cinematic_ui_event.emit("LAST_PROTOCOL_SHOW")
		return

	if shot.is_authorization:
		if not EventBus.story_event_triggered.is_connected(_on_authorization_event_received):
			EventBus.story_event_triggered.connect(_on_authorization_event_received)
		if not shot.ui_event.is_empty():
			EventBus.cinematic_ui_event.emit(shot.ui_event)
		else:
			EventBus.cinematic_ui_event.emit("AUTHORIZATION_SHOW")
		return

	if shot.is_choice and not shot.choice_config.is_empty():
		_play_choice_shot(shot, token)
		return

	if shot.is_video or not shot.video_path.is_empty():
		await _play_video_shot(shot, token)
		return

	await _execute_camera_action(shot)
	if token != _play_token:
		return

	if shot.dialogue_sequence != null:
		if not EventBus.dialogue_finished.is_connected(_on_shot_dialogue_finished):
			EventBus.dialogue_finished.connect(_on_shot_dialogue_finished, CONNECT_ONE_SHOT)
		DialogueManager.start_sequence(shot.dialogue_sequence)
	else:
		_start_shot_timer(shot.duration)


func _request_audio(shot: CinematicShot) -> void:
	if not shot.music_key.is_empty():
		if shot.music_key == "SILENCE":
			StoryAudioManager.stop_music()
		else:
			StoryAudioManager.play_music(shot.music_key)
	if not shot.ambience_key.is_empty():
		if shot.ambience_key == "SILENCE":
			StoryAudioManager.stop_ambience()
		else:
			StoryAudioManager.play_ambience(shot.ambience_key)
	for sfx_key in shot.sfx_keys:
		StoryAudioManager.play_sfx(sfx_key)


## Emit ui_event and story_event_on_start signals at shot entry.
func _fire_shot_start_events(shot: CinematicShot) -> void:
	if not shot.ui_event.is_empty():
		EventBus.cinematic_ui_event.emit(shot.ui_event)
	if not shot.story_event_on_start.is_empty():
		EventBus.story_event_triggered.emit(shot.story_event_on_start)


func _execute_camera_action(shot: CinematicShot) -> void:
	if shot.camera_action in ["STATIC", ""]:
		return
	if _camera_controller == null:
		push_warning("CinematicManager: Camera action '%s' requested, but no cinematic camera controller is available." % shot.camera_action)
		return
	if not _camera_controller.has_method("execute_shot"):
		push_warning("CinematicManager: Camera controller does not implement execute_shot().")
		return
	await _camera_controller.execute_shot(shot)


func _execute_fade_action(shot: CinematicShot) -> void:
	if shot.fade_action.is_empty():
		return
	if _fade_layer == null:
		push_warning("CinematicManager: Fade action '%s' requested, but no cinematic fade layer is available." % shot.fade_action)
		return
	if not _fade_layer.has_method("run_fade"):
		push_warning("CinematicManager: Fade layer does not implement run_fade().")
		return
	await _fade_layer.run_fade(shot.fade_action, shot.fade_duration)


func _start_shot_timer(duration: float) -> void:
	if duration <= 0.0:
		_advance_to_next_shot(_play_token)
		return
	_shot_timer = get_tree().create_timer(duration)
	_shot_timer.timeout.connect(_on_shot_timer_timeout.bind(_play_token), CONNECT_ONE_SHOT)


func _cancel_shot_timer() -> void:
	_shot_timer = null


func _advance_to_next_shot(token: int) -> void:
	if _current_sequence == null or token != _play_token:
		return
	var next := _current_shot_index + 1
	if next >= _current_sequence.shots.size():
		_finish_sequence()
	else:
		_play_shot(next, token)


func _finish_sequence() -> void:
	if _current_sequence == null:
		_is_active = false
		return
	var seq_id := _current_sequence.sequence_id
	var end_scene := _current_sequence.on_end_scene

	_restore_camera()
	_clear_fade()
	_unlock_player()
	_reset_state()
	EventBus.cinematic_finished.emit(seq_id)

	if not end_scene.is_empty():
		if ResourceLoader.exists(end_scene):
			get_tree().change_scene_to_file(end_scene)
		else:
			push_warning("CinematicManager: on_end_scene path '%s' does not exist. Staying in current scene." % end_scene)


func _lock_player() -> void:
	if not _player_locked:
		_player_locked = true
		EventBus.cinematic_mode_toggled.emit(true)


func _unlock_player() -> void:
	if _player_locked:
		_player_locked = false
		EventBus.cinematic_mode_toggled.emit(false)


func _reset_state() -> void:
	if _active_choice_ui != null and is_instance_valid(_active_choice_ui):
		_active_choice_ui.queue_free()
	_active_choice_ui = null
	_current_sequence = null
	_current_shot_index = -1
	_is_active = false
	_player_locked = false
	_shot_timer = null
	_video_player = null


func _on_shot_timer_timeout(token: int) -> void:
	if token != _play_token:
		return
	_fire_shot_complete_event()
	_advance_to_next_shot(token)


func _on_shot_dialogue_finished(sequence_id: String) -> void:
	if not _is_active or _current_sequence == null or _current_shot_index < 0:
		return
	
	var shot: CinematicShot = _current_sequence.shots[_current_shot_index]
	if shot == null:
		return
		
	# Verify that the finished dialogue sequence actually belongs to the current shot.
	if shot.dialogue_sequence == null or shot.dialogue_sequence.sequence_id != sequence_id:
		return
	
	# If the current shot is a video shot, we do NOT advance on dialogue finish.
	# The video shot MUST advance on the video player finished signal.
	if shot.is_video:
		return
		
	_cancel_shot_timer()
	if shot.duration > 0.0:
		_start_shot_timer(shot.duration)
	else:
		_fire_shot_complete_event()
		_advance_to_next_shot(_play_token)


func _fire_shot_complete_event() -> void:
	if _current_sequence == null or _current_shot_index < 0:
		return
	var shot: CinematicShot = _current_sequence.shots[_current_shot_index]
	if shot != null and not shot.on_complete.is_empty():
		EventBus.story_event_triggered.emit(shot.on_complete)


func _find_node_in_group(group_name: String) -> Node:
	var nodes := get_tree().get_nodes_in_group(group_name)
	if nodes.is_empty():
		return null
	return nodes[0]


func _restore_camera() -> void:
	if _camera_controller != null and is_instance_valid(_camera_controller) and _camera_controller.has_method("end_cinematic"):
		_camera_controller.end_cinematic()
	_camera_controller = null


func _clear_fade() -> void:
	if _fade_layer != null and is_instance_valid(_fade_layer) and _fade_layer.has_method("clear_fade"):
		_fade_layer.clear_fade()
	_fade_layer = null


func _play_video_shot(shot: CinematicShot, token: int) -> void:
	if _video_player == null:
		_video_player = _find_node_in_group("cinematic_video_player") as VideoStreamPlayer

	if _video_player == null:
		push_error("CinematicManager: Video shot requested, but no VideoStreamPlayer found in group 'cinematic_video_player'. Falling back to 3D shot.")
		_fallback_3d_shot(shot, token)
		return

	var resolved_path := _resolve_video_path(shot.video_path)
	if resolved_path.is_empty():
		push_error("CinematicManager: Video file not found for path: " + shot.video_path + ". Falling back to 3D shot.")
		_fallback_3d_shot(shot, token)
		return

	var stream = load(resolved_path)
	if stream == null:
		push_error("CinematicManager: Failed to load video stream: " + resolved_path + ". Falling back to 3D shot.")
		_fallback_3d_shot(shot, token)
		return

	_video_player.stream = stream
	_video_player.modulate.a = 0.0
	_video_player.visible = true
	
	# Clear any active CinematicFade overlay so it doesn't cover the video.
	if _fade_layer != null and is_instance_valid(_fade_layer) and _fade_layer.has_method("clear_fade"):
		_fade_layer.clear_fade()
	
	if _video_player.finished.is_connected(_on_video_finished):
		_video_player.finished.disconnect(_on_video_finished)
	_video_player.finished.connect(_on_video_finished.bind(token), CONNECT_ONE_SHOT)

	_video_player.play()
	
	var fade_in_tween := _video_player.create_tween()
	fade_in_tween.tween_property(_video_player, "modulate:a", 1.0, 0.4)
	
	if shot.dialogue_sequence != null:
		if not EventBus.dialogue_finished.is_connected(_on_shot_dialogue_finished):
			EventBus.dialogue_finished.connect(_on_shot_dialogue_finished, CONNECT_ONE_SHOT)
		DialogueManager.start_sequence(shot.dialogue_sequence)


func _on_video_finished(token: int) -> void:
	if token != _play_token or _current_sequence == null:
		return
	
	# Stop narration for the completed shot
	if _current_sequence != null and _current_shot_index >= 0 and _current_shot_index < _current_sequence.shots.size():
		var finished_shot := _current_sequence.shots[_current_shot_index]
		if finished_shot != null:
			NarrationManager.stop_narration(finished_shot.shot_id)
	
	if _video_player != null and is_instance_valid(_video_player):
		var fade_out_tween := _video_player.create_tween()
		fade_out_tween.tween_property(_video_player, "modulate:a", 0.0, 0.4)
		await fade_out_tween.finished
		
		if token == _play_token and _video_player != null and is_instance_valid(_video_player):
			_video_player.stop()
			_video_player.stream = null
	
	_advance_to_next_shot(token)


func _resolve_video_path(path: String) -> String:
	if path.is_empty():
		return ""
	
	if ResourceLoader.exists(path):
		return path
		
	var full_dir := "res://story/assets/videos/"
	var possible_paths: Array[String] = [
		path,
		full_dir + path,
		full_dir + path + ".ogv",
		full_dir + path + ".mp4",
		full_dir + path + ".mp4.mp4"
	]
	
	if not path.begins_with("res://"):
		possible_paths.append(path + ".ogv")
		possible_paths.append(path + ".mp4")
	
	for p in possible_paths:
		if ResourceLoader.exists(p):
			return p
			
	var base_name := path.get_file().get_basename()
	var dir := DirAccess.open(full_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var f_base := file_name.get_basename()
				if f_base == base_name or f_base.get_basename() == base_name or file_name.begins_with(base_name):
					return full_dir + file_name
			file_name = dir.get_next()
			
	return ""


func _fallback_3d_shot(shot: CinematicShot, token: int) -> void:
	if token != _play_token or _current_sequence == null:
		return
	
	if _video_player != null and is_instance_valid(_video_player):
		_video_player.modulate.a = 0.0
		_video_player.stop()
		_video_player.stream = null
		
	await _execute_camera_action(shot)
	if token != _play_token:
		return

	if shot.dialogue_sequence != null:
		if not EventBus.dialogue_finished.is_connected(_on_shot_dialogue_finished):
			EventBus.dialogue_finished.connect(_on_shot_dialogue_finished, CONNECT_ONE_SHOT)
		DialogueManager.start_sequence(shot.dialogue_sequence)
	else:
		_start_shot_timer(shot.duration)


func is_waiting_for_authorization() -> bool:
	if not _is_active or _current_sequence == null or _current_shot_index < 0:
		return false
	var shot: CinematicShot = _current_sequence.shots[_current_shot_index]
	return shot != null and (shot.is_authorization or shot.is_last_protocol or shot.is_choice)


## Instantiate InteractiveChoiceUI, present the choice, and wait for selection.
func _play_choice_shot(shot: CinematicShot, token: int) -> void:
	var ui_scene: PackedScene = load("res://story/ui/interactive_choice_ui.tscn")
	if ui_scene == null:
		push_warning("CinematicManager: interactive_choice_ui.tscn not found — skipping choice shot '%s'" % shot.shot_id)
		_advance_to_next_shot(token)
		return

	var ui: Node = ui_scene.instantiate()
	_active_choice_ui = ui
	# Add to the scene tree root so it survives scene transitions
	get_tree().get_root().add_child(ui)

	if not ui.has_method("show_choice"):
		push_warning("CinematicManager: InteractiveChoiceUI missing show_choice() — skipping '%s'" % shot.shot_id)
		ui.queue_free()
		_advance_to_next_shot(token)
		return

	# Connect one-shot to cinematic_choice_completed before showing to avoid race
	var shot_id_captured := shot.shot_id
	var token_captured := token
	var _choice_handler := func(completed_shot_id: String, _choice: String):
		if completed_shot_id == shot_id_captured and token_captured == _play_token:
			if EventBus.cinematic_choice_completed.is_connected(_on_cinematic_choice_received):
				EventBus.cinematic_choice_completed.disconnect(_on_cinematic_choice_received)
			_advance_to_next_shot(_play_token)

	if not EventBus.cinematic_choice_completed.is_connected(_on_cinematic_choice_received):
		EventBus.cinematic_choice_completed.connect(_on_cinematic_choice_received)

	# Build config, ensuring terminal_id matches the shot_id for completion routing
	var config: Dictionary = shot.choice_config.duplicate()
	config["terminal_id"] = shot.shot_id

	ui.show_choice(config)


func _on_cinematic_choice_received(shot_id: String, _choice: String) -> void:
	if not _is_active or _current_sequence == null or _current_shot_index < 0:
		return
	var current_shot: CinematicShot = _current_sequence.shots[_current_shot_index]
	if current_shot == null or current_shot.shot_id != shot_id:
		return
	if EventBus.cinematic_choice_completed.is_connected(_on_cinematic_choice_received):
		EventBus.cinematic_choice_completed.disconnect(_on_cinematic_choice_received)
	_advance_to_next_shot(_play_token)


func _on_authorization_event_received(event_id: String) -> void:
	if event_id == "player_authorized":
		if EventBus.story_event_triggered.is_connected(_on_authorization_event_received):
			EventBus.story_event_triggered.disconnect(_on_authorization_event_received)
		_advance_to_next_shot(_play_token)


func _on_last_protocol_event_received(event_id: String) -> void:
	if event_id == "last_protocol_initialized":
		if EventBus.story_event_triggered.is_connected(_on_last_protocol_event_received):
			EventBus.story_event_triggered.disconnect(_on_last_protocol_event_received)
		_advance_to_next_shot(_play_token)
