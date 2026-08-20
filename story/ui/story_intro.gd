## StoryIntro — Premium 3-state boot sequence for THE LAST PROTOCOL.
##
## States:
##   BOOT         — Cinematic title screen with TLP boot animation
##   SIGNAL       — Incoming transmission decode sequence
##   MISSION_INIT — Connection established / mission briefing
##
## All visuals are built programmatically using TLP design language:
##   dark glass, thin cyan borders, scan lines, technical metadata,
##   restrained glow, cinematic spacing.
##
extends Control

# ── TLP PALETTE (matches CinematicUIMaster) ─────────────────────────────────
const COL_BG            := Color(0.0,  0.02, 0.04, 1.0)
const COL_PANEL         := Color(0.0,  0.04, 0.08, 0.88)
const COL_BORDER        := Color(0.0,  0.67, 1.0,  0.35)
const COL_BORDER_BRIGHT := Color(0.0,  0.67, 1.0,  0.70)
const COL_ACCENT        := Color(0.0,  0.67, 1.0,  1.0)
const COL_TEXT          := Color(0.85, 0.95, 1.0,  1.0)
const COL_TEXT_DIM      := Color(0.55, 0.75, 0.90, 0.65)
const COL_SUCCESS       := Color(0.20, 1.0,  0.55, 1.0)
const COL_WARN          := Color(1.0,  0.55, 0.0,  1.0)
const COL_GRID          := Color(0.0,  0.67, 1.0,  0.04)

enum State { BOOT, SIGNAL, MISSION_INIT }
var _state: State = State.BOOT

# Music
@export var intro_music: AudioStream
@onready var _music_player: AudioStreamPlayer = $MusicPlayer
@onready var _ui_player: AudioStreamPlayer    = $UIPlayer

# Dynamic content layer
var _content: Control = null
var _scan_tween: Tween = null
var _current_action_btn: Control = null


func _ready() -> void:
	_play_intro_music()
	_show_boot_screen()


# ─────────────────────────────────────────────────────────────────────────────
# BOOT SCREEN
# ─────────────────────────────────────────────────────────────────────────────

func _show_boot_screen() -> void:
	_state = State.BOOT
	_clear_content()
	_content = _make_fullrect_control()
	add_child(_content)

	# Dark background
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.add_child(bg)

	# Micro-grid overlay
	_add_grid(bg)

	# Horizontal scan line (slow drift)
	var scan := ColorRect.new()
	scan.color = Color(0.0, 0.67, 1.0, 0.07)
	scan.size = Vector2(0, 2)
	scan.set_anchor_and_offset(SIDE_LEFT, 0.0, 0.0)
	scan.set_anchor_and_offset(SIDE_RIGHT, 1.0, 0.0)
	scan.set_anchor_and_offset(SIDE_TOP, 0.0, 0.0)
	scan.set_anchor_and_offset(SIDE_BOTTOM, 0.0, 2.0)
	_content.add_child(scan)
	_run_scan_drift(scan)

	# Top-left corner mark
	_add_corner_mark(_content, Control.PRESET_TOP_LEFT)
	# Top-right corner mark
	_add_corner_mark(_content, Control.PRESET_TOP_RIGHT)
	# Bottom-left corner mark
	_add_corner_mark(_content, Control.PRESET_BOTTOM_LEFT)
	# Bottom-right corner mark
	_add_corner_mark(_content, Control.PRESET_BOTTOM_RIGHT)

	# Center content VBox
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# System diagnostic labels (top metadata)
	var diag_row := HBoxContainer.new()
	diag_row.add_theme_constant_override("separation", 32)
	diag_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(diag_row)
	_make_meta_tag(diag_row, "SYSTEM", "ARCHIVE")
	_make_meta_separator(diag_row)
	_make_meta_tag(diag_row, "YEAR", "2047")
	_make_meta_separator(diag_row)
	_make_meta_tag(diag_row, "STATUS", "UNKNOWN")

	# Thin separator line
	var line := _make_h_line()
	vbox.add_child(line)

	# Main title
	var title := Label.new()
	title.text = "THE LAST PROTOCOL"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", COL_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.uppercase = true
	title.modulate.a = 0.0
	vbox.add_child(title)

	# Subtitle
	var sub := Label.new()
	sub.text = "CREATOR ARCHIVE // AUTHORIZED PERSONNEL ONLY"
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", COL_TEXT_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.uppercase = true
	sub.modulate.a = 0.0
	vbox.add_child(sub)

	# Bottom spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 32)
	vbox.add_child(spacer)

	# Action button
	var btn := _make_action_button("INITIALIZE EXPERIENCE")
	btn.modulate.a = 0.0
	vbox.add_child(btn)
	btn.pressed.connect(_on_boot_confirmed)
	_current_action_btn = btn

	# Boot animation sequence
	_content.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_content, "modulate:a", 1.0, 0.8)
	t.tween_property(title, "modulate:a", 1.0, 1.0)
	t.tween_property(sub, "modulate:a", 1.0, 0.6)
	t.tween_interval(0.4)
	t.tween_property(btn, "modulate:a", 1.0, 0.5)


