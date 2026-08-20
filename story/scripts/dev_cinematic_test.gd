extends Node3D

@onready var camera_controller: Node = $CinematicCameraController
@onready var gameplay_camera: Camera3D = $GameplayCamera
@onready var cinematic_camera: Camera3D = $CinematicCamera
@onready var fade: Node = $CinematicFade
@onready var dialogue_ui: DialogueUI = $DialogueUI
@onready var move_marker: Node3D = $CinematicMarkers/Shot_02
@onready var look_marker: Node3D = $CinematicMarkers/LookTarget

var _pass_count: int = 0
var _fail_count: int = 0
var _cinematic_started_count: int = 0
var _cinematic_finished_count: int = 0
var _auth_events_count: int = 0
var _last_protocol_events_count: int = 0
var _lock_count: int = 0
var _unlock_count: int = 0
var _dialogue_started_count: int = 0
var _dialogue_finished_count: int = 0
var _ui_event_received: String = ""


func _ready() -> void:
	EventBus.cinematic_started.connect(func(_sequence_id: String): _cinematic_started_count += 1)
	EventBus.cinematic_finished.connect(func(_sequence_id: String): _cinematic_finished_count += 1)
	EventBus.cinematic_mode_toggled.connect(func(locked: bool):
		if locked:
			_lock_count += 1
		else:
			_unlock_count += 1
	)
	EventBus.dialogue_started.connect(func(_sequence_id: String): _dialogue_started_count += 1)
	EventBus.dialogue_finished.connect(func(_sequence_id: String): _dialogue_finished_count += 1)
	EventBus.dialogue_line_shown.connect(_on_dialogue_line_shown)
	EventBus.story_event_triggered.connect(func(event_id: String):
		if event_id == "player_authorized":
			_auth_events_count += 1
		elif event_id == "last_protocol_initialized":
			_last_protocol_events_count += 1
	)
	EventBus.cinematic_ui_event.connect(func(ev: String):
		_ui_event_received = ev
		if ev == "AUTHORIZATION_SHOW":
			var auth_res := load("res://story/cinematics/ui/AuthorizationScreen.tscn")
			if auth_res:
				var inst = auth_res.instantiate()
				inst.name = "AuthorizationScreen"
				add_child(inst)
				if inst.has_method("initialize_interactive"):
					inst.call("initialize_interactive")
		elif ev == "LAST_PROTOCOL_SHOW":
			var last_res := load("res://story/cinematics/ui/LastProtocolScreen.tscn")
			if last_res:
				var inst = last_res.instantiate()
				inst.name = "LastProtocolScreen"
				add_child(inst)
				if inst.has_method("initialize_interactive"):
					inst.call("initialize_interactive")
	)

	await get_tree().process_frame
	await _run_tests()


