## EventBus — Global signal hub for all story/cinematic/gameplay communication.
##
## AUTOLOAD: Registered as "EventBus" in project.godot.
##
## Rules:
##   - EventBus transports events ONLY. It contains zero game logic.
##   - No system should directly reference another system's node path.
##     Use EventBus signals to communicate across system boundaries.
##   - Connect to these signals from _ready(). Disconnect if the node is freed.
##
## Team Ownership: Story Team
## Shared Signal Contract: Agreed with Gameplay Team before modifying signal signatures.
##
extends Node


# ── CINEMATIC SIGNALS ──────────────────────────────────────────────────────────

## Emitted when a CinematicSequence begins playing.
## @param sequence_id: String — the sequence_id of the CinematicSequence resource.
signal cinematic_started(sequence_id: String)

## Emitted when a CinematicSequence finishes all shots.
## @param sequence_id: String — the sequence_id of the finished sequence.
signal cinematic_finished(sequence_id: String)

## Emitted to lock or unlock player INPUT (not physics).
## When locked = true: gameplay input handlers should stop accepting movement/interaction.
## When locked = false: gameplay input handlers should resume normally.
## NOTE: _physics_process() is deliberately NOT affected by this signal.
signal cinematic_mode_toggled(locked: bool)

## Emitted by CinematicManager when a shot's ui_event field is non-empty.
## UI systems (DialogueUI, ObjectiveHUD, etc.) should listen to this signal
## to show/hide panels without the cinematic system referencing them directly.
## @param ui_event: String — the event key from CinematicShot.ui_event.
##   Valid values: "SHOW_DIAGNOSTIC", "SHOW_DIALOGUE", "HIDE_ALL",
##                 "SHOW_OBJECTIVE", "SHOW_WARNING", "SHOW_SUBTITLE"
signal cinematic_ui_event(ui_event: String)


# ── DIALOGUE SIGNALS ────────────────────────────────────────────────────────────

## Emitted when a DialogueSequence begins.
## @param sequence_id: String
signal dialogue_started(sequence_id: String)

## Emitted each time a single DialogueLine is shown on screen.
## @param line: DialogueLine — the resource being displayed.
signal dialogue_line_shown(line: DialogueLine)

## Emitted when a DialogueSequence finishes all lines.
## @param sequence_id: String
signal dialogue_finished(sequence_id: String)

## Emitted when the player skips an entire dialogue sequence.
## @param sequence_id: String
signal sequence_skipped(sequence_id: String)


# ── OBJECTIVE SIGNALS ───────────────────────────────────────────────────────────

## Emitted to show a new objective in the ObjectiveHUD.
## @param text: String — the objective description to display.
signal objective_started(text: String)

## Emitted to update the current objective text in place.
## @param text: String — the new objective text.
signal objective_updated(text: String)

## Emitted when the current objective has been satisfied.
signal objective_completed()


# ── STORY EVENT SIGNALS ─────────────────────────────────────────────────────────

## Emitted by gameplay systems (triggers, zones, interactables) when
## a named story event occurs. StoryManager listens to this signal.
## @param event_id: String — a named event key, e.g. "player_entered_pod_room"
signal story_event_triggered(event_id: String)


# ── AUDIO REQUEST SIGNALS ───────────────────────────────────────────────────────

## Emitted to request a music track change.
## @param key: String — audio key to look up in StoryAudioManager.music_streams.
signal music_change_requested(key: String)

## Emitted to request an ambience track change.
## @param key: String — audio key to look up in StoryAudioManager.ambience_streams.
signal ambience_change_requested(key: String)


# ── NARRATION SIGNALS (Phase 15) ────────────────────────────────────────────────

## Emitted by NarrationManager when a narration line is ready to display.
## @param shot_id: String — the shot this line belongs to (for stale-guard).
## @param speaker: String — speaker identifier, e.g. "RYAN VANCE".
## @param text: String — the line of narration text.
## @param duration: float — how long to display the line in seconds.
signal narration_line_shown(shot_id: String, speaker: String, text: String, duration: float)

## Emitted by NarrationManager when all lines for a shot are done.
## @param shot_id: String
signal narration_finished(shot_id: String)

## Emitted to show or hide the cinematic letterbox bars.
## @param visible: bool — true = bars slide in, false = bars slide out.
signal letterbox_toggled(visible: bool)

## Emitted when a shot begins with HUD metadata to display.
## @param metadata: Dictionary — key-value pairs, e.g. {"YEAR": "2047"}.
signal hud_metadata_shown(metadata: Dictionary)


# ── GAMEPLAY INTERACTION SIGNALS (Phase 16) ─────────────────────────────────────

## Emitted when the player selects a choice in an InteractiveChoiceUI panel.
## @param state_key: String — the StoryState key the choice is stored under.
## @param choice: String — the value of the selected option.
signal story_choice_made(state_key: String, choice: String)

## Emitted when an interactive terminal interaction begins (player locked).
## @param terminal_id: String — identifier of the terminal.
signal player_interaction_started(terminal_id: String)

## Emitted when an interactive terminal interaction ends (player unlocked).
## @param terminal_id: String — identifier of the terminal.
signal player_interaction_finished(terminal_id: String)

## Emitted by CinematicManager's choice shot handler when the player completes a
## story choice inside the cinematic sequence. CinematicManager listens one-shot to advance.
## @param shot_id: String — the shot_id of the is_choice CinematicShot.
## @param choice: String — the selected option value.
signal cinematic_choice_completed(shot_id: String, choice: String)
