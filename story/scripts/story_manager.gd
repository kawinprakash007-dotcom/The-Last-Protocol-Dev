## StoryManager — Entry point for all story events from gameplay.
##
## AUTOLOAD: Registered as "StoryManager" in project.godot.
##
## Usage (from gameplay triggers / interactables):
##   EventBus.story_event_triggered.emit("player_entered_pod_room")
##   StoryManager.trigger_event("player_found_terminal")
##
## StoryManager maps event IDs to CinematicSequences or DialogueSequences
## and delegates to CinematicManager or DialogueManager accordingly.
##
## To register a story event response, call:
##   StoryManager.register_event("event_id", my_cinematic_sequence)
##   StoryManager.register_dialogue_event("event_id", my_dialogue_sequence)
##
## Team Ownership: Story Team
## Story events are the agreed interface point with the Gameplay Team.
##
extends Node


# ── REGISTRY ───────────────────────────────────────────────────────────────────
## Maps event_id -> CinematicSequence
var _cinematic_registry: Dictionary = {}

## Maps event_id -> DialogueSequence
var _dialogue_registry: Dictionary = {}

## Tracks which events have already fired (to prevent repeat triggers).
var _fired_events: Dictionary = {}


# ── LIFECYCLE ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	EventBus.story_event_triggered.connect(_on_story_event_triggered)


# ── PUBLIC API ─────────────────────────────────────────────────────────────────

## Register a CinematicSequence to play when event_id fires.
## Call this from a level script or game initializer, not from player.gd.
func register_event(event_id: String, sequence: CinematicSequence) -> void:
	if event_id.is_empty():
		push_warning("StoryManager: register_event() called with empty event_id.")
		return
	if sequence == null:
		push_warning("StoryManager: register_event() called with null sequence for '%s'." % event_id)
		return
	_cinematic_registry[event_id] = sequence


## Register a DialogueSequence to play when event_id fires.
func register_dialogue_event(event_id: String, sequence: DialogueSequence) -> void:
	if event_id.is_empty():
		push_warning("StoryManager: register_dialogue_event() called with empty event_id.")
		return
	if sequence == null:
		push_warning("StoryManager: register_dialogue_event() called with null sequence for '%s'." % event_id)
		return
	_dialogue_registry[event_id] = sequence


## Manually trigger a named story event from code.
## Same as emitting EventBus.story_event_triggered(event_id).
func trigger_event(event_id: String) -> void:
	if event_id.is_empty():
		push_warning("StoryManager: trigger_event() called with empty event_id.")
		return
	EventBus.story_event_triggered.emit(event_id)


## Clear all registered events (use between major scenes to avoid stale triggers).
func clear_registry() -> void:
	_cinematic_registry.clear()
	_dialogue_registry.clear()
	_fired_events.clear()


## Returns true if the named event has already fired this session.
func has_event_fired(event_id: String) -> bool:
	return _fired_events.has(event_id)


# ── INTERNAL ───────────────────────────────────────────────────────────────────

func _on_story_event_triggered(event_id: String) -> void:
	# Check cinematic registry first
	if _cinematic_registry.has(event_id):
		if CinematicManager.is_active:
			push_warning(
				"StoryManager: Event '%s' fired but a cinematic is already active. "
				% event_id + "Ignoring."
			)
			return
		_fired_events[event_id] = true
		CinematicManager.play_sequence(_cinematic_registry[event_id])
		return

	# Check dialogue registry
	if _dialogue_registry.has(event_id):
		if DialogueManager.is_active:
			push_warning(
				"StoryManager: Event '%s' fired but dialogue is already active. "
				% event_id + "Ignoring."
			)
			return
		_fired_events[event_id] = true
		DialogueManager.start_sequence(_dialogue_registry[event_id])
		return

	# Event is not registered — not necessarily an error (gameplay may fire events
	# that story hasn't wired up yet, especially during development).
	# Use push_warning only in debug builds to avoid log spam in release.
	if OS.is_debug_build():
		push_warning(
			"StoryManager: Unregistered event '%s' received. "
			% event_id + "No sequence mapped."
		)