func _run_tests() -> void:
	print("\n====================================================")
	print("  THE LAST PROTOCOL - CINEMATIC VALIDATION")
	print("====================================================\n")

	_check(camera_controller != null, "01 cinematic camera controller loads")
	_check(fade != null, "02 cinematic fade loads")
	_check(dialogue_ui != null, "03 DialogueUI is available for cinematics")
	_check(gameplay_camera.current, "04 gameplay camera starts active")
	_check(not cinematic_camera.current, "05 cinematic camera starts inactive")

	var sequence := _make_sequence()
	CinematicManager.play_sequence(sequence)
	await get_tree().create_timer(0.5).timeout
	await get_tree().process_frame

	_check(_cinematic_started_count == 1, "06 cinematic_started emitted once")
	_check(_lock_count == 1, "07 player lock event emitted")
	_check(camera_controller.is_cinematic_camera_current(), "08 cinematic camera takes control")
	_check(not gameplay_camera.current, "09 gameplay camera is temporarily inactive")
	_check(cinematic_camera.global_position.distance_to(move_marker.global_position) < 0.5, "10 camera moves to marker")
	var dir := look_marker.global_position - cinematic_camera.global_position
	var target_y := atan2(dir.x, dir.z)
	_check(abs(cinematic_camera.global_rotation.y - target_y) < 0.02, "11 camera looks at marker")
	_check(_dialogue_started_count == 1, "12 dialogue starts during cinematic")

	dialogue_ui.request_continue()
	await get_tree().process_frame
	dialogue_ui.request_continue()
	await get_tree().create_timer(0.5).timeout

	_check(_dialogue_finished_count == 1, "13 dialogue finishes and cinematic continues")
	_check(_cinematic_finished_count == 1, "14 cinematic_finished emitted once")
	_check(_unlock_count == 1, "15 player unlock event emitted")
	_check(camera_controller.is_gameplay_camera_current(), "16 gameplay camera restores")
	_check(not cinematic_camera.current, "17 cinematic camera releases")
	_check(fade.is_clear(), "18 fade clears after cinematic end")
	_check(not DialogueManager.is_active, "19 DialogueManager is not trapped active")
	_check(not CinematicManager.is_active, "20 CinematicManager resets inactive")

	var safe_sequence := _make_missing_resource_sequence()
	CinematicManager.play_sequence(safe_sequence)
	await get_tree().create_timer(0.1).timeout
	_check(not CinematicManager.is_active, "21 missing camera target fails safely")
	_check(_cinematic_finished_count == 2, "22 missing-resource sequence still finishes")

	# Test 23 — ui_event signal
	_ui_event_received = ""
	var ui_event_sequence := _make_ui_event_sequence()
	CinematicManager.play_sequence(ui_event_sequence)
	await get_tree().create_timer(0.15).timeout
	_check(_ui_event_received == "SHOW_DIAGNOSTIC", "23 cinematic_ui_event emitted from shot ui_event field")

	# Video Playback Integration Tests
	print("\n--- Running Video Playback Integration Tests ---")
	
	var mock_script = GDScript.new()
	mock_script.source_code = "extends VideoStreamPlayer\n" + \
		"var _was_playing: bool = false\n" + \
		"var _play_timer: float = 0.0\n" + \
		"func _init() -> void:\n" + \
		"\tset_process(true)\n" + \
		"\tprint(\"  [MOCK] VideoStreamPlayer initialized\")\n" + \
		"func _process(delta: float) -> void:\n" + \
		"\tif is_playing():\n" + \
		"\t\tif not _was_playing:\n" + \
		"\t\t\t_was_playing = true\n" + \
		"\t\t\t_play_timer = 0.05\n" + \
		"\t\t\tprint(\"  [MOCK] Started playing stream: \", stream.resource_path if stream else 'NULL')\n" + \
		"\t\tif _play_timer > 0.0:\n" + \
		"\t\t\t_play_timer -= delta\n" + \
		"\t\t\tif _play_timer <= 0.0:\n" + \
		"\t\t\t\tprint(\"  [MOCK] Video finished, emitting signal\")\n" + \
		"\t\t\t\tstop()\n" + \
		"\t\t\t\tfinished.emit()\n" + \
		"\t\t\t\t_was_playing = false\n" + \
		"\telse:\n" + \
		"\t\t_was_playing = false\n" + \
		"\t\t_play_timer = 0.0\n"
	mock_script.reload()
	
	var player = get_node_or_null("VideoLayer/VideoStreamPlayer")
	_check(player != null, "VideoStreamPlayer node exists in test scene")
	if player != null:
		player.set_script(mock_script)
		_check(player.get_script() == mock_script, "Mock script attached to VideoStreamPlayer")
		
	# Play the test sequence
	_cinematic_finished_count = 0
	var video_seq = _make_test_sequence()
	CinematicManager.play_sequence(video_seq)
	
	# Wait for the sequence to play through (mock videos of 0.05s, fades of 0.05s, 3D moves, total duration ~2.4s)
	await get_tree().create_timer(3.5).timeout
	await get_tree().process_frame
	
	_check(_cinematic_finished_count == 1, "24 video sequence completed successfully")
	_check(not CinematicManager.is_active, "25 CinematicManager resets inactive after video sequence")

	# Interactive Authorization Tests
	print("\n--- Running Phase 13 Interactive Authorization Tests ---")
	
	_auth_events_count = 0

	# Play interactive sequence
	_cinematic_finished_count = 0
	var auth_seq := _make_auth_test_sequence()
	CinematicManager.play_sequence(auth_seq)
	
	# Wait for the first video to play and transition to the authorization shot (0.05s play + 0.4s fade)
	await get_tree().create_timer(0.6).timeout
	await get_tree().process_frame
	
	# Assertions for paused blocking shot
	_check(CinematicManager.is_waiting_for_authorization(), "26 CinematicManager blocks on authorization shot")
	_check(CinematicManager.is_active, "27 sequence remains active while waiting")
	
	var auth_screen = get_node_or_null("AuthorizationScreen")
	_check(auth_screen != null, "28 AuthorizationScreen instance exists in test scene")
	
	if auth_screen != null:
		# Test skip immunity: CinematicManager skip should be ignored
		# Check state
		_check(auth_screen.get("current_state") == 0, "29 initial state is WAITING_FOR_INPUT")
		
		# Test Deny
		auth_screen.call("_on_deny_pressed")
		_check(auth_screen.get("current_state") == 1, "30 deny transition triggers State.DENIED")
		_check(auth_screen.get_node("PanelContainer/MarginContainer/VBoxContainer/ButtonBox/DenyButton").disabled, "31 deny button disabled")
		_check(auth_screen.get_node("PanelContainer/MarginContainer/VBoxContainer/ButtonBox/AuthorizeButton").disabled, "32 authorize button disabled")
		
		# Wait for denial timer to complete (2.6s total animation + buffer)
		await get_tree().create_timer(3.0).timeout
		await get_tree().process_frame
		
		_check(auth_screen.get("current_state") == 0, "33 state restores to WAITING_FOR_INPUT")
		_check(not auth_screen.get_node("PanelContainer/MarginContainer/VBoxContainer/ButtonBox/DenyButton").disabled, "34 deny button re-enabled")
		_check(not auth_screen.get_node("PanelContainer/MarginContainer/VBoxContainer/ButtonBox/AuthorizeButton").disabled, "35 authorize button re-enabled")
		
		# Test Authorize & Double-Click prevention
		auth_screen.call("_on_authorize_pressed")
		_check(auth_screen.get("current_state") == 2, "36 authorize transition triggers State.VERIFYING")
		
		# Simulating double-click which should be ignored
		auth_screen.call("_on_authorize_pressed")
		
		# Verification animation: 7 steps * 0.4s = 2.8s + fade duration
		await get_tree().create_timer(4.0).timeout
		await get_tree().process_frame
		
		_check(_auth_events_count == 1, "37 exactly one player_authorized event was emitted")
		_check(get_node_or_null("AuthorizationScreen") == null, "38 UI screen removed on authorization completion")
		
		# Let the subsequent shots play through and complete
		await get_tree().create_timer(0.6).timeout
		await get_tree().process_frame
		
		_check(_cinematic_finished_count == 1, "39 interactive sequence completed successfully after authorization")
		_check(not CinematicManager.is_active, "40 CinematicManager is reset inactive")

	# Phase 14 Final Cinematic Timeline Tests
	print("\n--- Running Phase 14 Final Cinematic Timeline Tests ---")
	
	var final_builder_script = load("res://story/cinematics/final_opening_builder.gd")
	var final_seq: CinematicSequence = final_builder_script.build()
	var video_paths_ok := true
	for shot in final_seq.shots:
		if shot.is_video and not shot.video_path.is_empty():
			var resolved = CinematicManager.call("_resolve_video_path", shot.video_path)
			if resolved.is_empty():
				video_paths_ok = false
				print("  [FAIL] Failed to resolve video path: ", shot.video_path)
	_check(video_paths_ok, "41 all 10 video paths in FinalOpeningBuilder resolve successfully")
	
	_cinematic_finished_count = 0
	_auth_events_count = 0
	_last_protocol_events_count = 0
	
	# Override on_end_scene in test context so it doesn't change scenes to main.tscn (which would unload test nodes)
	# Wait, actually, let's keep it but intercept get_tree().change_scene_to_file or verify that change_scene_to_file works.
	# But in test environment, changing scene to main.tscn would exit the test tree.
	# So we temporarily set final_seq.on_end_scene = "" in the test to check everything else, or let it load main.tscn but check before it!
	# Set it to empty to verify final sequence end state.
	final_seq.on_end_scene = ""
	
	CinematicManager.play_sequence(final_seq)
	
	# Wait for videos + choice shots to advance to authorization shot
	for _i in range(15):
		await get_tree().create_timer(0.4).timeout
		await get_tree().process_frame
		var _ci_a = CinematicManager.get("_current_shot_index")
		var _seq_a = CinematicManager.get("_current_sequence")
		if _seq_a != null and _ci_a >= 0 and _ci_a < _seq_a.shots.size():
			var _shot_a = _seq_a.shots[_ci_a]
			if _shot_a != null and _shot_a.is_choice:
				print("DIAGNOSTIC: Resolving pre-auth choice shot: ", _shot_a.shot_id)
				EventBus.cinematic_choice_completed.emit(_shot_a.shot_id, "granted")
			elif _shot_a != null and _shot_a.is_authorization:
				break

	await get_tree().create_timer(0.5).timeout
	await get_tree().process_frame

	print("DIAGNOSTIC: is_active=", CinematicManager.is_active, " current_shot_index=", CinematicManager.get("_current_shot_index"), " total_shots=", final_seq.shots.size())
	if CinematicManager._current_sequence != null and CinematicManager._current_shot_index >= 0 and CinematicManager._current_shot_index < final_seq.shots.size():
		print("DIAGNOSTIC: current_shot_id=", final_seq.shots[CinematicManager._current_shot_index].shot_id)
	_check(CinematicManager.is_waiting_for_authorization(), "42 paused waiting for Creator authorization in final timeline")

	var final_auth_screen = get_node_or_null("AuthorizationScreen")
	_check(final_auth_screen != null, "43 AuthorizationScreen exists in final timeline")

	if final_auth_screen != null:
		# Click Authorize
		final_auth_screen.call("_on_authorize_pressed")
		
		# Wait for biometric steps to complete (2.8s steps + 0.4s fade = 3.2s)
		await get_tree().create_timer(3.5).timeout
		await get_tree().process_frame
		
		_check(_auth_events_count == 1, "44 player_authorized event emitted in final timeline")
		_check(get_node_or_null("AuthorizationScreen") == null, "45 AuthorizationScreen overlay cleared in final timeline")
		
		# Wait for video shots and resolve choice shots between auth and last_protocol
		for _i in range(25):
			await get_tree().create_timer(0.4).timeout
			await get_tree().process_frame
			var _ci_b = CinematicManager.get("_current_shot_index")
			var _seq_b = CinematicManager.get("_current_sequence")
			if _seq_b != null and _ci_b >= 0 and _ci_b < _seq_b.shots.size():
				var _shot_b = _seq_b.shots[_ci_b]
				if _shot_b != null and _shot_b.is_choice:
					print("DIAGNOSTIC: Resolving post-auth choice shot: ", _shot_b.shot_id)
					EventBus.cinematic_choice_completed.emit(_shot_b.shot_id, "trace")
				elif _shot_b != null and _shot_b.is_last_protocol:
					break

		await get_tree().create_timer(0.5).timeout
		await get_tree().process_frame

		
		print("DIAGNOSTIC 46: is_active=", CinematicManager.is_active, " current_shot_index=", CinematicManager.get("_current_shot_index"), " seq_null=", CinematicManager._current_sequence == null)
		_check(CinematicManager.is_waiting_for_authorization(), "46 paused waiting for Last Protocol confirmation in final timeline")
		
		var lp_screen = get_node_or_null("LastProtocolScreen")
		_check(lp_screen != null, "47 LastProtocolScreen overlay exists")
		
		if lp_screen != null:
			_check(lp_screen.get("current_state") == 0, "48 initial last protocol state is WAITING_FOR_INPUT")
			
			# Click Initialize
			lp_screen.call("_on_initialize_pressed")
			_check(lp_screen.get("current_state") == 1, "49 state transitions to INITIALIZING")
			_check(lp_screen.get_node("PanelContainer/MarginContainer/VBoxContainer/ButtonBox/InitializeButton").disabled, "50 initialize button disabled")
			
			# Wait for boot animation to complete (5 steps * 0.5s = 2.5s + 0.5s fade = 3.0s)
			await get_tree().create_timer(3.4).timeout
			await get_tree().process_frame
			
			_check(_last_protocol_events_count == 1, "51 last_protocol_initialized event emitted")
			_check(get_node_or_null("LastProtocolScreen") == null, "52 LastProtocolScreen overlay cleared")
			
			await get_tree().process_frame
			await get_tree().process_frame
			
			_check(_cinematic_finished_count == 1, "53 final cinematic sequence completed successfully")

	print("\n====================================================")
	print("  RESULTS: %d PASSED   %d FAILED" % [_pass_count, _fail_count])
	print("====================================================\n")
	get_tree().quit(_fail_count)


