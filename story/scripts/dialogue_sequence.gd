## DialogueSequence — An ordered collection of DialogueLines.
##
## Load this Resource into DialogueManager.start_sequence() to play a conversation.
## Create .tres instances of this resource in res://story/data/dialogue/
##
class_name DialogueSequence
extends Resource

## Unique identifier for this sequence. Used in EventBus signals.
## Example: "opening_radio_transmission", "vance_wakeup_01"
@export var sequence_id: String = ""

## The ordered list of dialogue lines to play.
@export var lines: Array[DialogueLine] = []

## Name of the EventBus signal to emit when the entire sequence ends.
## Leave empty for no event.
@export var on_end_event: String = ""
