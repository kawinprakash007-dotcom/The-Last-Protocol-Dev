extends Node

signal cutscene_finished

var is_cutscene_playing: bool = false
var _current_cutscene: Node = null

# State tracking for restoration
var _previous_mouse_mode: int
var _player: Node = null

func play_cutscene(scene_path: String) -> void:
	if is_cutscene_playing:
		push_warning("CutsceneManager: Already playing a cutscene.")
		return
		
	print("[CutsceneManager] Starting cutscene: ", scene_path)
	is_cutscene_playing = true
	
	# 1. Disable Player
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		if "is_control_disabled" in _player:
			_player.is_control_disabled = true
		
		# Hide HUD (CanvasLayer)
		for child in _player.get_children():
			if child is CanvasLayer:
				child.visible = false
				
	# 2. Save mouse mode and set to visible (so UI elements in cinematic work)
	_previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# 3. Instantiate Cinematic
	var scene_res = load(scene_path)
	if not scene_res:
		push_error("CutsceneManager: Failed to load scene ", scene_path)
		finish_cutscene()
		return
		
	_current_cutscene = scene_res.instantiate()
	get_tree().root.add_child(_current_cutscene)

func finish_cutscene() -> void:
	if not is_cutscene_playing:
		return
		
	print("[CutsceneManager] Finishing cutscene.")
	is_cutscene_playing = false
	
	# 1. Clean up the cinematic instance
	if _current_cutscene and is_instance_valid(_current_cutscene):
		_current_cutscene.queue_free()
		_current_cutscene = null
		
	# 2. Restore Player
	if _player and is_instance_valid(_player):
		if "is_control_disabled" in _player:
			_player.is_control_disabled = false
			
		# Show HUD
		for child in _player.get_children():
			if child is CanvasLayer:
				child.visible = true
				
		# Force camera back to player's camera
		var cam = _player.get_node_or_null("SpringArm3D/Camera")
		if cam and cam is Camera3D:
			cam.make_current()
			
	# 3. Restore mouse mode safely after everything else is cleaned up
	call_deferred("_restore_mouse_mode")
	
	emit_signal("cutscene_finished")

func _restore_mouse_mode() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