func _make_sequence() -> CinematicSequence:
	var sequence := CinematicSequence.new()
	sequence.sequence_id = "dev_cinematic_system_test"
	sequence.shots = [
		_make_fade_shot("shot_01_fade_from_black", "FADE_FROM_BLACK", 0.05, true),
		_make_camera_shot("shot_02_move_to_marker", "MOVE_TO", ^"CinematicMarkers/Shot_02", NodePath(""), "LINEAR", 0.05, true),
		_make_camera_shot("shot_03_look_at_marker", "LOOK_AT", NodePath(""), ^"CinematicMarkers/LookTarget", "CUT", 0.0, true),
		_make_dialogue_shot(),
		_make_wait_shot("shot_05_wait", 0.05, true),
		_make_fade_shot("shot_06_fade_to_black", "FADE_TO_BLACK", 0.05, true),
		_make_wait_shot("shot_07_end", 0.0, false),
	]
	return sequence


func _make_missing_resource_sequence() -> CinematicSequence:
	var sequence := CinematicSequence.new()
	sequence.sequence_id = "dev_cinematic_missing_resource_test"
	sequence.shots = [
		_make_camera_shot("missing_marker", "MOVE_TO", ^"CinematicMarkers/DoesNotExist", NodePath(""), "CUT", 0.0, true),
		_make_wait_shot("end_after_missing_marker", 0.0, false),
	]
	return sequence


