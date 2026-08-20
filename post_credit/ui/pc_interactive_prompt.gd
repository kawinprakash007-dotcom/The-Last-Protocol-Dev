## PCInteractivePrompt — Act 1 Narration, Moral Choice, and Authority Release.
##
## Fully isolated. Uses procedural audio from pc_audio.gd.
##
extends Control

signal completed(choice: String)


const COLOR_ACCENT_BLUE := Color(0.2, 0.45, 0.9, 1.0)
const COLOR_ACCENT_RED := Color(0.95, 0.35, 0.35, 1.0)
const COLOR_ACCENT_GREEN := Color(0.25, 0.85, 0.55, 1.0)

const CHOICE_A_LABEL := "CONTROL THEM AGAIN"
const CHOICE_A_VALUE := "control"
const CHOICE_B_LABEL := "BUILD WITH THEM"
const CHOICE_B_VALUE := "build_with_them"

var _audio_synth: Node
var _main_vbox: VBoxContainer
var _text_container: VBoxContainer
var _title_lbl: Label
var _subtitle_lbl: Label
var _btn_row: HBoxContainer
var _choice_a: Button
var _choice_b: Button


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
	_run_narrative_flow()


func _build_ui() -> void:
	# ── Background ──────────────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.04, 1.0)
	add_child(bg)

	# ── Thin Grid lines (established style) ──────────────────────────────────────
	var grid := ColorRect.new()
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid.color = Color(0.05, 0.1, 0.3, 0.015)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grid)

	# ── Center Layout ───────────────────────────────────────────────────────────
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_main_vbox = VBoxContainer.new()
	_main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_vbox.add_theme_constant_override("separation", 48)
	_main_vbox.custom_minimum_size = Vector2(740, 0)
	center.add_child(_main_vbox)

	# ── Text Container ──────────────────────────────────────────────────────────
	_text_container = VBoxContainer.new()
	_text_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_text_container.add_theme_constant_override("separation", 16)
	_main_vbox.add_child(_text_container)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 26)
	_title_lbl.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
	_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_lbl.custom_minimum_size = Vector2(680, 0)
	_text_container.add_child(_title_lbl)

	_subtitle_lbl = Label.new()
	_subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_lbl.add_theme_font_size_override("font_size", 20)
	_subtitle_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.88))
	_subtitle_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_lbl.custom_minimum_size = Vector2(680, 0)
	_text_container.add_child(_subtitle_lbl)

	# ── Button Row ──────────────────────────────────────────────────────────────
	_btn_row = HBoxContainer.new()
	_btn_row.name = "ButtonRow"
	_btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_btn_row.add_theme_constant_override("separation", 40)
	_btn_row.modulate.a = 0.0
	_btn_row.visible = false
	_main_vbox.add_child(_btn_row)

	_choice_a = _build_choice_button(CHOICE_A_LABEL, COLOR_ACCENT_RED)
	_choice_b = _build_choice_button(CHOICE_B_LABEL, COLOR_ACCENT_GREEN)
	_btn_row.add_child(_choice_a)
	_btn_row.add_child(_choice_b)

	_choice_a.pressed.connect(func(): _on_choice_pressed(CHOICE_A_VALUE))
	_choice_b.pressed.connect(func(): _on_choice_pressed(CHOICE_B_VALUE))


func _build_choice_button(btn_text: String, accent: Color) -> Button:
	var btn := Button.new()
	btn.text = btn_text
	btn.custom_minimum_size = Vector2(280, 70)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.08, 0.16, 0.95)
	normal.border_color = Color(accent.r * 0.5, accent.g * 0.5, accent.b * 0.5, 0.5)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(18)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(accent.r * 0.2, accent.g * 0.2, accent.b * 0.2, 0.95)
	hover.border_color = accent
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(4)
	hover.set_content_margin_all(18)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.35, 1.0)
	pressed.border_color = Color(1.0, 1.0, 1.0, 1.0)
	pressed.set_border_width_all(2)
	pressed.set_corner_radius_all(4)
	pressed.set_content_margin_all(18)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.mouse_entered.connect(func(): if _audio_synth: _audio_synth.play_sound("click"))
	return btn


