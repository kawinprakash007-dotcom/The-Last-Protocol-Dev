## PCRebuildTask — Act 2 Mini-Interactions and Dialogue Moment.
##
## Fully isolated. Procedural sounds from pc_audio.gd.
##
extends Control

signal completed


const COLOR_CYAN := Color(0.2, 0.75, 1.0, 1.0)
const COLOR_BLUE := Color(0.18, 0.45, 0.9, 1.0)
const COLOR_GREEN := Color(0.25, 0.85, 0.55, 1.0)
const COLOR_RED := Color(0.95, 0.35, 0.35, 1.0)

var _audio_synth: Node

# UI containers
var _game_vbox: VBoxContainer
var _title_lbl: Label
var _subtitle_lbl: Label
var _task_area: CenterContainer

# Power Grid state
var _power_nodes: Array[Button] = []
var _power_connections: Array[bool] = [false, false, false, false]
var _power_labels := ["POWER CORE", "NODE A", "NODE B", "CITY GRID"]

# Structural Rebuild state
var _struct_buttons: Array[Button] = []
var _struct_order: Array[String] = []
var _struct_labels := ["FOUNDATION", "SUPPORT", "ENERGY CORE"]

# Funny Robot Moment state
var _funny_step := 0
var _funny_continue_btn: Button

# City Restoration state
var _city_buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	modulate.a = 0.0
	
	# Instantiate audio synth
	var audio_script := load("res://post_credit/pc_audio.gd")
	if audio_script:
		_audio_synth = Node.new()
		_audio_synth.set_script(audio_script)
		add_child(_audio_synth)

	_build_ui_layout()
	_start_power_grid_task()


func _build_ui_layout() -> void:
	# ── Background ──────────────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.04, 1.0)
	add_child(bg)

	# ── Grid lines ──────────────────────────────────────────────────────────────
	var grid := ColorRect.new()
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid.color = Color(0.05, 0.1, 0.3, 0.015)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grid)

	# ── Center Area ─────────────────────────────────────────────────────────────
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_game_vbox = VBoxContainer.new()
	_game_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_game_vbox.add_theme_constant_override("separation", 36)
	_game_vbox.custom_minimum_size = Vector2(740, 480)
	center.add_child(_game_vbox)

	# ── Headers ─────────────────────────────────────────────────────────────────
	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 14)
	_title_lbl.add_theme_color_override("font_color", COLOR_BLUE)
	_game_vbox.add_child(_title_lbl)

	_subtitle_lbl = Label.new()
	_subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_lbl.add_theme_font_size_override("font_size", 22)
	_subtitle_lbl.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
	_subtitle_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_lbl.custom_minimum_size = Vector2(680, 0)
	_game_vbox.add_child(_subtitle_lbl)

	# ── Custom Task Area ────────────────────────────────────────────────────────
	_task_area = CenterContainer.new()
	_game_vbox.add_child(_task_area)


func _clear_task_area() -> void:
	for child in _task_area.get_children():
		child.queue_free()


func _build_premium_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.12, 0.95)
	style.border_color = Color(0.2, 0.35, 0.8, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _build_flat_button(btn_text: String) -> Button:
	var btn := Button.new()
	btn.text = btn_text
	btn.custom_minimum_size = Vector2(180, 56)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.1, 0.2, 0.9)
	normal.border_color = Color(0.2, 0.35, 0.8, 0.4)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	normal.set_content_margin_all(14)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.12, 0.18, 0.36, 0.95)
	hover.border_color = COLOR_BLUE
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(3)
	hover.set_content_margin_all(14)
	btn.add_theme_stylebox_override("hover", hover)
	
	btn.mouse_entered.connect(func(): if _audio_synth: _audio_synth.play_sound("click"))
	return btn


# ── INTERACTION 1: Power Grid ─────────────────────────────────────────────────

func _start_power_grid_task() -> void:
	# Fade in self root
	var t_root := create_tween()
	t_root.tween_property(self, "modulate:a", 1.0, 0.5)
	await t_root.finished

	_title_lbl.text = "POWER GRID // SECTOR 07"
	_subtitle_lbl.text = "Reconstruction requires power. Connect the grid nodes."
	_clear_task_area()

	var panel := _build_premium_panel()
	_task_area.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	panel.add_child(hbox)

	_power_nodes.clear()
	_power_connections = [false, false, false, false]

	for i in range(4):
		var btn := _build_flat_button(_power_labels[i])
		hbox.add_child(btn)
		_power_nodes.append(btn)
		
		# Connect press event
		btn.pressed.connect(func(): _on_power_node_clicked(i))
		
		if i > 0:
			var arrow := Label.new()
			arrow.text = "  →  "
			arrow.add_theme_color_override("font_color", Color(0.3, 0.45, 0.7, 0.5))
			hbox.add_child(arrow)
			# Move arrow to correct index before button
			hbox.move_child(arrow, hbox.get_child_count() - 2)

	_update_power_nodes_visuals()


