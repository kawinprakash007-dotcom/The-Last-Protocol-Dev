## GameplayController — Orchestrates Phase 16 first gameplay segment.
##
## Attached to the Main node in main.tscn.
## Manages the cinematic gameplay loop:
##
##   WAKE UP MOMENT
##   → Player gains control
##   → Explores corridor
##   → TERMINAL 1: Emergency Permission (x > 520)
##   → Player continues
##   → TERMINAL 2: System Diagnostic (x > 820)
##   → Player continues
##   → Loop / next story beat
##
## Team Ownership: Story Team
##
extends Node2D


# ── CONFIG ──────────────────────────────────────────────────────────────────────
const TERMINAL1_TRIGGER_X: float = 520.0
const TERMINAL2_TRIGGER_X: float = 820.0

## Emergency Permission choice config.
const EMERGENCY_CONFIG: Dictionary = {
	"terminal_id": "emergency_terminal",
	"title":       "EMERGENCY SYSTEM ACCESS REQUEST",
	"node_id":     "NETWORK NODE: SECTOR 07",
	"authority":   "VERIFIED",
	"condition":   "UNSTABLE",
	"prompt":      "A damaged service robot is requesting temporary access to the sector grid.",
	"state_key":   "permission_choice",
	"options": [
		{"label": "GRANT LIMITED ACCESS", "value": "granted"},
		{"label": "DENY ACCESS",          "value": "denied"},
	],
	"results": {
		"granted": {
			"main":  "LIMITED ACCESS GRANTED",
			"sub":   "Service robot authorized. Door lock disengaged.",
			"color": "success",
		},
		"denied": {
			"main":  "ACCESS DENIED",
			"sub":   "Authority rejected. Alternate route available.",
			"color": "warn",
		},
	},
}

## System Diagnostic choice config.
const DIAGNOSTIC_CONFIG: Dictionary = {
	"terminal_id": "diagnostic_terminal",
	"title":       "SYSTEM QUERY",
	"node_id":     "DIAGNOSTIC TERMINAL v4.2",
	"authority":   "VERIFIED",
	"condition":   "CRITICAL",
	"prompt":      "The authority network is attempting to regain control.\nWhich subsystem should be isolated first?",
	"state_key":   "diagnostic_answer",
	"options": [
		{"label": "SECURITY NETWORK",      "value": "SECURITY NETWORK"},
		{"label": "AUTONOMOUS AUTHORITY",  "value": "AUTONOMOUS AUTHORITY"},
		{"label": "POWER GRID",            "value": "POWER GRID"},
	],
	"results": {
		"AUTONOMOUS AUTHORITY": {
			"main":  "AUTONOMOUS AUTHORITY IDENTIFIED",
			"sub":   "Primary control path located. Proceed.",
			"color": "success",
		},
		"SECURITY NETWORK": {
			"main":  "SUBSYSTEM ISOLATED",
			"sub":   "Warning: This will delay network access.",
			"color": "warn",
		},
		"POWER GRID": {
			"main":  "SUBSYSTEM ISOLATED",
			"sub":   "Warning: This will delay network access.",
			"color": "warn",
		},
	},
}


# ── INTERNAL STATE ──────────────────────────────────────────────────────────────
var _terminal1_fired: bool = false
var _terminal2_fired: bool = false
var _player: RyanPlayer     = null
var _choice_ui             = null   # InteractiveChoiceUI instance
var _subtitle              = null   # CinematicSubtitle instance
var _t1_prompt: Label      = null
var _t2_prompt: Label      = null
var _t1_glow: ColorRect    = null
var _t2_glow: ColorRect    = null


func _ready() -> void:
	_player    = get_node_or_null("RyanPlayer")
	_choice_ui = get_node_or_null("InteractiveChoiceUI")
	_subtitle  = get_node_or_null("CinematicSubtitle")
	_t1_prompt = get_node_or_null("EmergencyTerminal/PromptLabel")
	_t2_prompt = get_node_or_null("DiagnosticTerminal/PromptLabel")
	_t1_glow   = get_node_or_null("EmergencyTerminal/ScreenGlow")
	_t2_glow   = get_node_or_null("DiagnosticTerminal/ScreenGlow")

	EventBus.story_choice_made.connect(_on_choice_made)

	# Start with player locked — show wake-up moment
	EventBus.cinematic_mode_toggled.emit(true)
	_run_wakeup()