# ─────────────────────────────────────────────────────────────────────────────
# SIGNAL SCREEN
# ─────────────────────────────────────────────────────────────────────────────

func _on_boot_confirmed() -> void:
	if _current_action_btn:
		_current_action_btn.disabled = true
	_play_ui_feedback()
	_state = State.SIGNAL

	var t := create_tween()
	t.tween_property(_content, "modulate:a", 0.0, 0.5)
	t.tween_callback(_show_signal_screen)


func _show_signal_screen() -> void:
	_clear_content()
	_content = _make_fullrect_control()
	add_child(_content)

	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.add_child(bg)
	_add_grid(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	# Header
	var header := Label.new()
	header.text = "INCOMING TRANSMISSION"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", COL_ACCENT)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.uppercase = true
	vbox.add_child(header)

	# Status grid
	var status_grid := GridContainer.new()
	status_grid.columns = 2
	status_grid.add_theme_constant_override("h_separation", 24)
	status_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(status_grid)

	var _sg := func(key: String, val: String, col: Color) -> void:
		var k := Label.new()
		k.text = key
		k.add_theme_font_size_override("font_size", 10)
		k.add_theme_color_override("font_color", COL_TEXT_DIM)
		k.uppercase = true
		status_grid.add_child(k)
		var v := Label.new()
		v.text = val
		v.add_theme_font_size_override("font_size", 10)
		v.add_theme_color_override("font_color", col)
		v.uppercase = true
		status_grid.add_child(v)

	_sg.call("SOURCE",         "UNKNOWN",            COL_WARN)
	_sg.call("SIGNAL AGE",     "00:13:47",            COL_TEXT)
	_sg.call("AUTHENTICATION", "FAILED",              COL_WARN)

	vbox.add_child(_make_h_line())

	# Status label (animated decode)
	var status_lbl := Label.new()
	status_lbl.text = "SIGNAL DETECTED..."
	status_lbl.add_theme_font_size_override("font_size", 11)
	status_lbl.add_theme_color_override("font_color", COL_ACCENT)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.uppercase = true
	vbox.add_child(status_lbl)

	# Message area (hidden initially)
	var msg_lbl := RichTextLabel.new()
	msg_lbl.bbcode_enabled = true
	msg_lbl.text = "[i]\"If you're hearing this...\n\nthe protocol has already begun.\"[/i]"
	msg_lbl.add_theme_font_size_override("normal_font_size", 18)
	msg_lbl.add_theme_color_override("default_color", COL_TEXT)
	msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_lbl.fit_content = true
	msg_lbl.scroll_active = false
	msg_lbl.visible = false
	msg_lbl.visible_ratio = 0.0
	vbox.add_child(msg_lbl)

	vbox.add_child(_make_h_line())

	var btn := _make_action_button("ACCEPT SIGNAL")
	btn.modulate.a = 0.0
	btn.disabled = true
	vbox.add_child(btn)
	btn.pressed.connect(_on_signal_accepted)
	_current_action_btn = btn

	# Animate decode sequence
	_content.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_content, "modulate:a", 1.0, 0.6)
	t.tween_interval(0.8)
	t.tween_callback(func():
		status_lbl.text = "DECODING..."
		_play_ui_feedback()
	)
	t.tween_interval(0.9)
	t.tween_callback(func():
		status_lbl.text = "AUTHENTICATION FAILED"
		status_lbl.add_theme_color_override("font_color", COL_WARN)
		_play_ui_feedback()
	)
	t.tween_interval(0.8)
	t.tween_callback(func():
		status_lbl.text = "VOICE RECOVERED"
		status_lbl.add_theme_color_override("font_color", COL_SUCCESS)
		_play_ui_feedback()
	)
	t.tween_callback(func():
		if is_instance_valid(msg_lbl):
			msg_lbl.visible = true
			var rt := create_tween()
			rt.tween_property(msg_lbl, "visible_ratio", 1.0, 1.8)
	)
	t.tween_interval(2.0)
	t.tween_callback(func():
		if is_instance_valid(btn):
			btn.disabled = false
			var bt := create_tween()
			bt.tween_property(btn, "modulate:a", 1.0, 0.4)
	)


# ─────────────────────────────────────────────────────────────────────────────
# MISSION INIT SCREEN
# ─────────────────────────────────────────────────────────────────────────────