func _update_power_nodes_visuals() -> void:
	for i in range(4):
		var btn := _power_nodes[i]
		var style := btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		
		if _power_connections[i]:
			style.bg_color = Color(0.1, 0.35, 0.25, 0.95)
			style.border_color = COLOR_GREEN
			btn.add_theme_color_override("font_color", COLOR_GREEN)
		else:
			style.bg_color = Color(0.08, 0.1, 0.2, 0.9)
			style.border_color = Color(0.2, 0.35, 0.8, 0.4)
			btn.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
			
		btn.add_theme_stylebox_override("normal", style)


func _on_power_node_clicked(index: int) -> void:
	# Verify that nodes are connected in sequence: 0 -> 1 -> 2 -> 3
	if index == 0 or _power_connections[index - 1]:
		if not _power_connections[index]:
			_power_connections[index] = true
			_update_power_nodes_visuals()
			
			if index == 3:
				# Complete
				_on_power_grid_complete()
			else:
				if _audio_synth:
					_audio_synth.play_sound("click")
	else:
		# Wrong click order, play buzz
		if _audio_synth:
			_audio_synth.play_sound("electric")


func _on_power_grid_complete() -> void:
	print("[PC] REBUILD STEP = 1")
	if _audio_synth:
		_audio_synth.play_sound("success")
		_audio_synth.play_sound("electric")
		
	# Disable all power buttons
	for btn in _power_nodes:
		btn.disabled = true

	_subtitle_lbl.text = "POWER GRID ONLINE\nSECTOR 07 RECONNECTED"
	_subtitle_lbl.add_theme_color_override("font_color", COLOR_GREEN)

	await get_tree().create_timer(2.0).timeout
	
	# Narration
	_subtitle_lbl.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
	_subtitle_lbl.text = "RYAN: \"One system at a time.\""
	_clear_task_area()
	
	await get_tree().create_timer(2.5).timeout
	_start_structural_rebuild_task()


# ── INTERACTION 2: Structural Rebuild ─────────────────────────────────────────

func _start_structural_rebuild_task() -> void:
	_title_lbl.text = "RECONSTRUCTION FRAME"
	_subtitle_lbl.text = "Integrate components in correct logical order."
	_clear_task_area()

	var panel := _build_premium_panel()
	_task_area.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	panel.add_child(hbox)

	_struct_buttons.clear()
	_struct_order.clear()

	# Create the three components shuffled or placed in order
	for label in _struct_labels:
		var btn := _build_flat_button(label)
		hbox.add_child(btn)
		_struct_buttons.append(btn)
		
		# Connect click
		btn.pressed.connect(func(): _on_struct_clicked(btn, label))


func _on_struct_clicked(btn: Button, label: String) -> void:
	if label in _struct_order:
		return # Already added
		
	_struct_order.append(label)
	
	# Visual indication of selection
	var style := btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	style.bg_color = Color(0.15, 0.25, 0.45, 0.95)
	style.border_color = COLOR_CYAN
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", COLOR_CYAN)
	
	if _audio_synth:
		_audio_synth.play_sound("clink")

	# Check progress
	if _struct_order.size() == 3:
		# Check logical order: FOUNDATION (0), SUPPORT (1), ENERGY CORE (2)
		if _struct_order[0] == "FOUNDATION" and _struct_order[1] == "SUPPORT" and _struct_order[2] == "ENERGY CORE":
			_on_structural_complete()
		else:
			# Failed order, reset
			_struct_order.clear()
			if _audio_synth:
				_audio_synth.play_sound("electric")
			await get_tree().create_timer(0.6).timeout
			_start_structural_rebuild_task()


func _on_structural_complete() -> void:
	print("[PC] REBUILD STEP = 2")
	if _audio_synth:
		_audio_synth.play_sound("success")
		
	for btn in _struct_buttons:
		btn.disabled = true
		var style := btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		style.bg_color = Color(0.1, 0.35, 0.25, 0.95)
		style.border_color = COLOR_GREEN
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_color_override("font_color", COLOR_GREEN)

	_subtitle_lbl.text = "STRUCTURE STABLE"
	_subtitle_lbl.add_theme_color_override("font_color", COLOR_GREEN)
	await get_tree().create_timer(1.8).timeout

	# Dialogue
	_subtitle_lbl.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
	_subtitle_lbl.text = "ROBOT: \"Structural integrity restored.\""
	if _audio_synth: _audio_synth.play_sound("servo")
	await get_tree().create_timer(1.6).timeout

	_subtitle_lbl.text = "RYAN: \"See?\""
	await get_tree().create_timer(1.2).timeout

	_subtitle_lbl.text = "RYAN: \"You're getting better.\""
	await get_tree().create_timer(2.0).timeout
	
	_run_funny_robot_moment()


