extends CanvasLayer
class_name CinematicUIMaster

## Central controller for The Last Protocol's cinematic UI system.
## Phase 12 + Phase 14B: Premium cinematic UI with narration, diagnostics,
## scanning overlays and story-reactive components.
## Does NOT interfere with gameplay HUD or existing dialogue system.

const UI_DIR = "res://story/cinematics/ui/"

# ── Colour palette ─────────────────────────────────────────────────
const COL_ACCENT       = Color(0.0,  0.67, 1.0,  1.0)   # #00aaff
const COL_ACCENT_DIM   = Color(0.0,  0.67, 1.0,  0.5)
const COL_BG           = Color(0.0,  0.05, 0.1,  0.72)  # dark glass
const COL_LINE         = Color(0.0,  0.67, 1.0,  0.35)
const COL_WARN         = Color(1.0,  0.3,  0.1,  1.0)
const COL_CRIT         = Color(1.0,  0.0,  0.0,  1.0)
const COL_TEXT         = Color(0.85, 0.95, 1.0,  1.0)
const COL_TEXT_DIM     = Color(0.85, 0.95, 1.0,  0.5)
const COL_SUCCESS      = Color(0.2,  1.0,  0.55, 1.0)   # green-cyan

# ── Active overlays ────────────────────────────────────────────────
var _active_year_marker:   Control = null
var _active_status:        Control = null
var _active_warning:       Control = null
var _active_subtitle:      Control = null
var _active_narration:     Control = null
var _active_diagnostic:    Control = null

# ── Layer order ────────────────────────────────────────────────────
func _ready():
	layer = 10  # Above world, below dialogue

# ─────────────────────────────────────────────────────────────────
#  PUBLIC API — story calls these
# ─────────────────────────────────────────────────────────────────

## Show a year stamp: show_year(1) → "YEAR 01"
func show_year(year: int, hold_s: float = 3.0):
	if _active_year_marker:
		_active_year_marker.queue_free()
	var m = _load_ui("YearMarker")
	if not m: return
	add_child(m)
	_active_year_marker = m
	var label = m.get_node_or_null("Label")
	if label:
		label.text = "YEAR %02d" % year
	_animate_slide_in(m, Vector2(-200, 0))
	_auto_dismiss(m, hold_s, func(): _active_year_marker = null)

## Show a generic system status line: show_status("SYSTEMS ONLINE")
func show_status(text: String, hold_s: float = 4.0):
	if _active_status:
		_active_status.queue_free()
	var m = _load_ui("SystemStatus")
	if not m: return
	add_child(m)
	_active_status = m
	_set_label(m, "StatusLabel", text)
	_animate_data_reveal(m, "StatusLabel")
	_auto_dismiss(m, hold_s, func(): _active_status = null)

## Show network status bar: show_network(42, "AUTOMATION NETWORK")
func show_network(percent: int, label_text: String = "NETWORK", hold_s: float = 5.0):
	if _active_status:
		_active_status.queue_free()
	var m = _load_ui("NetworkStatus")
	if not m: return
	add_child(m)
	_active_status = m
	_set_label(m, "TitleLabel", label_text + ": %d%%" % percent)
	var bar = m.get_node_or_null("Bar")
	if bar:
		_animate_bar(bar, float(percent) / 100.0)
	_auto_dismiss(m, hold_s, func(): _active_status = null)

## Show warning text on the edges of screen
func show_warning(text: String, hold_s: float = 4.0):
	if _active_warning:
		_active_warning.queue_free()
	var m = _load_ui("WarningOverlay")
	if not m: return
	add_child(m)
	_active_warning = m
	_set_label(m, "WarnLabel", text)
	_animate_warning_pulse(m)
	_auto_dismiss(m, hold_s, func(): _active_warning = null)

## Show a large mission title
func show_title(text: String, hold_s: float = 4.0):
	var m = _load_ui("MissionTitle")
	if not m: return
	add_child(m)
	_set_label(m, "TitleLabel", text)
	_animate_glitch_reveal(m)
	_auto_dismiss(m, hold_s)

