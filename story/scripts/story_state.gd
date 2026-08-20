## StoryState — Lightweight persistent player-decision store.
##
## AUTOLOAD: Registered as "StoryState" in project.godot.
##
## Records choices and story flags that future cinematics, dialogue,
## and gameplay can read without coupling systems directly together.
##
## Usage:
##   StoryState.set_state("permission_choice", "granted")
##   StoryState.get_state("permission_choice")         # → "granted"
##   StoryState.has_state("permission_choice")         # → true
##
## Keys used by Phase 16:
##   "permission_choice"   → "granted" | "denied"
##   "diagnostic_answer"   → "SECURITY NETWORK" | "AUTONOMOUS AUTHORITY" | "POWER GRID"
##
## Team Ownership: Story Team
##
extends Node


var _state: Dictionary = {}


# ── PUBLIC API ──────────────────────────────────────────────────────────────────

## Store a key-value decision.
func set_state(key: String, value: Variant) -> void:
	if key.is_empty():
		push_warning("StoryState: set_state() called with empty key.")
		return
	_state[key] = value


## Retrieve a stored value. Returns default if key was never set.
func get_state(key: String, default: Variant = null) -> Variant:
	return _state.get(key, default)


## Returns true if the key has been set at least once.
func has_state(key: String) -> bool:
	return _state.has(key)


## Remove a single key.
func clear_state(key: String) -> void:
	_state.erase(key)


## Wipe all state (call between major sessions if needed).
func reset_all() -> void:
	_state.clear()


## Dump current state to console (debug only).
func debug_print() -> void:
	if OS.is_debug_build():
		print("[StoryState] current state: ", _state)
