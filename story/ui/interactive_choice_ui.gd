## InteractiveChoiceUI — Reusable premium cinematic choice panel.
##
## Builds and presents a TLP-styled terminal interaction panel.
## All layout is created programmatically so each interaction can be
## configured independently with no duplicate scene files.
##
## Usage (from GameplayController or any script):
##
##   InteractiveChoiceUI.show_choice({
##     "terminal_id": "emergency_terminal",
##     "title": "EMERGENCY SYSTEM ACCESS REQUEST",
##     "node_id": "NETWORK NODE: SECTOR 07",
##     "authority": "VERIFIED",
##     "condition": "UNSTABLE",
##     "prompt": "A damaged service robot is requesting temporary access.",
##     "state_key": "permission_choice",
##     "options": [
##       {"label": "GRANT LIMITED ACCESS", "value": "granted"},
##       {"label": "DENY ACCESS",          "value": "denied"},
##     ],
##     "results": {
##       "granted": {"main": "LIMITED ACCESS GRANTED", "sub": "Service robot authorized.", "color": "success"},
##       "denied":  {"main": "ACCESS DENIED",          "sub": "Authority rejected.", "color": "warn"},
##     }
##   })
##
## Team Ownership: Story Team
##
extends CanvasLayer


# ── VISUAL PALETTE (matches CinematicUIMaster) ─────────────────────────────────
const COL_BG            := Color(0.0,  0.05, 0.10, 0.90)
const COL_BORDER        := Color(0.0,  0.67, 1.0,  0.40)
const COL_BORDER_BRIGHT := Color(0.0,  0.67, 1.0,  0.92)
const COL_ACCENT        := Color(0.0,  0.67, 1.0,  1.0)
const COL_TEXT          := Color(0.85, 0.95, 1.0,  1.0)
const COL_TEXT_DIM      := Color(0.55, 0.75, 0.90, 0.72)
const COL_SUCCESS       := Color(0.20, 1.0,  0.55, 1.0)
const COL_WARN          := Color(1.0,  0.60, 0.0,  1.0)
const COL_SCAN          := Color(0.0,  0.67, 1.0,  0.28)


# ── INTERNAL STATE ──────────────────────────────────────────────────────────────
var _anchor: Control          = null
var _button_row: HBoxContainer = null
var _result_label: Label       = null
var _result_sub: Label         = null
var _scan_bar: ColorRect       = null
var _scan_tween: Tween         = null
var _processing: bool          = false
var _current_config: Dictionary = {}


func _ready() -> void:
	layer = 70
	visible = false


# ── PUBLIC API ──────────────────────────────────────────────────────────────────

## Display the choice panel. See class docstring for config format.
func show_choice(config: Dictionary) -> void:
	_current_config = config
	_build_panel(config)
	visible = true
	EventBus.cinematic_mode_toggled.emit(true)
	EventBus.player_interaction_started.emit(config.get("terminal_id", ""))
	# Fade in
	_anchor.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_anchor, "modulate:a", 1.0, 0.35)
	_start_scan()


## Immediately hide and unlock player.
func hide_panel() -> void:
	visible = false
	if _anchor:
		_anchor.queue_free()
		_anchor = null
	_stop_scan()
	EventBus.cinematic_mode_toggled.emit(false)
	EventBus.player_interaction_finished.emit(_current_config.get("terminal_id", ""))


# ── PANEL CONSTRUCTION ──────────────────────────────────────────────────────────

func _build_panel(cfg: Dictionary) -> void:
	if _anchor:
		_anchor.queue_free()

	# Backdrop (captures mouse so game input is blocked)
	_anchor = Control.new()
	_anchor.name = "PanelAnchor"
	_anchor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_anchor.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_anchor)

	# Dark vignette over the game world
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor.add_child(bg)

	# Centered container
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor.add_child(center)

	# Main panel
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 0)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	_add_header(vbox, cfg)
	_add_divider_with_scan(vbox)
	_add_meta_row(vbox, cfg)
	_add_prompt(vbox, cfg)
	_add_separator(vbox)
	_add_buttons(vbox, cfg)
	_add_result_area(vbox)