## Show the authority transfer screen with scanning animation sequence
func show_authorization():
	var m = _load_ui("AuthorizationScreen")
	if not m: return
	add_child(m)
	if m.has_method("initialize_interactive"):
		m.call("initialize_interactive")
	else:
		_set_label(m, "MainLabel", "AUTHORITY TRANSFER")
		_set_label(m, "SubLabel", "SCANNING...")
		_animate_auth_screen(m)
		# Scanning → Verifying → Authorized sequence
		get_tree().create_timer(1.5).timeout.connect(func():
			if is_instance_valid(m): _set_label(m, "SubLabel", "IDENTITY VERIFIED")
		)
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(m):
				_set_label(m, "SubLabel", "ACCESS GRANTED")
				var lbl = m.get_node_or_null("SubLabel")
				if lbl: lbl.add_theme_color_override("font_color", COL_SUCCESS)
		)
		_auto_dismiss(m, 5.0)

## Show the emergency Last Protocol confirmation screen
func show_last_protocol():
	var m = _load_ui("LastProtocolScreen")
	if not m: return
	add_child(m)
	if m.has_method("initialize_interactive"):
		m.call("initialize_interactive")

## Show system failure state
func show_system_failure():
	show_warning("SYSTEM FAILURE")

## Show critical failure state (red full-frame corners)
func show_critical_failure():
	var m = _load_ui("WarningOverlay")
	if not m: return
	add_child(m)
	_set_label(m, "WarnLabel", "CRITICAL FAILURE")
	for child in m.get_children():
		if child is Label:
			child.add_theme_color_override("font_color", COL_CRIT)
	_animate_warning_pulse(m)
	_auto_dismiss(m, 6.0)

## Show a bottom subtitle (for gameplay dialogue / UI labels)
func show_subtitle(text: String, hold_s: float = 4.0):
	if _active_subtitle:
		_active_subtitle.queue_free()
	var m = _load_ui("CinematicSubtitle")
	if not m: return
	add_child(m)
	_active_subtitle = m
	_set_label(m, "SubtitleLabel", text)
	_animate_scan_in(m)
	_auto_dismiss(m, hold_s, func(): _active_subtitle = null)