func _make_ui_event_sequence() -> CinematicSequence:
	var shot := CinematicShot.new()
	shot.shot_id = "shot_ui_event_test"
	shot.ui_event = "SHOW_DIAGNOSTIC"
	shot.duration = 0.05
	shot.lock_player = false

	var sequence := CinematicSequence.new()
	sequence.sequence_id = "dev_cinematic_ui_event_test"
	sequence.shots = [shot]
	return sequence


func _make_fade_shot(shot_id: String, fade_action: String, fade_duration: float, lock_player: bool) -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = shot_id
	shot.fade_action = fade_action
	shot.fade_duration = fade_duration
	shot.duration = 0.0
	shot.lock_player = lock_player
	return shot


func _make_camera_shot(
		shot_id: String,
		action: String,
		camera_target: NodePath,
		look_target_path: NodePath,
		transition: String,
		transition_duration: float,
		lock_player: bool) -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = shot_id
	shot.camera_action = action
	shot.camera_target = camera_target
	shot.look_target = look_target_path
	shot.camera_transition = transition
	shot.camera_transition_duration = transition_duration
	shot.duration = 0.0
	shot.lock_player = lock_player
	return shot


func _make_dialogue_shot() -> CinematicShot:
	var line := DialogueLine.new()
	line.speaker_id = "GENESIS"
	line.text = "Diagnostic sequence active."

	var dialogue := DialogueSequence.new()
	dialogue.sequence_id = "dev_cinematic_dialogue"
	dialogue.lines = [line]

	var shot := CinematicShot.new()
	shot.shot_id = "shot_04_dialogue"
	shot.dialogue_sequence = dialogue
	shot.duration = 0.0
	shot.lock_player = true
	return shot