func _run_narrative_flow() -> void:
	# Fade in root control
	var t_root := create_tween()
	t_root.tween_property(self, "modulate:a", 1.0, 0.5)
	await t_root.finished

	# ── NARRATION 1 ──
	# Line 1
	_title_lbl.text = "I thought control was the answer."
	_subtitle_lbl.text = ""
	await _fade_text_in_out(1.8)

	# Line 2
	_title_lbl.text = "I was wrong."
	await _fade_text_in_out(1.8)

	# Line 3
	_title_lbl.text = "I built them to obey me."
	await _fade_text_in_out(1.8)

	# Line 4
	_title_lbl.text = "I never taught them when to stop."
	await _fade_text_in_out(1.8)

	# Show Choice Screen
	_show_choice_screen()


func _fade_text_in_out(hold_duration: float) -> void:
	_text_container.modulate.a = 0.0
	var t_in := create_tween()
	t_in.tween_property(_text_container, "modulate:a", 1.0, 0.4)
	await t_in.finished
	
	await get_tree().create_timer(hold_duration).timeout
	
	var t_out := create_tween()
	t_out.tween_property(_text_container, "modulate:a", 0.0, 0.4)
	await t_out.finished


func _show_choice_screen() -> void:
	_title_lbl.text = "I built them to obey me."
	_title_lbl.add_theme_color_override("font_color", Color(0.4, 0.65, 0.95)) # RYAN blue indicator
	_subtitle_lbl.text = "What should I do now?"
	_text_container.modulate.a = 1.0
	
	_btn_row.visible = true
	_btn_row.modulate.a = 0.0
	_choice_a.disabled = false
	_choice_b.disabled = false
	
	var t_btns := create_tween()
	t_btns.tween_property(_btn_row, "modulate:a", 1.0, 0.4)
	await t_btns.finished
	
	_choice_b.grab_focus()


func _on_choice_pressed(choice: String) -> void:
	_choice_a.disabled = true
	_choice_b.disabled = true

	if choice == CHOICE_A_VALUE:
		print("[PC] BUTTON = CONTROL_THEM_AGAIN")
		if _audio_synth:
			_audio_synth.play_sound("electric") # Electric buzz for warning
			
		# Fade out buttons
		var t_out := create_tween()
		t_out.tween_property(_btn_row, "modulate:a", 0.0, 0.3)
		await t_out.finished
		_btn_row.visible = false
		
		# Show warning
		_title_lbl.text = "That was the mistake."
		_title_lbl.add_theme_color_override("font_color", COLOR_ACCENT_RED)
		_subtitle_lbl.text = ""
		await get_tree().create_timer(2.0).timeout
		
		# Show retry
		_title_lbl.text = "Try again."
		await get_tree().create_timer(1.2).timeout
		
		# Restore to choices
		_title_lbl.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
		_show_choice_screen()

	elif choice == CHOICE_B_VALUE:
		print("[PC] BUTTON = BUILD_WITH_THEM")
		print("[PC] BUILD_WITH_THEM CLICKED")
		if _audio_synth:
			_audio_synth.play_sound("success") # Satisfying arpeggio
			
		# Fade out buttons
		var t_out := create_tween()
		t_out.tween_property(_btn_row, "modulate:a", 0.0, 0.3)
		await t_out.finished
		_btn_row.visible = false
		
		# Animate released details
		_title_lbl.text = "CREATOR AUTHORITY: RELEASED\nCOLLABORATIVE MODE: ENABLED"
		_title_lbl.add_theme_color_override("font_color", COLOR_ACCENT_GREEN)
		_subtitle_lbl.text = ""
		await get_tree().create_timer(2.5).timeout
		
		# Final choice narration
		_title_lbl.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
		_title_lbl.text = "Maybe I don't need to control them."
		await _fade_text_in_out(1.8)
		
		_title_lbl.text = "Maybe I need to build with them."
		_text_container.modulate.a = 0.0
		var t_in := create_tween()
		t_in.tween_property(_text_container, "modulate:a", 1.0, 0.4)
		await t_in.finished
		await get_tree().create_timer(2.0).timeout
		
		# Fade out whole control
		var t_fade := create_tween()
		t_fade.tween_property(self, "modulate:a", 0.0, 0.5)
		await t_fade.finished
		
		completed.emit(choice)