## Phase 14B: Show cinematic voice-over narration — elegant bottom-bar.
## Smaller, more transparent than subtitle. No background box.
func show_narration(text: String, hold_s: float = 4.0):
	if _active_narration:
		_active_narration.queue_free()
	# Build narration bar procedurally (no .tscn required — always available)
	var root = Control.new()
	root.name = "NarrationBar"
	root.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	root.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	root.set_anchor_and_offset(SIDE_BOTTOM, 1, -28)
	root.custom_minimum_size = Vector2(0, 42)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Subtle semi-transparent dark bar
	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.02, 0.08, 0.60)
	bg.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	bg.set_anchor_and_offset(SIDE_TOP,    0, 0)
	bg.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	bg.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
	root.add_child(bg)
	# Thin cyan top accent
	var accent = ColorRect.new()
	accent.color = Color(0.0, 0.67, 1.0, 0.45)
	accent.custom_minimum_size = Vector2(0, 1)
	accent.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	accent.set_anchor_and_offset(SIDE_TOP,    0, 0)
	accent.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	accent.set_anchor_and_offset(SIDE_BOTTOM, 0, 1)
	root.add_child(accent)
	# Narration label — centred, elegant
	var lbl = Label.new()
	lbl.name = "NarrationLabel"
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.88, 0.95, 1.0, 0.92))
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchor_and_offset(SIDE_LEFT,   0, 60)
	lbl.set_anchor_and_offset(SIDE_TOP,    0, 0)
	lbl.set_anchor_and_offset(SIDE_RIGHT,  1, -60)
	lbl.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
	root.add_child(lbl)
	add_child(root)
	_active_narration = root
	root.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(root, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	_auto_dismiss(root, hold_s, func(): _active_narration = null)

## Phase 14B: Show robot diagnostic with a given state
func show_robot_diagnostic(state: String = "ONLINE", hold_s: float = 5.0):
	if _active_diagnostic:
		_active_diagnostic.queue_free()
	var m = _load_ui("RobotDiagnostic")
	if not m: return
	add_child(m)
	_active_diagnostic = m
	match state:
		"BOOTING":
			_set_label(m, "Header", "ROBOT DIAGNOSTIC — BOOTING")
		"FAILURE":
			_set_label(m, "Header", "ROBOT DIAGNOSTIC — FAILURE")
			for i in range(6):
				var row = m.get_node_or_null("Row%d" % i)
				if row:
					for child in row.get_children():
						if child is Label and child != row.get_child(0):
							child.add_theme_color_override("font_color", COL_WARN)
		_:
			_set_label(m, "Header", "ROBOT DIAGNOSTIC — ONLINE")
	_animate_slide_in(m, Vector2(200, 0))
	_auto_dismiss(m, hold_s, func(): _active_diagnostic = null)

## Phase 14B: Show city status panel
func show_city_status(hold_s: float = 4.0):
	if _active_status: _active_status.queue_free()
	var m = _load_ui("CityStatus")
	if not m: return
	add_child(m)
	_active_status = m
	_animate_slide_in(m, Vector2(200, 0))
	_auto_dismiss(m, hold_s, func(): _active_status = null)

## Full narrative demo sequence
func play_demo_sequence():
	show_year(1)
	await get_tree().create_timer(2.5).timeout
	show_status("SYSTEMS ONLINE")
	await get_tree().create_timer(4.0).timeout
	show_year(5)
	await get_tree().create_timer(2.5).timeout
	show_network(42, "AUTOMATION NETWORK")
	await get_tree().create_timer(5.0).timeout
	show_year(10)
	await get_tree().create_timer(2.5).timeout
	show_network(100, "GLOBAL MACHINE NETWORK")
	await get_tree().create_timer(4.0).timeout
	show_authorization()
	await get_tree().create_timer(5.5).timeout
	show_system_failure()
	await get_tree().create_timer(4.0).timeout
	show_critical_failure()

# ─────────────────────────────────────────────────────────────────
#  INTERNAL HELPERS
# ─────────────────────────────────────────────────────────────────

func _load_ui(name: String) -> Control:
	var path = UI_DIR + name + ".tscn"
	if not ResourceLoader.exists(path):
		printerr("[CinematicUIMaster] UI scene not found: " + path)
		return null
	return (load(path) as PackedScene).instantiate()

func _set_label(root: Control, node_name: String, text: String):
	var lbl = root.get_node_or_null(node_name)
	if lbl is Label or lbl is RichTextLabel:
		lbl.text = text

func _auto_dismiss(node: Control, after: float, callback: Callable = Callable()):
	get_tree().create_timer(after).timeout.connect(func():
		if not node or not is_instance_valid(node): return
		var t = create_tween()
		t.tween_property(node, "modulate:a", 0.0, 0.5)
		t.tween_callback(func():
			if is_instance_valid(node): node.queue_free()
			if callback.is_valid(): callback.call()
		)
	)

func _animate_slide_in(node: Control, from_offset: Vector2):
	node.position += from_offset
	node.modulate.a = 0.0
	var t = create_tween().set_parallel(true)
	t.tween_property(node, "position", node.position - from_offset, 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "modulate:a", 1.0, 0.4)

func _animate_scan_in(node: Control):
	node.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(node, "modulate:a", 1.0, 0.3)

func _animate_warning_pulse(node: Control):
	node.modulate.a = 1.0
	var t = create_tween().set_loops(0)
	t.tween_property(node, "modulate:a", 0.4, 0.5)
	t.tween_property(node, "modulate:a", 1.0, 0.5)

func _animate_data_reveal(root: Control, label_name: String):
	var lbl = root.get_node_or_null(label_name)
	if not lbl is Label: return
	var full_text = lbl.text
	lbl.text = ""
	root.modulate.a = 1.0
	var timer = root.get_tree().create_timer(0.0)
	for c in full_text:
		await timer.timeout
		lbl.text += c
		timer = root.get_tree().create_timer(0.04)

func _animate_bar(bar: Control, target_ratio: float):
	var t = create_tween()
	t.tween_property(bar, "custom_minimum_size:x", target_ratio * 400.0, 1.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _animate_glitch_reveal(node: Control):
	node.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(node, "modulate:a", 1.0, 0.1)
	t.tween_property(node, "modulate:a", 0.2, 0.05)
	t.tween_property(node, "modulate:a", 1.0, 0.05)
	t.tween_property(node, "modulate:a", 0.5, 0.05)
	t.tween_property(node, "modulate:a", 1.0, 0.3)

func _animate_auth_screen(node: Control):
	node.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(node, "modulate:a", 1.0, 1.0)