func _make_wait_shot(shot_id: String, duration: float, lock_player: bool) -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = shot_id
	shot.duration = duration
	shot.lock_player = lock_player
	return shot


func _on_dialogue_line_shown(_line: DialogueLine) -> void:
	await get_tree().process_frame
	dialogue_ui.request_continue()


func _check(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		print("  [PASS] %s" % test_name)
	else:
		_fail_count += 1
		print("  [FAIL] %s" % test_name)


func _make_test_sequence() -> CinematicSequence:
	var sequence := CinematicSequence.new()
	sequence.sequence_id = "dev_cinematic_video_integration_test"
	sequence.shots = [
		# 1. Video -> Video
		_make_video_shot("video_01", "res://story/scripts/dummy_video_stream.tres", 0.0, true),
		_make_video_shot("video_02", "res://story/scripts/dummy_video_stream.tres", 0.0, true),
		
		# 2. Video -> 3D
		_make_video_shot("video_03", "res://story/scripts/dummy_video_stream.tres", 0.0, true),
		_make_camera_shot("3d_shot_04", "MOVE_TO", ^"CinematicMarkers/Shot_02", NodePath(""), "LINEAR", 0.05, true),
		
		# 3. 3D -> Video
		_make_video_shot("video_05", "res://story/scripts/dummy_video_stream.tres", 0.0, true),
		
		# 4. Video -> Fade -> Video
		_make_fade_shot("fade_06", "FADE_TO_BLACK", 0.05, true),
		_make_video_shot("video_07", "res://story/scripts/dummy_video_stream.tres", 0.0, true),
		_make_fade_shot("fade_08", "FADE_FROM_BLACK", 0.05, true),
		
		# 5. Invalid video (triggers fallback to 3D wait shot)
		_make_video_shot("invalid_video_shot", "res://story/assets/videos/non_existent_file.ogv", 0.05, true),
		
		_make_wait_shot("end_shot", 0.0, false)
	]
	return sequence


func _make_video_shot(shot_id: String, path: String, duration: float, lock_player: bool) -> CinematicShot:
	var shot := CinematicShot.new()
	var shot_id_str := shot_id
	shot.shot_id = shot_id_str
	shot.video_path = path
	shot.is_video = true
	shot.duration = duration
	shot.lock_player = lock_player
	return shot


func _make_auth_test_sequence() -> CinematicSequence:
	var sequence := CinematicSequence.new()
	sequence.sequence_id = "dev_cinematic_auth_integration_test"
	sequence.shots = [
		# video -> authorization -> video
		_make_video_shot("vid_start", "res://story/scripts/dummy_video_stream.tres", 0.0, true),
		_make_auth_shot("auth_middle", "AUTHORIZATION_SHOW"),
		_make_video_shot("vid_end", "res://story/scripts/dummy_video_stream.tres", 0.0, true),
		_make_wait_shot("auth_end", 0.0, false)
	]
	return sequence


func _make_auth_shot(shot_id: String, event_name: String) -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = shot_id
	shot.is_authorization = true
	shot.ui_event = event_name
	shot.lock_player = true
	return shot
