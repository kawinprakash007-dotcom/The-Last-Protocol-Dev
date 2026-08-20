extends Node

## Mission 01: RESTORE COMMUNICATION
## Narrative coordinator — layers story beats on existing GameState signals.
## Creates its own HUD (CanvasLayer) so no scene modifications are needed.

# UI references
var _canvas: CanvasLayer
var _objective_label: Label
var _log_container: VBoxContainer

# Failure UI references
var _failure_overlay: ColorRect
var _failure_title: Label
var _failure_subtitle: Label
var _is_failing: bool = false
var _is_final_objective_set: bool = false

func _ready() -> void:
	_create_hud()
	_connect_signals()
	
	_start_mission.call_deferred()

func _start_mission() -> void:
	# Wait until the main scene is loaded and the player is ready
	while not get_tree().get_first_node_in_group("player"):
		await get_tree().process_frame
		
	if CutsceneManager.has_method("play_cutscene"):
		CutsceneManager.play_cutscene("res://story/ui/story_intro.tscn")
		await CutsceneManager.cutscene_finished
		
	_boot_sequence()

# ── HUD Construction ──────────────────────────────────────────────

func _create_hud() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 10
	_canvas.name = "MissionHUD"
	add_child(_canvas)

	# Full-screen root that ignores mouse
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(root)

	# ── Objective (top-left) ──
	_objective_label = Label.new()
	_objective_label.name = "ObjectiveLabel"
	_objective_label.anchor_left = 0.0
	_objective_label.anchor_top = 0.0
	_objective_label.offset_left = 24
	_objective_label.offset_top = 24
	_objective_label.offset_right = 600
	_objective_label.offset_bottom = 60
	_objective_label.add_theme_font_size_override("font_size", 18)
	_objective_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.9))
	_objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_objective_label)

	# ── System log (bottom-left, grows upward) ──
	_log_container = VBoxContainer.new()
	_log_container.name = "SystemLog"
	_log_container.anchor_left = 0.0
	_log_container.anchor_right = 0.0
	_log_container.anchor_top = 1.0
	_log_container.anchor_bottom = 1.0
	_log_container.offset_left = 24
	_log_container.offset_right = 700
	_log_container.offset_top = -300
	_log_container.offset_bottom = -24
	_log_container.alignment = BoxContainer.ALIGNMENT_END
	_log_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_log_container)

	# ── Failure Overlay ──
	_failure_overlay = ColorRect.new()
	_failure_overlay.name = "FailureOverlay"
	_failure_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_failure_overlay.color = Color(0.0, 0.0, 0.0, 0.0) # Start transparent
	_failure_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_failure_overlay.visible = false
	root.add_child(_failure_overlay)

	var center_container := CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_failure_overlay.add_child(center_container)

	var failure_box := VBoxContainer.new()
	failure_box.alignment = BoxContainer.ALIGNMENT_CENTER
	failure_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_container.add_child(failure_box)

	_failure_title = Label.new()
	_failure_title.text = "MISSION FAILED"
	_failure_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_failure_title.add_theme_font_size_override("font_size", 36)
	_failure_title.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1, 1.0))
	_failure_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	failure_box.add_child(_failure_title)

	_failure_subtitle = Label.new()
	_failure_subtitle.text = "AUTONOMOUS UNIT NEUTRALIZED YOU"
	_failure_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_failure_subtitle.add_theme_font_size_override("font_size", 18)
	_failure_subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	_failure_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	failure_box.add_child(_failure_subtitle)

func trigger_player_caught() -> void:
	if _is_failing:
		return
	_is_failing = true
	
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player:
		player.is_control_disabled = true
		if "velocity" in player:
			player.velocity = Vector3.ZERO
			
	# Fade in failure screen
	_failure_overlay.visible = true
	var tween := create_tween()
	tween.tween_property(_failure_overlay, "color", Color(0.0, 0.0, 0.0, 0.85), 1.0)
	await tween.finished
	
	# Wait at full opacity
	await get_tree().create_timer(1.5).timeout
	
	# Teleport player to checkpoint
	if player and player.has_method("reset_to_position"):
		player.reset_to_position(Vector3(4.1, 1.0, 18.0), 0)
		
	# Reset security robots
	var robots = get_tree().get_nodes_in_group("security_robots")
	for robot in robots:
		if robot.has_method("reset_to_initial_state"):
			robot.reset_to_initial_state()
			
	# Fade out failure screen
	var tween_out := create_tween()
	tween_out.tween_property(_failure_overlay, "color", Color(0.0, 0.0, 0.0, 0.0), 1.0)
	await tween_out.finished
	_failure_overlay.visible = false
	
	if player:
		player.is_control_disabled = false
		
	_is_failing = false