# ── ACT 3: Funny Robot Moment ─────────────────────────────────────────────────

func _run_funny_robot_moment() -> void:
	print("[PC] REBUILD STEP = 3")
	_title_lbl.text = "INTELLIGENCE BRIDGE // DIALOGUE"
	_subtitle_lbl.text = ""
	_clear_task_area()

	var panel := _build_premium_panel()
	_task_area.add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var dialog_lbl := Label.new()
	dialog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_lbl.add_theme_font_size_override("font_size", 20)
	dialog_lbl.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
	dialog_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_lbl.custom_minimum_size = Vector2(580, 80)
	vbox.add_child(dialog_lbl)

	_funny_continue_btn = _build_flat_button("[ CONTINUE ]")
	vbox.add_child(_funny_continue_btn)

	_funny_step = 0
	_funny_continue_btn.pressed.connect(func(): _on_funny_dialogue_advanced(dialog_lbl))
	_on_funny_dialogue_advanced(dialog_lbl)


func _on_funny_dialogue_advanced(label: Label) -> void:
	if _audio_synth:
		_audio_synth.play_sound("click")
		
	_funny_step += 1
	
	if _funny_step == 1:
		label.text = "RYAN:\n\"Okay. Don't destroy anything this time.\""
		label.add_theme_color_override("font_color", COLOR_BLUE)
	elif _funny_step == 2:
		label.text = "ROBOT:\n\"Define destroy.\""
		label.add_theme_color_override("font_color", COLOR_CYAN)
		if _audio_synth:
			_audio_synth.play_sound("servo")
	elif _funny_step == 3:
		label.text = "RYAN:\n\"...You know what?\""
		label.add_theme_color_override("font_color", COLOR_BLUE)
	elif _funny_step == 4:
		label.text = "RYAN:\n\"Never mind.\""
		label.add_theme_color_override("font_color", COLOR_BLUE)
	elif _funny_step == 5:
		label.text = "ROBOT:\n\"Understood.\""
		label.add_theme_color_override("font_color", COLOR_CYAN)
		if _audio_synth:
			_audio_synth.play_sound("servo")
	else:
		_funny_continue_btn.disabled = true
		_start_city_restoration_task()


# ── INTERACTION 3: Restore the City ───────────────────────────────────────────

func _start_city_restoration_task() -> void:
	print("[PC] REBUILD STEP = 4")
	_title_lbl.text = "CITY RESTORATION PRIORITY"
	_subtitle_lbl.text = "Select immediate infrastructure priority allocation."
	_clear_task_area()

	var panel := _build_premium_panel()
	_task_area.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	panel.add_child(hbox)

	_city_buttons.clear()

	var priorities := ["WATER", "TRANSPORT", "COMMUNICATION"]
	for pr in priorities:
		var btn := _build_flat_button(pr)
		hbox.add_child(btn)
		_city_buttons.append(btn)
		btn.pressed.connect(func(): _on_city_priority_selected(pr))


func _on_city_priority_selected(priority: String) -> void:
	if _audio_synth:
		_audio_synth.play_sound("success")
		
	for btn in _city_buttons:
		btn.disabled = true
		if btn.text == priority:
			var style := btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			style.bg_color = Color(0.1, 0.35, 0.25, 0.95)
			style.border_color = COLOR_GREEN
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_color_override("font_color", COLOR_GREEN)

	# Show dialogue response based on choice
	_subtitle_lbl.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
	if priority == "WATER":
		_subtitle_lbl.text = "RYAN: \"People need water first.\""
	elif priority == "TRANSPORT":
		_subtitle_lbl.text = "RYAN: \"People need to move again.\""
	elif priority == "COMMUNICATION":
		_subtitle_lbl.text = "RYAN: \"Let people find each other again.\""
		
	await get_tree().create_timer(2.2).timeout

	_subtitle_lbl.add_theme_color_override("font_color", COLOR_GREEN)
	_subtitle_lbl.text = "SYSTEM: RESTORATION PRIORITY ACCEPTED"
	await get_tree().create_timer(2.5).timeout

	# Transition complete
	var t_fade := create_tween()
	t_fade.tween_property(self, "modulate:a", 0.0, 0.5)
	await t_fade.finished
	completed.emit()