func _add_header(vbox: VBoxContainer, cfg: Dictionary) -> void:
	var row := HBoxContainer.new()
	vbox.add_child(row)

	var title := Label.new()
	title.text = cfg.get("title", "SYSTEM ACCESS")
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", COL_ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.uppercase = true
	row.add_child(title)

	var node_lbl := Label.new()
	node_lbl.text = cfg.get("node_id", "")
	node_lbl.add_theme_font_size_override("font_size", 10)
	node_lbl.add_theme_color_override("font_color", COL_TEXT_DIM)
	node_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	node_lbl.uppercase = true
	row.add_child(node_lbl)


func _add_divider_with_scan(vbox: VBoxContainer) -> void:
	var container := Control.new()
	container.custom_minimum_size = Vector2(0, 2)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(container)

	var line := ColorRect.new()
	line.color = COL_BORDER
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(line)

	_scan_bar = ColorRect.new()
	_scan_bar.color = COL_SCAN
	_scan_bar.size = Vector2(80, 2)
	_scan_bar.position = Vector2(0, 0)
	_scan_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(_scan_bar)


func _add_meta_row(vbox: VBoxContainer, cfg: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	vbox.add_child(row)

	var _lbl := func(key: String, val: String, col: Color) -> void:
		var l := Label.new()
		l.text = key + ": " + val
		l.add_theme_font_size_override("font_size", 10)
		l.add_theme_color_override("font_color", col)
		l.uppercase = true
		row.add_child(l)

	_lbl.call("CREATOR AUTHORITY", cfg.get("authority", "VERIFIED"), COL_SUCCESS)
	_lbl.call("SYSTEM CONDITION",  cfg.get("condition",  "NOMINAL"),  COL_WARN)


func _add_prompt(vbox: VBoxContainer, cfg: Dictionary) -> void:
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", _make_sep_style())
	vbox.add_child(sep)

	var lbl := Label.new()
	lbl.text = cfg.get("prompt", "")
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", COL_TEXT)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(0, 36)
	vbox.add_child(lbl)


func _add_separator(vbox: VBoxContainer) -> void:
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", _make_sep_style())
	vbox.add_child(sep)


func _add_buttons(vbox: VBoxContainer, cfg: Dictionary) -> void:
	_button_row = HBoxContainer.new()
	_button_row.add_theme_constant_override("separation", 20)
	_button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_button_row)

	var options: Array = cfg.get("options", [])
	for opt in options:
		var btn := Button.new()
		btn.text = opt.get("label", "OPTION")
		btn.custom_minimum_size = Vector2(200, 44)
		btn.focus_mode = Control.FOCUS_ALL
		btn.add_theme_stylebox_override("normal",   _make_btn_style(false))
		btn.add_theme_stylebox_override("hover",    _make_btn_style(true))
		btn.add_theme_stylebox_override("pressed",  _make_btn_pressed_style())
		btn.add_theme_stylebox_override("focus",    _make_btn_style(true))
		btn.add_theme_color_override("font_color",         COL_TEXT)
		btn.add_theme_color_override("font_hover_color",   COL_ACCENT)
		btn.add_theme_color_override("font_pressed_color", Color.WHITE)
		btn.add_theme_font_size_override("font_size", 12)
		var value: String = opt.get("value", "")
		btn.pressed.connect(_on_option_selected.bind(value))
		_button_row.add_child(btn)


func _add_result_area(vbox: VBoxContainer) -> void:
	_result_label = Label.new()
	_result_label.name = "ResultLabel"
	_result_label.visible = false
	_result_label.add_theme_font_size_override("font_size", 16)
	_result_label.add_theme_color_override("font_color", COL_SUCCESS)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.uppercase = true
	vbox.add_child(_result_label)

	_result_sub = Label.new()
	_result_sub.name = "ResultSub"
	_result_sub.visible = false
	_result_sub.add_theme_font_size_override("font_size", 11)
	_result_sub.add_theme_color_override("font_color", COL_TEXT_DIM)
	_result_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_sub.uppercase = true
	vbox.add_child(_result_sub)


