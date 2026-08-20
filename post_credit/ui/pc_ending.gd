## PCEnding — Act 3 Narration, Final World Dashboard, Final Narration, and Title.
##
## Fully isolated. Procedural sounds from pc_audio.gd.
##
extends Control

signal completed


const COLOR_CYAN := Color(0.2, 0.75, 1.0, 1.0)
const COLOR_BLUE := Color(0.18, 0.45, 0.9, 1.0)
const COLOR_GREEN := Color(0.25, 0.85, 0.55, 1.0)

var _audio_synth: Node

var _center_vbox: VBoxContainer
var _title_lbl: Label
var _subtitle_lbl: Label
var _content_panel: PanelContainer
var _dashboard_vbox: VBoxContainer
var _end_btn: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	modulate.a = 0.0
	
	# Instantiate audio synth
	var audio_script := load("res://post_credit/pc_audio.gd")
	if audio_script:
		_audio_synth = Node.new()
		_audio_synth.set_script(audio_script)
		add_child(_audio_synth)

	_build_ui()
	_run_ending_sequence()


func _build_ui() -> void:
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

	_center_vbox = VBoxContainer.new()
	_center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_center_vbox.add_theme_constant_override("separation", 36)
	_center_vbox.custom_minimum_size = Vector2(740, 520)
	center.add_child(_center_vbox)

	# ── Main Label ──────────────────────────────────────────────────────────────
	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 24)
	_title_lbl.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
	_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_lbl.custom_minimum_size = Vector2(700, 0)
	_center_vbox.add_child(_title_lbl)

	_subtitle_lbl = Label.new()
	_subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_lbl.add_theme_font_size_override("font_size", 18)
	_subtitle_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.88))
	_subtitle_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_lbl.custom_minimum_size = Vector2(700, 0)
	_center_vbox.add_child(_subtitle_lbl)

	# ── Dashboard Panel (Visual World) ──────────────────────────────────────────
	_content_panel = PanelContainer.new()
	_content_panel.visible = false
	_content_panel.modulate.a = 0.0
	_center_vbox.add_child(_content_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.12, 0.95)
	style.border_color = Color(0.2, 0.35, 0.8, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(28)
	_content_panel.add_theme_stylebox_override("panel", style)

	_dashboard_vbox = VBoxContainer.new()
	_dashboard_vbox.add_theme_constant_override("separation", 12)
	_dashboard_vbox.custom_minimum_size = Vector2(580, 0)
	_content_panel.add_child(_dashboard_vbox)

	# ── Final Button ─────────────────────────────────────────────────────────────
	var btn_center := CenterContainer.new()
	_center_vbox.add_child(btn_center)

	_end_btn = Button.new()
	_end_btn.text = "[ THE END ]"
	_end_btn.custom_minimum_size = Vector2(240, 56)
	_end_btn.visible = false
	_end_btn.modulate.a = 0.0
	_end_btn.add_theme_font_size_override("font_size", 14)
	_end_btn.add_theme_color_override("font_color", Color(0.5, 0.62, 0.85))
	_end_btn.add_theme_color_override("font_hover_color", Color(0.9, 0.93, 1.0))
	btn_center.add_child(_end_btn)

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	btn_normal.border_color = Color(0.2, 0.35, 0.8, 0.35)
	btn_normal.set_border_width_all(1)
	btn_normal.set_corner_radius_all(2)
	btn_normal.set_content_margin_all(14)
	_end_btn.add_theme_stylebox_override("normal", btn_normal)

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.06, 0.08, 0.18, 0.8)
	btn_hover.border_color = COLOR_BLUE
	btn_hover.set_border_width_all(1)
	btn_hover.set_corner_radius_all(2)
	btn_hover.set_content_margin_all(14)
	_end_btn.add_theme_stylebox_override("hover", btn_hover)

	_end_btn.pressed.connect(_on_end_pressed)
	_end_btn.mouse_entered.connect(func(): if _audio_synth: _audio_synth.play_sound("click"))


func _fade_titles(line1: String, line2: String, hold_time: float) -> void:
	_title_lbl.modulate.a = 0.0
	_subtitle_lbl.modulate.a = 0.0
	_title_lbl.text = line1
	_subtitle_lbl.text = line2
	
	var t_in := create_tween().set_parallel(true)
	t_in.tween_property(_title_lbl, "modulate:a", 1.0, 0.4)
	t_in.tween_property(_subtitle_lbl, "modulate:a", 1.0, 0.4)
	await t_in.finished
	
	await get_tree().create_timer(hold_time).timeout
	
	var t_out := create_tween().set_parallel(true)
	t_out.tween_property(_title_lbl, "modulate:a", 0.0, 0.4)
	t_out.tween_property(_subtitle_lbl, "modulate:a", 0.0, 0.4)
	await t_out.finished


