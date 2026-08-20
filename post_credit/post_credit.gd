## PostCredit ─ Isolated post-credit epilogue controller.
##
## Standalone module. Zero dependencies on res://story/.
## Press F6 in Godot to run independently for development.
##
extends Control


# ── Video paths ────────────────────────────────────────────────────────────────
const PC01_OGV := "res://post_credit/videos/PC01_RYAN_REALIZATION.ogv"
const PC02_OGV := "res://post_credit/videos/PC02_REBUILD.ogv"

# ── UI scene paths ─────────────────────────────────────────────────────────────
const SCENE_INTERACTIVE := "res://post_credit/ui/pc_interactive_prompt.tscn"
const SCENE_REBUILD     := "res://post_credit/ui/pc_rebuild_task.tscn"
const SCENE_ENDING      := "res://post_credit/ui/pc_ending.tscn"

# ── Phase tracking ─────────────────────────────────────────────────────────────
enum Phase { IDLE, INTRO, PC01, INTERACTIVE, PC02, REBUILD, ENDING, DONE }
var _phase := Phase.IDLE

# ── Active UI ref (set when loading interactive/rebuild/ending scenes) ─────────
var _active_ui: Control = null

# ── Space-to-continue flag (for video placeholders) ───────────────────────────
var _waiting_for_space := false

# ── Node references ────────────────────────────────────────────────────────────
@onready var _video_player: VideoStreamPlayer = $VideoLayer/VideoPlayer
@onready var _ui_layer:     CanvasLayer       = $UILayer
@onready var _fade:         Control           = $FadeLayer/PCFade


func _ready() -> void:
	_video_player.visible = false
	_video_player.modulate.a = 0.0
	_resize_video_player()
	get_tree().root.size_changed.connect(_resize_video_player)
	await get_tree().process_frame
	
	if OS.get_environment("AUTOMATE_TEST") == "true":
		var automator_script := load("res://post_credit/post_credit_automation.gd")
		if automator_script:
			var automator := Node.new()
			automator.set_script(automator_script)
			add_child(automator)
			
	_run_sequence()


func _resize_video_player() -> void:
	var size := get_viewport().get_visible_rect().size
	_video_player.offset_left   = 0.0
	_video_player.offset_top    = 0.0
	_video_player.offset_right  = size.x
	_video_player.offset_bottom = size.y


# ── State Machine Transitions ──────────────────────────────────────────────────

func _run_sequence() -> void:
	await _black()
	_phase = Phase.INTRO
	print("[PC] PHASE = INTRO")
	print_diagnostics()
	await _show_intro()
	_run_pc01()


func _run_pc01() -> void:
	_phase = Phase.PC01
	print("[PC] PC01 PLAY")
	print_diagnostics()
	
	await _play_or_placeholder(
		PC01_OGV,
		"PC01 — RYAN REALIZATION",
		"Before the world could forgive him...\nRyan had to forgive himself."
	)
	print("[PC] PC01 FINISHED")
	_run_choice()


func _run_choice() -> void:
	_phase = Phase.INTERACTIVE
	print("[PC] SHOW CHOICE")
	
	# Clean video player
	_video_player.stop()
	_video_player.visible = false
	_video_player.stream = null
	
	# Clear/Hide FadeLayer
	_fade.instant_clear()
	var fade_layer = get_node_or_null("FadeLayer")
	if fade_layer:
		fade_layer.visible = false
		
	# Show VideoLayer and UILayer
	var video_layer = get_node_or_null("VideoLayer")
	if video_layer:
		video_layer.visible = true
	_ui_layer.visible = true
	
	# Load interactive choice UI
	_load_ui(SCENE_INTERACTIVE)
	if _active_ui:
		_active_ui.visible = true
		_active_ui.modulate.a = 1.0
		_active_ui.move_to_front()
		
		# Grab focus on first button
		var btn_row = _active_ui.find_child("ButtonRow", true, false)
		if btn_row and btn_row.get_child_count() > 0:
			var first_btn = btn_row.get_child(0) as Button
			if first_btn:
				first_btn.grab_focus()
				
		# Connect selection
		_active_ui.completed.connect(func(choice: String):
			if choice == "build_with_them":
				select_build_with_them()
		)
		
	print("[PC] CHOICE READY")
	print_diagnostics()


func select_build_with_them() -> void:
	print("[PC] BUILD_WITH_THEM CLICKED")
	_clear_ui()
	_run_pc02()