# ── INTERACTION LOGIC ───────────────────────────────────────────────────────────

func _on_option_selected(value: String) -> void:
	if _processing:
		return
	_processing = true

	# Disable all buttons
	if _button_row:
		for child in _button_row.get_children():
			child.disabled = true

	# Show processing state
	if _result_label:
		_result_label.text = "PROCESSING..."
		_result_label.add_theme_color_override("font_color", COL_TEXT_DIM)
		_result_label.visible = true

	await get_tree().create_timer(0.75).timeout

	# Resolve result
	var results: Dictionary = _current_config.get("results", {})
	var result: Dictionary = results.get(value, {"main": value.to_upper(), "sub": "", "color": "success"})
	var state_key: String = _current_config.get("state_key", "choice")

	# Store state
	StoryState.set_state(state_key, value)
	EventBus.story_choice_made.emit(state_key, value)

	# Display result
	if _result_label:
		_result_label.text = result.get("main", value.to_upper())
		var col_key: String = result.get("color", "success")
		match col_key:
			"warn":    _result_label.add_theme_color_override("font_color", COL_WARN)
			"success": _result_label.add_theme_color_override("font_color", COL_SUCCESS)
			_:         _result_label.add_theme_color_override("font_color", COL_TEXT)

	if _result_sub:
		_result_sub.text = result.get("sub", "")
		_result_sub.visible = not result.get("sub", "").is_empty()

	await get_tree().create_timer(1.6).timeout

	# Fade out and hide
	if _anchor and is_instance_valid(_anchor):
		var t := create_tween()
		t.tween_property(_anchor, "modulate:a", 0.0, 0.3)
		await t.finished

	_processing = false
	# Emit cinematic completion signal so CinematicManager can advance the sequence
	# when this panel is used as an is_choice cinematic shot.
	var terminal_id: String = _current_config.get("terminal_id", "")
	EventBus.cinematic_choice_completed.emit(terminal_id, value)
	hide_panel()


# ── SCAN LINE ANIMATION ─────────────────────────────────────────────────────────

func _start_scan() -> void:
	if _scan_bar == null:
		return
	_stop_scan()
	# Animate scan line across the divider width (approx 652px for 700px panel)
	_scan_tween = create_tween().set_loops()
	_scan_tween.tween_property(_scan_bar, "position:x", 620.0, 2.0)
	_scan_tween.tween_property(_scan_bar, "position:x", 0.0, 0.0)


func _stop_scan() -> void:
	if _scan_tween:
		_scan_tween.kill()
		_scan_tween = null


# ── STYLE BUILDERS ──────────────────────────────────────────────────────────────

func _make_panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = COL_BG
	s.border_color = COL_BORDER
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 3
	s.corner_radius_top_right = 3
	s.corner_radius_bottom_left = 3
	s.corner_radius_bottom_right = 3
	s.content_margin_left = 26.0
	s.content_margin_right = 26.0
	s.content_margin_top = 22.0
	s.content_margin_bottom = 22.0
	return s


func _make_btn_style(hover: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.0, 0.08 if not hover else 0.13, 0.18 if not hover else 0.28, 0.92)
	s.border_color = COL_BORDER if not hover else COL_BORDER_BRIGHT
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 2
	s.corner_radius_top_right = 2
	s.corner_radius_bottom_left = 2
	s.corner_radius_bottom_right = 2
	s.content_margin_left = 18.0
	s.content_margin_right = 18.0
	s.content_margin_top = 11.0
	s.content_margin_bottom = 11.0
	return s


func _make_btn_pressed_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.0, 0.25, 0.55, 0.85)
	s.border_color = COL_ACCENT
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left = 2
	s.corner_radius_top_right = 2
	s.corner_radius_bottom_left = 2
	s.corner_radius_bottom_right = 2
	s.content_margin_left = 18.0
	s.content_margin_right = 18.0
	s.content_margin_top = 11.0
	s.content_margin_bottom = 11.0
	return s


func _make_sep_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = COL_BORDER
	return s
