extends Node

## Mission 01: RESTORE COMMUNICATION
## Narrative coordinator — layers story beats on existing GameState signals.
## Creates its own HUD (CanvasLayer) so no scene modifications are needed.

# UI references
var _canvas: CanvasLayer
var _objective_label: Label
var _log_container: VBoxContainer

func _ready() -> void:
	_create_hud()
	_connect_signals()
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

# ── Signal Connections ────────────────────────────────────────────

func _connect_signals() -> void:
	GameState.terminal_online.connect(_on_terminal_online)
	GameState.relay_activated.connect(_on_relay_activated)
	GameState.power_puzzle_reset.connect(_on_puzzle_reset)
	GameState.power_system_online.connect(_on_power_online)
	GameState.comms_online.connect(_on_comms_online)

# ── Narrative Beats ───────────────────────────────────────────────

func _boot_sequence() -> void:
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
	_log("POWER RELAY GRID: SECTOR 02 — ACCESSIBLE")
	_set_objective("RESTORE AUXILIARY POWER")
	await get_tree().create_timer(1.0).timeout
	_log("BULKHEAD UNLOCKED — SECTOR 02 ACCESS GRANTED")

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