# ── Signal Connections ────────────────────────────────────────────

func _connect_signals() -> void:
	GameState.terminal_online.connect(_on_terminal_online)
	GameState.entered_data_center.connect(_on_entered_data_center)
	GameState.relay_activated.connect(_on_relay_activated)
	GameState.power_puzzle_reset.connect(_on_puzzle_reset)
	GameState.power_system_online.connect(_on_power_online)
	GameState.security_threat_detected.connect(_on_security_threat_detected)
	GameState.comms_online.connect(_on_comms_online)
	GameState.shelter_lock_released.connect(_on_shelter_unlocked)
	GameState.survivors_rescued.connect(_on_survivors_rescued)
	GameState.robot_destroyed.connect(_on_robot_destroyed)
	GameState.last_protocol_accessed.connect(_on_last_protocol_accessed)
	GameState.last_protocol_activated.connect(_on_last_protocol_activated)

# ── Narrative Beats ───────────────────────────────────────────────

func _boot_sequence() -> void:
	if AudioManager.has_method("play_music"):
		AudioManager.play_music("music_main")
	await get_tree().create_timer(1.0).timeout
	_log("FACILITY OS v7.1 — EMERGENCY BOOT")
	await get_tree().create_timer(0.8).timeout
	_log("COMMS ARRAY: OFFLINE")
	await get_tree().create_timer(0.5).timeout
	_log("PRIMARY POWER: OFFLINE")
	await get_tree().create_timer(0.5).timeout
	_log("AUXILIARY TERMINAL DETECTED — SECTOR 01")
	_set_objective("RESTORE COMMUNICATIONS")

func _on_terminal_online() -> void:
	_log("AUX TERMINAL: ONLINE")
	await get_tree().create_timer(0.6).timeout
	_log("COMMS REQUIRE AUXILIARY POWER")
	await get_tree().create_timer(0.5).timeout
	_log("ROUTING TO DATA CENTER RELAYS...")
	_set_objective("ENTER DATA CENTER")

func _on_entered_data_center() -> void:
	_log("DATA CENTER: ACCESSED")
	await get_tree().create_timer(0.8).timeout
	_set_objective("RESTORE / REROUTE POWER")

func _on_security_threat_detected() -> void:
	_log("WARNING: AUTONOMOUS SECURITY UNIT ACTIVE")
	await get_tree().create_timer(0.5).timeout
	_set_objective("DISABLE SECURITY SYSTEM")

func _on_relay_activated(relay_index: int) -> void:
	var relay_names := ["ALPHA", "BETA", "GAMMA"]
	if relay_index >= 0 and relay_index < relay_names.size():
		_log("RELAY " + relay_names[relay_index] + ": ONLINE")

func _on_puzzle_reset() -> void:
	_log("SEQUENCE FAULT — RELAY GRID RESET")
	await get_tree().create_timer(0.5).timeout
	_log("RE-INITIALIZING...")

func _on_power_online() -> void:
	_log("AUXILIARY POWER: ONLINE")
	await get_tree().create_timer(1.0).timeout
	_log("COMMS ARRAY: POWERING UP...")
	await get_tree().create_timer(1.5).timeout
	_log("COMMUNICATION TERMINAL: ACTIVE")
	_set_objective("ACCESS COMMUNICATION TERMINAL")

func _on_comms_online() -> void:
	if AudioManager.has_method("play_music"):
		AudioManager.play_music("music_ruined_city")
	_log("SCANNING FREQUENCIES...")
	await get_tree().create_timer(1.5).timeout
	_log("SIGNAL DETECTED — ENCRYPTED CIVILIAN BAND")
	await get_tree().create_timer(1.0).timeout
	_log("DECRYPTING... COMPLETE")
	await get_tree().create_timer(1.0).timeout
	_log("SURVIVOR GROUP — SECTOR 04 — COORDINATES LOCKED")
	await get_tree().create_timer(1.5).timeout
	_log("WARNING: AUTONOMOUS SECURITY GRID ACTIVE")
	await get_tree().create_timer(0.8).timeout
	_log("HUMAN SIGNAL EMISSIONS BEING TRACKED")
	await get_tree().create_timer(1.0).timeout
	_set_objective("REACH SECTOR 04")

func _on_shelter_unlocked() -> void:
	if AudioManager.has_method("play_music"):
		AudioManager.play_music("music_shelter")
	_log("SHELTER 04 — SECURITY NODE DISABLED")
	await get_tree().create_timer(0.8).timeout
	_log("SHELTER 04 — ACCESS GRANTED")
	await get_tree().create_timer(0.5).timeout
	_set_objective("RESCUE THE SURVIVORS")

