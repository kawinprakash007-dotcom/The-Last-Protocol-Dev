## CinematicSequence — An ordered collection of CinematicShots.
##
## Load this Resource into CinematicManager.play_sequence() to run a cinematic.
## Create .tres instances in res://story/data/sequences/
##
class_name CinematicSequence
extends Resource

## Unique identifier for this sequence. Used in EventBus signals.
## Example: "opening_prologue", "vance_wakeup", "final_elevator"
@export var sequence_id: String = ""

## The ordered list of shots that make up this cinematic.
@export var shots: Array[CinematicShot] = []

## Scene path to transition to when the sequence ends.
## Leave empty to return to gameplay without a scene change.
## Example: "res://main.tscn", "res://story/scenes/sector_09.tscn"
@export var on_end_scene: String = ""
