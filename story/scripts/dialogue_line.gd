## DialogueLine — Story Data Resource
##
## One unit of story content.
## Assign these in the Inspector or build them in code.
## Used by DialogueSequence and DialogueManager.
##
## AUDIO DESIGNER: Assign voice_key to match an entry in StoryAudioManager.voice_streams.
## WRITER: Set speaker_id to "GENESIS", "VANCE", "RADIO", "WARDEN", or "NARRATION".
class_name DialogueLine
extends Resource

## Who is speaking. Maps to a visual style in DialogueUI.
## Valid values: "GENESIS", "VANCE", "RADIO", "WARDEN", "NARRATION"
@export var speaker_id: String = ""

## The text that will be displayed. Supports \n for line breaks.
@export_multiline var text: String = ""

## Key used to look up a voice AudioStream in StoryAudioManager.
## Leave empty if no voice audio is available for this line.
@export var voice_key: String = ""

## Visual style override. Leave empty to auto-derive from speaker_id.
## Valid values: "SYSTEM", "DIALOGUE", "NARRATION", "WARNING"
@export var style: String = ""

## Minimum seconds this line stays visible.
## Set to 0.0 to require player input (CONTINUE button).
## Set > 0.0 to auto-advance after this duration if auto_advance is true.
@export var duration: float = 0.0

## If true, the line automatically advances after 'duration' seconds.
## If false, the player must press Continue regardless of duration.
@export var auto_advance: bool = false

## Name of the EventBus signal to emit when this line finishes displaying.
## Leave empty for no event. Example: "story_event_triggered"
@export var on_complete_event: String = ""