func _process(_delta: float) -> void:
	if _player == null:
		return

	var px: float = _player.get_x()

	# Show/hide terminal prompts based on proximity
	_update_terminal_prompt(_t1_prompt, _t1_glow, px, 650.0, _terminal1_fired)
	_update_terminal_prompt(_t2_prompt, _t2_glow, px, 920.0, _terminal2_fired)

	# Trigger Terminal 1
	if not _terminal1_fired and px > TERMINAL1_TRIGGER_X:
		_terminal1_fired = true
		_fire_terminal(EMERGENCY_CONFIG)

	# Trigger Terminal 2 (only after Terminal 1 is complete)
	elif _terminal1_fired and not _terminal2_fired and px > TERMINAL2_TRIGGER_X:
		_terminal2_fired = true
		_fire_terminal(DIAGNOSTIC_CONFIG)


# ── WAKE UP SEQUENCE ────────────────────────────────────────────────────────────

func _run_wakeup() -> void:
	await get_tree().create_timer(0.5).timeout

	# Show contextual subtitle
	EventBus.narration_line_shown.emit("gameplay_start", "SYSTEM", "NETWORK SIGNAL DETECTED.", 3.0)

	await get_tree().create_timer(2.2).timeout
	EventBus.narration_finished.emit("gameplay_start")

	await get_tree().create_timer(0.4).timeout

	# Unlock player — gameplay begins
	EventBus.cinematic_mode_toggled.emit(false)

	# Environmental hint
	await get_tree().create_timer(1.5).timeout
	EventBus.narration_line_shown.emit("gameplay_hint", "SYSTEM", "TERMINAL ACTIVITY DETECTED AHEAD.", 3.5)
	await get_tree().create_timer(3.5).timeout
	EventBus.narration_finished.emit("gameplay_hint")


# ── TERMINAL TRIGGER ────────────────────────────────────────────────────────────

func _fire_terminal(config: Dictionary) -> void:
	if _choice_ui == null:
		push_warning("GameplayController: InteractiveChoiceUI not found.")
		return
	_choice_ui.show_choice(config)


# ── CHOICE CONSEQUENCE ──────────────────────────────────────────────────────────

func _on_choice_made(state_key: String, choice: String) -> void:
	match state_key:
		"permission_choice":
			_handle_permission_result(choice)
		"diagnostic_answer":
			_handle_diagnostic_result(choice)


func _handle_permission_result(choice: String) -> void:
	# Small delay for UI to fully dismiss first
	await get_tree().create_timer(0.8).timeout
	match choice:
		"granted":
			EventBus.narration_line_shown.emit(
				"perm_result", "SYSTEM", "ACCESS DOOR UNLOCKED. PROCEED FORWARD.", 3.5
			)
		"denied":
			EventBus.narration_line_shown.emit(
				"perm_result", "SYSTEM", "ALTERNATE ROUTE AVAILABLE. PROCEED.", 3.5
			)
	await get_tree().create_timer(3.5).timeout
	EventBus.narration_finished.emit("perm_result")


func _handle_diagnostic_result(choice: String) -> void:
	await get_tree().create_timer(0.8).timeout
	if choice == "AUTONOMOUS AUTHORITY":
		EventBus.narration_line_shown.emit(
			"diag_result", "SYSTEM", "OPTIMAL ISOLATION PATH CONFIRMED.", 3.5
		)
	else:
		EventBus.narration_line_shown.emit(
			"diag_result", "SYSTEM", "SUBSYSTEM ISOLATED. EXPECT DELAYS.", 3.5
		)
	await get_tree().create_timer(3.5).timeout
	EventBus.narration_finished.emit("diag_result")


# ── HELPERS ─────────────────────────────────────────────────────────────────────

func _update_terminal_prompt(
		prompt: Label,
		glow: ColorRect,
		player_x: float,
		terminal_x: float,
		already_fired: bool
) -> void:
	if prompt == null or already_fired:
		return
	var dist: float = abs(player_x - terminal_x)
	var near: bool = dist < 130.0
	prompt.visible = near
	if glow:
		var target_a: float = 0.9 if near else 0.4
		glow.modulate.a = lerp(glow.modulate.a, target_a, 0.1)