func _run_pc02() -> void:
	_phase = Phase.PC02
	print("[PC] PC02 PLAY")
	
	# Hide all UI & Fade elements completely before PC02 starts
	_clear_ui()
	var fade_layer = get_node_or_null("FadeLayer")
	if fade_layer:
		fade_layer.visible = false
		
	# Ensure VideoLayer and Player are active
	var video_layer = get_node_or_null("VideoLayer")
	if video_layer:
		video_layer.visible = true
	_video_player.visible = true
	
	# Check PC02 existence
	var pc02_exists = ResourceLoader.exists(PC02_OGV)
	print("[PC] PC02 RESOURCE EXISTS = ", pc02_exists)
	print_diagnostics()
	
	if pc02_exists:
		var stream = load(PC02_OGV)
		print("[PC] PC02 STREAM NULL = ", stream == null)
		
		_video_player.stream = stream
		_video_player.visible = true
		_video_player.modulate.a = 1.0
		_video_player.play()
		
		# Wait for video to finish naturally with safety timeout fallback
		var duration := _video_player.get_stream_length()
		if duration <= 0.0:
			duration = 10.01
			
		var timer := get_tree().create_timer(duration + 1.5)
		var video_done := false
		var on_finished := func():
			video_done = true
			
		_video_player.finished.connect(on_finished, CONNECT_ONE_SHOT)
		
		while not video_done and timer.time_left > 0.0:
			await get_tree().process_frame
			
		if _video_player.finished.is_connected(on_finished):
			_video_player.finished.disconnect(on_finished)
			
		_video_player.stop()
		_video_player.stream = null
		_video_player.visible = false
	else:
		# Fallback placeholder
		await _show_placeholder("PC02 — REBUILD", "He returned to the lab.\nNot to build machines.\nBut to rebuild trust.")
		
	print("[PC] PC02 FINISHED")
	_run_rebuild_task()


func _run_rebuild_task() -> void:
	_phase = Phase.REBUILD
	print("[PC] SHOW REBUILD TASK")
	
	# Clean video player
	_video_player.stop()
	_video_player.visible = false
	
	# Load rebuild task
	_load_ui(SCENE_REBUILD)
	if _active_ui:
		_active_ui.visible = true
		_active_ui.modulate.a = 1.0
		_active_ui.move_to_front()
		
		# Connect completed signal
		_active_ui.completed.connect(func():
			print("[PC] REBUILD COMPLETE")
			_clear_ui()
			_run_ending()
		)
		
	print_diagnostics()


func _run_ending() -> void:
	_phase = Phase.ENDING
	print("[PC] SHOW ENDING")
	
	# Load ending
	_load_ui(SCENE_ENDING)
	if _active_ui:
		_active_ui.visible = true
		_active_ui.modulate.a = 1.0
		_active_ui.move_to_front()
		
		# Connect completed signal
		_active_ui.completed.connect(func():
			print("[PC] END")
			_run_done()
		)
		
	print_diagnostics()


func _run_done() -> void:
	_phase = Phase.DONE
	await _black()
	_clear_ui()
	print("PostCredit: sequence complete.")


# ── Video Playback Helpers ─────────────────────────────────────────────────────

func _play_or_placeholder(path: String, label: String, fallback_text: String) -> void:
	if ResourceLoader.exists(path):
		await _play_video(path)
	else:
		push_warning("PostCredit: video not found — '%s'. Showing placeholder." % path)
		await _show_placeholder(label, fallback_text)


func _play_video(path: String) -> void:
	var stream = load(path)
	if stream == null:
		push_error("PostCredit: Failed to load video stream: " + path)
		return
	_video_player.stream = stream
	_video_player.visible = true
	_video_player.modulate.a = 0.0
	_video_player.play()
	await _reveal()
	var t_in := create_tween()
	t_in.tween_property(_video_player, "modulate:a", 1.0, 0.5)
	await t_in.finished
	
	# Wait for video to finish naturally with safety timeout fallback
	var duration := _video_player.get_stream_length()
	if duration <= 0.0:
		duration = 10.01
		
	var timer := get_tree().create_timer(duration + 1.5)
	var video_done := false
	var on_finished := func():
		video_done = true
		
	_video_player.finished.connect(on_finished, CONNECT_ONE_SHOT)
	
	while not video_done and timer.time_left > 0.0:
		await get_tree().process_frame
		
	if _video_player.finished.is_connected(on_finished):
		_video_player.finished.disconnect(on_finished)
		
	var t_out := create_tween()
	t_out.tween_property(_video_player, "modulate:a", 0.0, 0.5)
	await t_out.finished
	await _black()
	_video_player.stop()
	_video_player.stream = null
	_video_player.visible = false


func _show_placeholder(label: String, text: String) -> void:
	var ph := _build_placeholder_ui(label, text)
	_ui_layer.add_child(ph)
	await _reveal()
	await _wait_for_space()
	await _black()
	ph.queue_free()