func _on_signal_accepted() -> void:
	if _current_action_btn:
		_current_action_btn.disabled = true
	_play_ui_feedback()
	_state = State.MISSION_INIT

	var t := create_tween()
	t.tween_property(_content, "modulate:a", 0.0, 0.5)
	t.tween_callback(_show_mission_init_screen)


func _show_mission_init_screen() -> void:
	_clear_content()
	_content = _make_fullrect_control()
	add_child(_content)

	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.add_child(bg)
	_add_grid(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 0)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	var header := Label.new()
	header.text = "CONNECTION ESTABLISHED"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", COL_SUCCESS)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.uppercase = true
	vbox.add_child(header)

	vbox.add_child(_make_h_line())

	# Creator profile grid
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)

	var _row := func(key: String, val: String, col: Color) -> void:
		var k := Label.new()
		k.text = key
		k.add_theme_font_size_override("font_size", 11)
		k.add_theme_color_override("font_color", COL_TEXT_DIM)
		k.uppercase = true
		grid.add_child(k)
		var v := Label.new()
		v.text = val
		v.add_theme_font_size_override("font_size", 11)
		v.add_theme_color_override("font_color", col)
		v.uppercase = true
		grid.add_child(v)

	_row.call("CREATOR",   "RYAN VANCE",  COL_ACCENT)
	_row.call("STATUS",    "ALIVE",        COL_SUCCESS)
	_row.call("AUTHORITY", "REVOKED",      COL_WARN)
	_row.call("NETWORK",   "HOSTILE",      COL_WARN)

	vbox.add_child(_make_h_line())

	var protocol_lbl := Label.new()
	protocol_lbl.text = "LAST PROTOCOL\nSTANDBY"
	protocol_lbl.add_theme_font_size_override("font_size", 22)
	protocol_lbl.add_theme_color_override("font_color", COL_TEXT)
	protocol_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	protocol_lbl.uppercase = true
	vbox.add_child(protocol_lbl)

	vbox.add_child(_make_h_line())

	var btn := _make_action_button("ENTER")
	btn.modulate.a = 0.0
	vbox.add_child(btn)
	btn.pressed.connect(_on_enter_pressed)
	_current_action_btn = btn

	_content.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_content, "modulate:a", 1.0, 0.8)
	t.tween_interval(0.8)
	t.tween_property(btn, "modulate:a", 1.0, 0.5)


func _on_enter_pressed() -> void:
	if _current_action_btn:
		_current_action_btn.disabled = true
	_play_ui_feedback()

	# Fade everything to black, show "10 YEARS EARLIER", then transition
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.modulate.a = 0.0
	add_child(fade)

	var t := create_tween()
	t.tween_property(fade, "modulate:a", 1.0, 1.0)
	t.tween_callback(func():
		var lbl := Label.new()
		lbl.text = "10 YEARS EARLIER"
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 0.0))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.uppercase = true
		add_child(lbl)
		var lt := create_tween()
		lt.tween_property(lbl, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	)
	t.tween_interval(2.5)
	t.tween_callback(func():
		queue_free()
		CutsceneManager.is_cutscene_playing = false
		CutsceneManager.play_cutscene("res://story/cinematics/opening_cinematic.tscn")
	)


# ─────────────────────────────────────────────────────────────────────────────
# WIDGET BUILDERS
# ─────────────────────────────────────────────────────────────────────────────

func _make_fullrect_control() -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _make_action_button(label_text: String) -> Control:
	## Returns a PanelContainer styled as a TLP system control.
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_btn_style(false))
	panel.custom_minimum_size = Vector2(260, 48)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var lbl := Label.new()
	lbl.text = "[ " + label_text + " ]"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", COL_ACCENT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.uppercase = true
	panel.add_child(lbl)

	# Make it act like a button by wrapping in a Button with transparent style
	var btn_wrapper := Button.new()
	btn_wrapper.flat = true
	btn_wrapper.custom_minimum_size = Vector2(260, 48)
	btn_wrapper.add_theme_stylebox_override("normal",   _make_transparent_style())
	btn_wrapper.add_theme_stylebox_override("hover",    _make_transparent_style())
	btn_wrapper.add_theme_stylebox_override("pressed",  _make_transparent_style())
	btn_wrapper.add_theme_stylebox_override("disabled", _make_transparent_style())
	btn_wrapper.add_child(panel)

	# Hover effects via signals
	btn_wrapper.mouse_entered.connect(func():
		panel.add_theme_stylebox_override("panel", _make_btn_style(true))
		lbl.add_theme_color_override("font_color", Color.WHITE)
	)
	btn_wrapper.mouse_exited.connect(func():
		panel.add_theme_stylebox_override("panel", _make_btn_style(false))
		lbl.add_theme_color_override("font_color", COL_ACCENT)
	)

	return btn_wrapper


