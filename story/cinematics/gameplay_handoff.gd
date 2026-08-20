## GameplayHandoff — Cinematic transition bridge between the final cinematic and gameplay.
##
## This scene plays after the Last Protocol sequence ends and before main.tscn loads.
## It creates the "the movie just became the game" moment:
##
##   Black screen
##   → Heartbeat audio cue
##   → Ambient hum
##   → Ryan Vance: "...wake up."
##   → Slow fade to main.tscn
##
## The player is NOT in control during this scene.
## No HUD. No player character. Pure transition.
##
## Team Ownership: Story Team
##
extends Node


const MAIN_SCENE: String = "res://main.tscn"
const HEARTBEAT_KEY: String = "handoff_heartbeat"
const AMBIENT_KEY: String = "handoff_ambient"
const WAKEUP_LINE: String = "...wake up."
const WAKEUP_SPEAKER: String = "SYSTEM"

## Total duration of the handoff sequence in seconds before loading gameplay.
const HANDOFF_DURATION: float = 4.0
const FADE_OUT_DURATION: float = 2.0


func _ready() -> void:
	# Ensure the screen is black to start
	_set_overlay_alpha(1.0)
	_run_handoff()


func _run_handoff() -> void:
	# Brief pause in darkness — let the player absorb the last frame
	await get_tree().create_timer(0.8).timeout

	# Play ambient sound cues via StoryAudioManager (silently skipped if not registered)
	if StoryAudioManager.ambience_streams.has(AMBIENT_KEY):
		StoryAudioManager.play_ambience(AMBIENT_KEY)
	if StoryAudioManager.sfx_streams.has(HEARTBEAT_KEY):
		StoryAudioManager.play_sfx(HEARTBEAT_KEY)

	# Show the wake-up subtitle line
	EventBus.narration_line_shown.emit("handoff", WAKEUP_SPEAKER, WAKEUP_LINE, 3.0)

	await get_tree().create_timer(1.5).timeout

	# Slow fade out of black — transition begins
	var tween := create_tween()
	tween.tween_method(_set_overlay_alpha, 1.0, 0.0, FADE_OUT_DURATION)
	await tween.finished

	# Brief moment visible then load gameplay
	await get_tree().create_timer(0.3).timeout

	# Notify subtitle to clear
	EventBus.narration_finished.emit("handoff")

	# Hide letterbox before gameplay
	EventBus.letterbox_toggled.emit(false)

	# Hand back control to gameplay
	CutsceneManager.finish_cutscene()


func _set_overlay_alpha(alpha: float) -> void:
	var overlay := get_node_or_null("FadeOverlay")
	if overlay:
		overlay.modulate.a = alpha