func _build_placeholder_ui(label: String, text: String) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.035, 0.035, 0.06, 1.0)
	root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 28)
	center.add_child(vbox)

	var items: Array[Dictionary] = [
		{ "t": "[ VIDEO NOT YET PLACED ]",     "sz": 11, "c": Color(0.30, 0.55, 1.00, 0.55) },
		{ "t": label,                           "sz": 28, "c": Color(0.88, 0.92, 1.00) },
		{ "t": text,                            "sz": 17, "c": Color(0.62, 0.68, 0.82) },
		{ "t": "— PRESS SPACE TO CONTINUE —",  "sz": 11, "c": Color(0.35, 0.42, 0.58, 0.65) },
	]
	for item in items:
		var lbl := Label.new()
		lbl.text = item["t"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", item["sz"])
		lbl.add_theme_color_override("font_color", item["c"])
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(700, 0)
		vbox.add_child(lbl)

	return root


func _show_intro() -> void:
	var intro := Control.new()
	intro.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.04, 1.0)
	intro.add_child(bg)
	
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro.add_child(center)
	
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)
	
	var status_lbl := Label.new()
	status_lbl.text = "[ SECURE DATA DECRYPTION INITIALIZED ]"
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 11)
	status_lbl.add_theme_color_override("font_color", Color(0.18, 0.45, 0.85, 0.65))
	vbox.add_child(status_lbl)
	
	var title_lbl := Label.new()
	title_lbl.text = "EPILOGUE"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 32)
	title_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
	vbox.add_child(title_lbl)
	
	var sub_lbl := Label.new()
	sub_lbl.text = "Sector 7 Laboratory Ruins — One Year Later"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 14)
	sub_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.72))
	vbox.add_child(sub_lbl)
	
	_ui_layer.add_child(intro)
	intro.modulate.a = 0.0
	
	# Screen is already black, fade in intro info
	var t_in := create_tween()
	t_in.tween_property(intro, "modulate:a", 1.0, 1.0)
	await t_in.finished
	
	await get_tree().create_timer(3.0).timeout
	
	var t_out := create_tween()
	t_out.tween_property(intro, "modulate:a", 0.0, 1.0)
	await t_out.finished
	
	intro.queue_free()


# ── Input ──────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _waiting_for_space:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
				_waiting_for_space = false
				get_viewport().set_input_as_handled()


func _wait_for_space() -> void:
	_waiting_for_space = true
	while _waiting_for_space:
		await get_tree().process_frame


# ── Fade Helpers ───────────────────────────────────────────────────────────────

func _black() -> void:
	if _fade != null and _fade.has_method("fade_out"):
		await _fade.fade_out()


func _reveal() -> void:
	if _fade != null and _fade.has_method("fade_in"):
		await _fade.fade_in()


# ── UI Helpers ─────────────────────────────────────────────────────────────────

func _load_ui(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_error("PostCredit: UI scene not found: " + scene_path)
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("PostCredit: Cannot instantiate scene: " + scene_path)
		return
	_active_ui = packed.instantiate() as Control
	_ui_layer.add_child(_active_ui)


func _clear_ui() -> void:
	if _active_ui != null and is_instance_valid(_active_ui):
		_active_ui.queue_free()
	_active_ui = null


# ── Diagnostic Print Utility ───────────────────────────────────────────────────

func print_diagnostics() -> void:
	print("================= POST-CREDIT DIAGNOSTICS =================")
	_print_node_state(_video_player, "VideoPlayer")
	
	var fade_rect = get_node_or_null("FadeLayer/PCFade")
	_print_node_state(fade_rect, "FadeRect")
	
	var fade_layer = get_node_or_null("FadeLayer")
	_print_node_state(fade_layer, "FadeLayer")
	
	if _active_ui:
		_print_node_state(_active_ui, "ActiveUI (" + _active_ui.name + ")")
		for child in _active_ui.get_children():
			_print_node_state(child, "  -> Child: " + child.name)
	else:
		print("ActiveUI: null")
	print("===========================================================")


func _print_node_state(node: Node, label: String) -> void:
	if node == null:
		print(label, ": null")
		return
		
	var is_visible = node.get("visible") if "visible" in node else "n/a"
	var modulate_val = node.get("modulate") if "modulate" in node else "n/a"
	var z_index_val = node.get("z_index") if "z_index" in node else "n/a"
	var canvas_layer_val = "n/a"
	if node is CanvasLayer:
		canvas_layer_val = node.layer
	elif node.get_parent() is CanvasLayer:
		canvas_layer_val = node.get_parent().layer
		
	var size_val = node.get("size") if "size" in node else "n/a"
	var position_val = node.get("position") if "position" in node else "n/a"
	
	print(label, " - Visible: ", is_visible, ", Modulate: ", modulate_val, ", Z-Index: ", z_index_val, ", CanvasLayer: ", canvas_layer_val, ", Size: ", size_val, ", Position: ", position_val)