func _on_survivors_rescued() -> void:
	_log("SURVIVORS SECURED")
	await get_tree().create_timer(1.2).timeout
	_log("SURVIVOR: \"THE MACHINES AREN'T BROKEN.\"")
	await get_tree().create_timer(1.0).timeout
	_log("SURVIVOR: \"SOMETHING ELSE IS GIVING THEM ORDERS.\"")
	await get_tree().create_timer(1.5).timeout
	_log("SURVIVOR: \"YOU HAVE TO FIND THE CONTROL NETWORK.\"")
	await get_tree().create_timer(1.0).timeout
	if not _is_final_objective_set:
		_set_objective("FIND THE LAST PROTOCOL SWITCH")
		_is_final_objective_set = true

func _on_robot_destroyed() -> void:
	print("[MISSION] Combat encounter completed")
	_log("THREAT NEUTRALIZED.")
	await get_tree().create_timer(1.5).timeout
	print("[MISSION] Objective updated")
	_set_objective("REACH SECTOR 04")

func shelter_console_log(msg: String) -> void:
	_log(msg)

func _on_last_protocol_accessed() -> void:
	if AudioManager.has_method("play_music"):
		AudioManager.play_music("music_final")
	if not _is_final_objective_set:
		_set_objective("FIND THE LAST PROTOCOL SWITCH")
		_is_final_objective_set = true
	_log("SYSTEM OVERRIDE DETECTED...")
	await get_tree().create_timer(1.0).timeout
	_log("SECURITY PROTOCOL ACTIVATED. AWAITING INPUT.")

func _on_last_protocol_activated() -> void:
	_log("THE LAST PROTOCOL: EXECUTED")
	await get_tree().create_timer(1.5).timeout
	_log("OVERRIDING ALL CITY SYSTEMS...")
	
	# Shutdown robots safely
	var robots = get_tree().get_nodes_in_group("security_robots")
	for robot in robots:
		if robot.has_method("shutdown"):
			robot.shutdown()
			
	# Fade out environment lights
	var scene = get_tree().current_scene
	if scene:
		var all_nodes = scene.find_children("*", "Light3D", true, false)
		for light in all_nodes:
			if light is Light3D and not (light.name == "ShelterInteriorLight" or light.name == "ScanLight"):
				var tw = create_tween()
				tw.tween_property(light, "light_energy", 0.0, 3.0)
				
	if AudioManager.has_method("fade_music"):
		AudioManager.fade_music(4.0, 0.0)
				
	await get_tree().create_timer(4.0).timeout
	
	# Show ending UI
	_show_ending_ui()

func _show_ending_ui() -> void:
	if AudioManager.has_method("play_music"):
		AudioManager.play_music("music_ending")
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player:
		player.is_control_disabled = true
		
	var overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0)
	_canvas.add_child(overlay)
	
	var tw = create_tween()
	tw.tween_property(overlay, "color", Color(0, 0, 0, 1), 3.0)
	await tw.finished
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "THE LAST PROTOCOL EXECUTED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	title.custom_minimum_size = Vector2(900, 0)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = false
	vbox.add_child(title)
	
	var sub = Label.new()
	sub.text = "CITY SHUTDOWN COMPLETE"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 32)
	sub.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	sub.custom_minimum_size = Vector2(900, 0)
	sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	sub.clip_text = false
	vbox.add_child(sub)
	
	# Wait for player to read the ending text, then start the post-credit sequence
	await get_tree().create_timer(5.0).timeout
	if CutsceneManager.has_method("play_cutscene"):
		CutsceneManager.play_cutscene("res://post_credit/post_credit.tscn")

# ── HUD Utilities ─────────────────────────────────────────────────

func _log(text: String) -> void:
	print("[SYSTEM] ", text)
	var label := Label.new()
	label.text = "> " + text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.3, 0.95, 0.4, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log_container.add_child(label)

	# Fade out after 8 seconds, then free
	var tween := create_tween()
	tween.tween_interval(8.0)
	tween.tween_property(label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(label.queue_free)

	# Cap visible lines
	while _log_container.get_child_count() > 10:
		var old := _log_container.get_child(0)
		_log_container.remove_child(old)
		old.queue_free()

func _set_objective(text: String) -> void:
	_objective_label.text = "[ " + text + " ]"
	# Brief green highlight on update
	_objective_label.modulate = Color(0.4, 1.0, 0.6, 1.0)
	var tween := create_tween()
	tween.tween_property(_objective_label, "modulate", Color(1, 1, 1, 1), 1.5)