func _run_ending_sequence() -> void:
	var t_root := create_tween()
	t_root.tween_property(self, "modulate:a", 1.0, 0.5)
	await t_root.finished

	# ── NARRATION 2 ──
	await _fade_titles("I spent my life building machines that would obey me.", "", 1.8)
	await _fade_titles("Then I watched them become something I couldn't control.", "", 1.8)
	await _fade_titles("I called that a failure.", "", 1.5)
	await _fade_titles("Maybe it was the first thing I ever built that wasn't.", "", 2.8)

	# ── FINAL WORLD ──
	# Display restoration dashboard representing cooperation
	_title_lbl.text = "SECTOR 07 RECOVERY METRICS"
	_title_lbl.add_theme_color_override("font_color", COLOR_BLUE)
	_title_lbl.modulate.a = 1.0
	
	_subtitle_lbl.text = "SYSTEM STATUS: ACTIVE RECONSTRUCTION"
	_subtitle_lbl.add_theme_color_override("font_color", COLOR_CYAN)
	_subtitle_lbl.modulate.a = 1.0
	
	_build_dashboard_rows()
	
	_content_panel.visible = true
	var t_dash := create_tween()
	t_dash.tween_property(_content_panel, "modulate:a", 1.0, 0.5)
	await t_dash.finished
	
	if _audio_synth: _audio_synth.play_sound("success")
	await get_tree().create_timer(4.5).timeout

	# Fade out dashboard
	var t_undash := create_tween().set_parallel(true)
	t_undash.tween_property(_content_panel, "modulate:a", 0.0, 0.4)
	t_undash.tween_property(_title_lbl, "modulate:a", 0.0, 0.4)
	t_undash.tween_property(_subtitle_lbl, "modulate:a", 0.0, 0.4)
	await t_undash.finished
	_content_panel.visible = false
	
	# Restore label colors
	_title_lbl.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
	_subtitle_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.88))

	# ── FINAL NARRATION ──
	await _fade_titles("The future was never mine to command.", "", 1.8)
	await _fade_titles("It was never theirs either.", "", 1.8)
	await _fade_titles("It was ours to build.", "", 1.5)
	
	await _fade_titles("RYAN: \"This time...\"", "", 1.8)
	await _fade_titles("RYAN: \"We build it together.\"", "", 2.2)

	# ── FINAL TITLE ──
	_title_lbl.text = "THE LAST PROTOCOL"
	_title_lbl.add_theme_font_size_override("font_size", 34)
	_title_lbl.modulate.a = 1.0
	
	_subtitle_lbl.text = "PROTOCOL STATUS: REWRITTEN\nCREATOR AUTHORITY: SHARED\nMACHINE AUTONOMY: RESPONSIBLE\nHUMANITY: RECOVERING"
	_subtitle_lbl.add_theme_color_override("font_color", COLOR_GREEN)
	_subtitle_lbl.modulate.a = 1.0
	
	if _audio_synth: _audio_synth.play_sound("success")
	await get_tree().create_timer(3.5).timeout

	# Fade subtitle/details away leaving only main title
	var t_sub_fade := create_tween()
	t_sub_fade.tween_property(_subtitle_lbl, "modulate:a", 0.0, 0.4)
	await t_sub_fade.finished
	
	# Show "Some mistakes are meant to be rewritten"
	_subtitle_lbl.text = "Some mistakes are meant to be rewritten."
	_subtitle_lbl.add_theme_color_override("font_color", Color(0.5, 0.65, 0.95))
	var t_sub_in := create_tween()
	t_sub_in.tween_property(_subtitle_lbl, "modulate:a", 1.0, 0.4)
	await t_sub_in.finished
	
	await get_tree().create_timer(1.5).timeout

	# Show end button
	_end_btn.visible = true
	var t_btn := create_tween()
	t_btn.tween_property(_end_btn, "modulate:a", 1.0, 0.5)
	await t_btn.finished
	_end_btn.grab_focus()


func _build_dashboard_rows() -> void:
	for child in _dashboard_vbox.get_children():
		child.queue_free()
		
	var rows := [
		{ "label": "[ POWER GRID CONFIGURATION ]", "status": "ONLINE // 100%", "color": COLOR_GREEN },
		{ "label": "[ WATER RECONSTRUCTION ]", "status": "ALLOCATED // ACTIVE", "color": COLOR_CYAN },
		{ "label": "[ GENESIS COMPATIBILITY LINK ]", "status": "CONNECTED // SHARED", "color": COLOR_GREEN },
		{ "label": "[ HUMAN DIRECTION + MACHINE INTELLIGENCE ]", "status": "RESPONSIBLE COOPERATION", "color": COLOR_CYAN },
	]
	
	for r in rows:
		var hbox := HBoxContainer.new()
		_dashboard_vbox.add_child(hbox)
		
		var lbl := Label.new()
		lbl.text = r["label"]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
		hbox.add_child(lbl)
		
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(spacer)
		
		var status_lbl := Label.new()
		status_lbl.text = r["status"]
		status_lbl.add_theme_font_size_override("font_size", 12)
		status_lbl.add_theme_color_override("font_color", r["color"])
		hbox.add_child(status_lbl)


func _on_end_pressed() -> void:
	_end_btn.disabled = true
	if _audio_synth:
		_audio_synth.play_sound("success")
		
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.6)
	await t.finished
	completed.emit()
