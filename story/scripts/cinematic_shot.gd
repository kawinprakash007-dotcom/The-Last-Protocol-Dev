## CinematicShot — One discrete unit of a cinematic sequence.
##
## A CinematicShot defines what happens during one camera "shot":
## which camera move plays, what dialogue runs, what audio fires, etc.
##
## Assign these in the Inspector or build them in code.
## Group them into a CinematicSequence.
##
class_name CinematicShot
extends Resource

## Unique identifier for this shot. Used in debug output.
## Example: "shot_01_black_screen", "shot_04_pod_release"
@export var shot_id: String = ""

## How long this shot runs in seconds.
## If a DialogueSequence is attached and requires player input,
## the shot will wait for dialogue to finish before this timer matters.
## Set to 0.0 to advance immediately after the dialogue sequence ends.
@export var duration: float = 2.0

## Camera action type. Used by a CinematicCameraController when available.
## Valid values: "STATIC", "LOOK_AT", "MOVE_TO", "MOVE_AND_LOOK", "CUT"
@export var camera_action: String = "STATIC"

## NodePath to the camera marker/position target. Optional.
## Used by the cinematic camera controller to know where to move.
@export var camera_target: NodePath = NodePath("")

## Optional NodePath for LOOK_AT / MOVE_AND_LOOK shots.
@export var look_target: NodePath = NodePath("")

## Camera transition type. Valid values: "CUT", "LINEAR", "EASE_IN",
## "EASE_OUT", "EASE_IN_OUT"
@export var camera_transition: String = "CUT"

## Duration for camera movement in seconds. 0.0 uses an instant cut.
@export var camera_transition_duration: float = 0.0

## Optional fade instruction. Valid values: "", "FADE_IN", "FADE_OUT",
## "FADE_TO_BLACK", "FADE_FROM_BLACK"
@export var fade_action: String = ""

## Duration for fade action in seconds.
@export var fade_duration: float = 0.5

## UI event key to send at shot start.
## Valid values: "SHOW_DIAGNOSTIC", "SHOW_DIALOGUE", "HIDE_ALL", "SHOW_OBJECTIVE", ""
@export var ui_event: String = ""

## Optional dialogue sequence to play during this shot.
## Leave null if this shot has no dialogue.
@export var dialogue_sequence: DialogueSequence

## StoryAudioManager key for the music to play at shot start.
## Leave empty to keep current music. Use "SILENCE" to stop music.
@export var music_key: String = ""

## StoryAudioManager key for ambience to play at shot start.
## Leave empty to keep current ambience. Use "SILENCE" to stop ambience.
@export var ambience_key: String = ""

## StoryAudioManager keys for SFX to fire at shot start.
## Each key maps to a sound in StoryAudioManager.sfx_streams.
@export var sfx_keys: Array[String] = []

## If true, player input is disabled during this shot.
## NOTE (per architecture approval): _physics_process is NOT disabled.
## Only input-driven movement and interaction are locked.
@export var lock_player: bool = false

## EventBus.story_event_triggered key to emit at the START of this shot.
## Leave empty for no event. Useful for triggering gameplay reactions at shot entry.
@export var story_event_on_start: String = ""

## EventBus.story_event_triggered key to emit when this shot FINISHES.
## Leave empty for no event.
@export var on_complete: String = ""

## Optional path to a video resource to play during this shot.
@export var video_path: String = ""

## If true, this shot is played as a pre-rendered video rather than real-time 3D.
@export var is_video: bool = false

## If true, automatically advance to the next shot when the video completes.
@export var video_auto_advance: bool = true

## If true, this shot blocks progression until the player confirms authorization.
@export var is_authorization: bool = false

## If true, this shot blocks progression until the player confirms the Last Protocol.
@export var is_last_protocol: bool = false

## If true, this shot presents an interactive story choice panel (Interaction A/C/D).
## CinematicManager will instantiate InteractiveChoiceUI and wait for the player's selection.
@export var is_choice: bool = false

## Configuration dictionary for an is_choice shot.
## Required keys: "terminal_id", "title", "prompt", "state_key", "options", "results"
## Optional keys: "node_id", "authority", "condition"
## Same format as InteractiveChoiceUI.show_choice().
@export var choice_config: Dictionary = {}

## Optional narration lines spoken by Ryan Vance during this shot.
## Displayed as cinematic subtitles. Can optionally drive StoryAudioManager voice playback.
## Lines are shown sequentially with timed pauses between them.
## Empty array = no narration for this shot.
@export var narration_lines: Array[String] = []

## Optional HUD metadata key-value pairs to display during this shot.
## Keys: "YEAR", "LOCATION", "SYSTEM", "CREATOR", "PROTOCOL"
## Example: {"YEAR": "2047", "LOCATION": "VANCE LABORATORY"}
## Empty dict = no HUD metadata display for this shot.
@export var hud_metadata: Dictionary = {}
