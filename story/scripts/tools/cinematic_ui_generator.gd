extends SceneTree

## Phase 12 — Procedural Cinematic UI Generator
## Generates all 10 cinematic UI component scenes into res://story/cinematics/ui/
## All nodes built from Godot's native Control/Panel/Label/AnimationPlayer system.
## No external assets required.

const OUT = "res://story/cinematics/ui/"

# ── Palette ─────────────────────────────────────────────────────────────
const CA  = Color(0.0,  0.67, 1.0,  1.0)   # accent cyan
const CA2 = Color(0.0,  0.67, 1.0,  0.35)  # accent dim
const CBG = Color(0.0,  0.05, 0.1,  0.72)  # glass bg
const CT  = Color(0.85, 0.95, 1.0,  1.0)   # main text
const CTD = Color(0.85, 0.95, 1.0,  0.55)  # dim text
const CW  = Color(1.0,  0.3,  0.1,  1.0)   # warning
const CC  = Color(1.0,  0.0,  0.0,  1.0)   # critical

# ── Utility ──────────────────────────────────────────────────────────────
func _save(node: Control, name: String):
	var ps = PackedScene.new()
	ps.pack(node)
	ResourceSaver.save(ps, OUT + name + ".tscn")
	node.free()
	print("  Saved: " + name + ".tscn")

func _sbox(bg: Color, border: Color = Color(0,0,0,0), bw: int = 1) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(2)
	return s

func _label(parent: Node, node_name: String, text: String,
			color: Color = Color(0.85, 0.95, 1.0, 1.0),
			font_size: int = 14, bold: bool = false) -> Label:
	var l = Label.new()
	l.name = node_name
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	parent.add_child(l)
	l.owner = _root(parent)
	return l

func _root(n: Node) -> Node:
	var r = n
	while r.get_parent() != null: r = r.get_parent()
	return r

func _hline(parent: Node, color: Color, h: int = 1) -> ColorRect:
	var cr = ColorRect.new()
	cr.name = "HLine"
	cr.color = color
	cr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cr.custom_minimum_size = Vector2(0, h)
	parent.add_child(cr)
	cr.owner = _root(parent)
	return cr

func _anim_player(parent: Node) -> AnimationPlayer:
	var a = AnimationPlayer.new()
	a.name = "AnimationPlayer"
	parent.add_child(a)
	a.owner = _root(parent)
	return a

# ── Scan-line shader (reused by multiple components) ─────────────────────
func _scan_shader() -> ShaderMaterial:
	var sm = ShaderMaterial.new()
	var sh = Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float speed : hint_range(0.1, 5.0) = 1.5;