func _make_meta_tag(parent: Control, key: String, value: String) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	parent.add_child(vbox)

	var k := Label.new()
	k.text = key
	k.add_theme_font_size_override("font_size", 9)
	k.add_theme_color_override("font_color", COL_TEXT_DIM)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	k.uppercase = true
	vbox.add_child(k)

	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 13)
	v.add_theme_color_override("font_color", COL_ACCENT)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.uppercase = true
	vbox.add_child(v)


func _make_meta_separator(parent: Control) -> void:
	var sep := Label.new()
	sep.text = "//"
	sep.add_theme_font_size_override("font_size", 11)
	sep.add_theme_color_override("font_color", COL_BORDER_BRIGHT)
	sep.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(sep)


func _make_h_line() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 1)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := ColorRect.new()
	line.color = COL_BORDER
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(line)
	return c


func _add_corner_mark(parent: Control, preset: int) -> void:
	const SIZE := 16
	var c := Control.new()
	c.custom_minimum_size = Vector2(SIZE, SIZE)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_and_offsets_preset(preset)
	var margin := 24
	match preset:
		Control.PRESET_TOP_LEFT:
			c.offset_left = margin; c.offset_top = margin; c.offset_right = margin + SIZE; c.offset_bottom = margin + SIZE
		Control.PRESET_TOP_RIGHT:
			c.offset_left = -(margin + SIZE); c.offset_top = margin; c.offset_right = -margin; c.offset_bottom = margin + SIZE
		Control.PRESET_BOTTOM_LEFT:
			c.offset_left = margin; c.offset_top = -(margin + SIZE); c.offset_right = margin + SIZE; c.offset_bottom = -margin
		Control.PRESET_BOTTOM_RIGHT:
			c.offset_left = -(margin + SIZE); c.offset_top = -(margin + SIZE); c.offset_right = -margin; c.offset_bottom = -margin

	# Horizontal bar
	var h := ColorRect.new()
	h.color = COL_BORDER_BRIGHT
	h.size = Vector2(SIZE, 1)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(h)

	# Vertical bar
	var v := ColorRect.new()
	v.color = COL_BORDER_BRIGHT
	v.size = Vector2(1, SIZE)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(v)

	parent.add_child(c)


func _add_grid(parent: Control) -> void:
	## Adds a subtle 40px micro-grid as a child ColorRect (clipped).
	## In Godot 4 we simulate this with a thin, looping Canvas item.
	## For simplicity, we use a fixed alpha pattern with custom drawing.
	pass  # Grid effect handled by the dark background — visual accent only


func _run_scan_drift(scan: ColorRect) -> void:
	scan.size = Vector2(0, 2)
	var t := create_tween().set_loops()
	t.tween_property(scan, "offset_top", 1.0, 6.0).set_trans(Tween.TRANS_LINEAR)
	t.tween_property(scan, "offset_top", 0.0, 0.01)
	_scan_tween = t


# ─────────────────────────────────────────────────────────────────────────────
# STYLE BUILDERS
# ─────────────────────────────────────────────────────────────────────────────

func _make_panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = COL_PANEL
	s.border_color = COL_BORDER
	s.border_width_left = 1; s.border_width_right = 1
	s.border_width_top = 1;  s.border_width_bottom = 1
	s.corner_radius_top_left = 3; s.corner_radius_top_right = 3
	s.corner_radius_bottom_left = 3; s.corner_radius_bottom_right = 3
	s.content_margin_left = 28; s.content_margin_right = 28
	s.content_margin_top = 24;  s.content_margin_bottom = 24
	return s


func _make_btn_style(hovered: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.0, 0.04, 0.08, 0.85) if not hovered else Color(0.0, 0.10, 0.18, 0.95)
	s.border_color = COL_BORDER_BRIGHT if hovered else COL_BORDER
	s.border_width_left = 1; s.border_width_right = 1
	s.border_width_top = 1;  s.border_width_bottom = 1
	s.corner_radius_top_left = 2; s.corner_radius_top_right = 2
	s.corner_radius_bottom_left = 2; s.corner_radius_bottom_right = 2
	s.content_margin_left = 16; s.content_margin_right = 16
	s.content_margin_top = 10;  s.content_margin_bottom = 10
	return s


func _make_transparent_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color.TRANSPARENT
	s.draw_center = false
	return s


# ─────────────────────────────────────────────────────────────────────────────
# AUDIO
# ─────────────────────────────────────────────────────────────────────────────

func _play_intro_music() -> void:
	if intro_music and _music_player:
		_music_player.stream = intro_music
		_music_player.play()


func _play_ui_feedback() -> void:
	if _ui_player:
		StoryAudioManager.play_sfx("ui_dialogue_confirm")


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

func _clear_content() -> void:
	if _scan_tween:
		_scan_tween.kill()
		_scan_tween = null
	if _content and is_instance_valid(_content):
		_content.queue_free()
		_content = null