uniform float line_density : hint_range(10.0, 200.0) = 80.0;
uniform float line_opacity : hint_range(0.0, 1.0) = 0.08;
void fragment() {
	float line = mod(UV.y * line_density - TIME * speed, 1.0);
	float alpha = smoothstep(0.0, 0.05, line) * (1.0 - smoothstep(0.95, 1.0, line));
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= mix(1.0 - line_opacity, 1.0, 1.0 - alpha);
}
"""
	sm.shader = sh
	return sm

# ════════════════════════════════════════════════════════════════════════
# 1. YearMarker
# ════════════════════════════════════════════════════════════════════════
func _gen_year_marker():
	var root = Control.new()
	root.name = "YearMarker"
	root.set_anchor_and_offset(SIDE_LEFT,  0, 60)
	root.set_anchor_and_offset(SIDE_TOP,   0, 80)
	root.custom_minimum_size = Vector2(400, 64)

	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", _sbox(CBG, CA2))
	panel.custom_minimum_size = Vector2(400, 64)
	root.add_child(panel); panel.owner = root

	var vbox = VBoxContainer.new()
	panel.add_child(vbox); vbox.owner = root

	# Thin accent top line
	var line_top = ColorRect.new()
	line_top.name = "AccentTop"
	line_top.color = CA
	line_top.custom_minimum_size = Vector2(0, 2)
	line_top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(line_top); line_top.owner = root

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox); hbox.owner = root

	# Small diamond decorator
	var dot = ColorRect.new()
	dot.name = "Dot"
	dot.color = CA
	dot.custom_minimum_size = Vector2(6, 6)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(dot); dot.owner = root

	var lbl = Label.new()
	lbl.name = "Label"
	lbl.text = "YEAR 01"
	lbl.add_theme_color_override("font_color", CT)
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(lbl); lbl.owner = root

	# Scan shader on panel
	panel.material = _scan_shader()

	_save(root, "YearMarker")

# ════════════════════════════════════════════════════════════════════════
# 2. SystemStatus
# ════════════════════════════════════════════════════════════════════════
func _gen_system_status():
	var root = Control.new()
	root.name = "SystemStatus"
	root.set_anchor_and_offset(SIDE_LEFT,  0, 60)
	root.set_anchor_and_offset(SIDE_TOP,   0, 160)
	root.custom_minimum_size = Vector2(320, 48)

	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", _sbox(Color(0,0.05,0.1,0.55), CA2))
	root.add_child(panel); panel.owner = root

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox); hbox.owner = root

	var tick = Label.new()
	tick.name = "Tick"
	tick.text = "▶"
	tick.add_theme_color_override("font_color", CA)
	tick.add_theme_font_size_override("font_size", 10)
	tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(tick); tick.owner = root

	var lbl = Label.new()
	lbl.name = "StatusLabel"
	lbl.text = "SYSTEMS ONLINE"
	lbl.add_theme_color_override("font_color", CT)
	lbl.add_theme_font_size_override("font_size", 13)
	hbox.add_child(lbl); lbl.owner = root

	_save(root, "SystemStatus")

# ════════════════════════════════════════════════════════════════════════
# 3. RobotDiagnostic
# ════════════════════════════════════════════════════════════════════════
func _gen_robot_diagnostic():
	var root = Control.new()
	root.name = "RobotDiagnostic"
	root.set_anchor_and_offset(SIDE_RIGHT, 1, -320)
	root.set_anchor_and_offset(SIDE_TOP,   0, 80)
	root.custom_minimum_size = Vector2(280, 200)

	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", _sbox(CBG, CA2))
	panel.custom_minimum_size = Vector2(280, 200)
	root.add_child(panel); panel.owner = root

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox); vbox.owner = root

	# Header
	var hdr = Label.new()
	hdr.name = "Header"
	hdr.text = "ROBOT DIAGNOSTIC"
	hdr.add_theme_color_override("font_color", CA)
	hdr.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hdr); hdr.owner = root

	var line = ColorRect.new()
	line.color = CA2
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(line); line.owner = root

	# Diagnostic rows
	var rows = [
		["SERVO SYSTEMS", "NOMINAL"],
		["POWER CORE", "ACTIVE"],
		["OPTICAL SENSORS", "ONLINE"],
		["JOINTS", "CALIBRATED"],
		["NEURAL NET", "SYNCED"],
		["COMMS LINK", "SECURE"],
	]
	for i in rows.size():
		var hbox = HBoxContainer.new()
		hbox.name = "Row%d" % i
		vbox.add_child(hbox); hbox.owner = root
		var key = Label.new()
		key.text = rows[i][0]
		key.add_theme_color_override("font_color", CTD)
		key.add_theme_font_size_override("font_size", 10)
		key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(key); key.owner = root
		var val = Label.new()
		val.text = rows[i][1]
		val.add_theme_color_override("font_color", CA)
		val.add_theme_font_size_override("font_size", 10)
		hbox.add_child(val); val.owner = root

	panel.material = _scan_shader()
	_save(root, "RobotDiagnostic")

# ════════════════════════════════════════════════════════════════════════
# 4. NetworkStatus
# ════════════════════════════════════════════════════════════════════════
func _gen_network_status():
	var root = Control.new()
	root.name = "NetworkStatus"
	root.set_anchor_and_offset(SIDE_LEFT,  0, 60)
	root.set_anchor_and_offset(SIDE_BOTTOM, 1, -100)
	root.custom_minimum_size = Vector2(440, 56)

	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", _sbox(CBG, CA2))
	root.add_child(panel); panel.owner = root

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox); vbox.owner = root

	var lbl = Label.new()
	lbl.name = "TitleLabel"
	lbl.text = "AUTOMATION NETWORK: 42%"
	lbl.add_theme_color_override("font_color", CT)
	lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(lbl); lbl.owner = root

	# Bar track
	var track = Control.new()
	track.name = "BarTrack"
	track.custom_minimum_size = Vector2(400, 6)
	vbox.add_child(track); track.owner = root

	var track_bg = ColorRect.new()
	track_bg.name = "BarBG"
	track_bg.color = Color(0,0.67,1, 0.12)
	track_bg.set_anchor_and_offset(SIDE_LEFT, 0, 0)
	track_bg.set_anchor_and_offset(SIDE_TOP, 0, 0)
	track_bg.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
	track_bg.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
	track.add_child(track_bg); track_bg.owner = root

	var bar = ColorRect.new()
	bar.name = "Bar"
	bar.color = CA
	bar.set_anchor_and_offset(SIDE_LEFT, 0, 0)
	bar.set_anchor_and_offset(SIDE_TOP, 0, 0)
	bar.set_anchor_and_offset(SIDE_RIGHT, 0, 0)  # animated by master
	bar.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
	bar.custom_minimum_size = Vector2(0, 6)
	track.add_child(bar); bar.owner = root

	_save(root, "NetworkStatus")

# ════════════════════════════════════════════════════════════════════════
# 5. CityStatus
# ════════════════════════════════════════════════════════════════════════
func _gen_city_status():
	var root = Control.new()
	root.name = "CityStatus"
	root.set_anchor_and_offset(SIDE_RIGHT, 1, -320)
	root.set_anchor_and_offset(SIDE_BOTTOM, 1, -100)
	root.custom_minimum_size = Vector2(260, 100)

	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", _sbox(CBG, CA2))
	root.add_child(panel); panel.owner = root

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox); vbox.owner = root

	var hdr = Label.new()
	hdr.name = "Header"
	hdr.text = "CITY STATUS"
	hdr.add_theme_color_override("font_color", CA)
	hdr.add_theme_font_size_override("font_size", 10)
	vbox.add_child(hdr); hdr.owner = root

	var line = ColorRect.new()
	line.color = CA2
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(line); line.owner = root

	for row in [["POPULATION", "8.2M"], ["INFRASTRUCTURE", "OPERATIONAL"], ["NETWORK UPTIME", "99.7%"]]:
		var hbox = HBoxContainer.new()
		vbox.add_child(hbox); hbox.owner = root
		var k = Label.new(); k.text = row[0]
		k.add_theme_color_override("font_color", CTD)
		k.add_theme_font_size_override("font_size", 10)
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(k); k.owner = root
		var v = Label.new(); v.text = row[1]
		v.add_theme_color_override("font_color", CT)
		v.add_theme_font_size_override("font_size", 10)
		hbox.add_child(v); v.owner = root

	_save(root, "CityStatus")

# ════════════════════════════════════════════════════════════════════════
# 6. WarningOverlay — Corner bracket style, NOT full screen
# ════════════════════════════════════════════════════════════════════════
func _gen_warning_overlay():
	var root = Control.new()
	root.name = "WarningOverlay"
	# Full viewport but transparent — only corners are visible
	root.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	root.set_anchor_and_offset(SIDE_TOP,    0, 0)
	root.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	root.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Top-left corner bracket
	for pos in [Vector2(20,20), Vector2(-20,20), Vector2(20,-20), Vector2(-20,-20)]:
		var br = ColorRect.new()
		br.color = CW
		br.custom_minimum_size = Vector2(40, 2)
		br.position = Vector2(
			20 if pos.x > 0 else root.size.x - 60,
			20 if pos.y > 0 else root.size.y - 22
		)
		root.add_child(br); br.owner = root

	# Central warning label — small, not covering scene
	var lbl = Label.new()
	lbl.name = "WarnLabel"
	lbl.text = "WARNING"
	lbl.add_theme_color_override("font_color", CW)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.set_anchor_and_offset(SIDE_LEFT,   0, 60)
	lbl.set_anchor_and_offset(SIDE_BOTTOM, 1, -60)
	root.add_child(lbl); lbl.owner = root

	_save(root, "WarningOverlay")

# ════════════════════════════════════════════════════════════════════════
# 7. MissionTitle
# ════════════════════════════════════════════════════════════════════════
func _gen_mission_title():
	var root = Control.new()
	root.name = "MissionTitle"
	root.set_anchor_and_offset(SIDE_LEFT,  0, 0)
	root.set_anchor_and_offset(SIDE_TOP,   0, 0)
	root.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
	root.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var lbl = Label.new()
	lbl.name = "TitleLabel"
	lbl.text = "THE LAST PROTOCOL"
	lbl.add_theme_color_override("font_color", CT)
	lbl.add_theme_font_size_override("font_size", 42)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	lbl.set_anchor_and_offset(SIDE_TOP,    0, 0)
	lbl.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	lbl.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
	root.add_child(lbl); lbl.owner = root

	# Thin horizontal accent line under title
	var line = ColorRect.new()
	line.name = "AccentLine"
	line.color = CA
	line.custom_minimum_size = Vector2(200, 1)
	line.set_anchor_and_offset(SIDE_LEFT,   0.5, -100)
	line.set_anchor_and_offset(SIDE_TOP,    0.5, 30)
	line.set_anchor_and_offset(SIDE_RIGHT,  0.5, 100)
	line.set_anchor_and_offset(SIDE_BOTTOM, 0.5, 31)
	root.add_child(line); line.owner = root

	_save(root, "MissionTitle")

# ════════════════════════════════════════════════════════════════════════
# 8. CinematicSubtitle
# ════════════════════════════════════════════════════════════════════════
func _gen_cinematic_subtitle():
	var root = Control.new()
	root.name = "CinematicSubtitle"
	root.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	root.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	root.set_anchor_and_offset(SIDE_BOTTOM, 1, -40)
	root.custom_minimum_size = Vector2(0, 48)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg = ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0, 0.02, 0.05, 0.55)
	bg.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	bg.set_anchor_and_offset(SIDE_TOP,    0, 0)
	bg.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	bg.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
	root.add_child(bg); bg.owner = root

	var lbl = Label.new()
	lbl.name = "SubtitleLabel"
	lbl.text = ""
	lbl.add_theme_color_override("font_color", CT)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	lbl.set_anchor_and_offset(SIDE_TOP,    0, 0)
	lbl.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	lbl.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
	root.add_child(lbl); lbl.owner = root

	_save(root, "CinematicSubtitle")

# ════════════════════════════════════════════════════════════════════════
# 9. HolographicTerminal
# ════════════════════════════════════════════════════════════════════════
func _gen_holographic_terminal():
	var root = Control.new()
	root.name = "HolographicTerminal"
	root.custom_minimum_size = Vector2(300, 220)

	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", _sbox(Color(0,0.12,0.22,0.78), CA2))
	panel.custom_minimum_size = Vector2(300, 220)
	root.add_child(panel); panel.owner = root

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox); vbox.owner = root

	# Header band
	var hdr_bg = ColorRect.new()
	hdr_bg.color = Color(0, 0.67, 1.0, 0.18)
	hdr_bg.custom_minimum_size = Vector2(0, 28)
	hdr_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(hdr_bg); hdr_bg.owner = root

	var hdr = Label.new()
	hdr.name = "Header"
	hdr.text = "▸ HOLOGRAPHIC TERMINAL"
	hdr.add_theme_color_override("font_color", CA)
	hdr.add_theme_font_size_override("font_size", 11)
	hdr.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	hdr_bg.add_child(hdr); hdr.owner = root

	# Data stream text
	var data = Label.new()
	data.name = "DataStream"
	data.text = "INIT SEQUENCE...\nLOADING NEURAL PROTOCOLS...\nSYNC: 0001 0110 1001 0101\nACCESS: GRANTED\nSTATUS: OPERATIONAL"
	data.add_theme_color_override("font_color", Color(0.5, 1, 0.7, 0.85))
	data.add_theme_font_size_override("font_size", 10)
	data.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(data); data.owner = root

	panel.material = _scan_shader()
	_save(root, "HolographicTerminal")

# ════════════════════════════════════════════════════════════════════════
# 10. AuthorizationScreen — Dramatic, only for AUTHORITY TRANSFER
# ════════════════════════════════════════════════════════════════════════
func _gen_authorization_screen():
	var root = Control.new()
	root.name = "AuthorizationScreen"
	# Semi-transparent overlay — environment still partially visible
	root.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	root.set_anchor_and_offset(SIDE_TOP,    0, 0)
	root.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	root.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Dark-but-transparent overlay (doesn't kill environment)
	var overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0, 0.02, 0.06, 0.80)
	overlay.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	overlay.set_anchor_and_offset(SIDE_TOP,    0, 0)
	overlay.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	overlay.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
	root.add_child(overlay); overlay.owner = root

	# Thin top accent
	var top_line = ColorRect.new()
	top_line.color = CA
	top_line.custom_minimum_size = Vector2(0, 2)
	top_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_line.set_anchor_and_offset(SIDE_LEFT,  0, 0)
	top_line.set_anchor_and_offset(SIDE_TOP,   0, 0)
	top_line.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
	top_line.set_anchor_and_offset(SIDE_BOTTOM, 0, 2)
	root.add_child(top_line); top_line.owner = root

	# Thin bottom accent
	var bot_line = ColorRect.new()
	bot_line.color = CA
	bot_line.custom_minimum_size = Vector2(0, 2)
	bot_line.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	bot_line.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
	bot_line.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	bot_line.set_anchor_and_offset(SIDE_TOP,    1, -2)
	root.add_child(bot_line); bot_line.owner = root

	# Main label — centred but not full-screen text
	var main_lbl = Label.new()
	main_lbl.name = "MainLabel"
	main_lbl.text = "AUTHORITY TRANSFER"
	main_lbl.add_theme_color_override("font_color", CT)
	main_lbl.add_theme_font_size_override("font_size", 36)
	main_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_lbl.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	main_lbl.set_anchor_and_offset(SIDE_TOP,    0.5, -60)
	main_lbl.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	main_lbl.set_anchor_and_offset(SIDE_BOTTOM, 0.5, -10)
	root.add_child(main_lbl); main_lbl.owner = root

	var sub_lbl = Label.new()
	sub_lbl.name = "SubLabel"
	sub_lbl.text = "INITIATING PROTOCOL..."
	sub_lbl.add_theme_color_override("font_color", CA)
	sub_lbl.add_theme_font_size_override("font_size", 14)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	sub_lbl.set_anchor_and_offset(SIDE_TOP,    0.5, 0)
	sub_lbl.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	sub_lbl.set_anchor_and_offset(SIDE_BOTTOM, 0.5, 30)
	root.add_child(sub_lbl); sub_lbl.owner = root

	root.material = _scan_shader()
	_save(root, "AuthorizationScreen")

# ════════════════════════════════════════════════════════════════════════
# ENTRY POINT
# ════════════════════════════════════════════════════════════════════════
func _init():
	print("Phase 12 — Generating Cinematic UI Components...")
	_gen_year_marker()
	_gen_system_status()
	_gen_robot_diagnostic()
	_gen_network_status()
	_gen_city_status()
	_gen_warning_overlay()
	_gen_mission_title()
	_gen_cinematic_subtitle()
	_gen_holographic_terminal()
	_gen_authorization_screen()
	print("Phase 12 — All 10 UI components saved to res://story/cinematics/ui/")
	quit()
