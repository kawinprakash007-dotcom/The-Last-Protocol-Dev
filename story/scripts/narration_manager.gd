## NarrationManager — Cinematic narration voice and subtitle system.
##
## AUTOLOAD: Registered as "NarrationManager" in project.godot.
##
## Responsibilities:
##   - Accepts narration line arrays from CinematicManager at shot start.
##   - Emits EventBus.narration_line_shown for each line (subtitle display).
##   - Calls StoryAudioManager.play_voice() if a matching key is registered.
##   - Ducks music volume during narration and restores after.
##   - Token-guards against stale narration from previous shots.
##   - stop_narration() immediately cancels in-flight narration.
##
## Voice audio is OPTIONAL. If no stream is registered for a key the system
## silently falls through and subtitles still display.
##
## Team Ownership: Story Team
##
extends Node


# ── CONFIGURATION ──────────────────────────────────────────────────────────────

## Seconds between narration lines (the "breath" between sentences).
const LINE_GAP_SECONDS: float = 1.2

## Seconds each line stays on screen if no voice audio is playing.
const DEFAULT_LINE_DURATION: float = 3.5

## Music duck amount in dB when narration is active.
const MUSIC_DUCK_DB: float = -6.0

## Speaker label shown for Ryan's narration.
const RYAN_SPEAKER: String = "RYAN VANCE"

## Prefix used for voice audio key lookup: "{VOICE_KEY_PREFIX}{shot_id}_line_{n:02d}"
## e.g. "tlp_seq01_line_01". Voice designer drops OGG files in and registers them.
const VOICE_KEY_PREFIX: String = "narration_"


# ── INTERNAL STATE ──────────────────────────────────────────────────────────────

var _narration_token: int = 0
var _is_narrating: bool = false
var _music_ducked: bool = false


# ── PUBLIC API ──────────────────────────────────────────────────────────────────

## Begin playing narration lines for a shot.
## @param lines: Array[String] — the ordered lines to display.
## @param shot_id: String — used as stale-guard token and voice key prefix.
## @param speaker: String — override speaker name; defaults to RYAN_SPEAKER.
func play_narration(lines: Array[String], shot_id: String, speaker: String = RYAN_SPEAKER) -> void:
	if lines.is_empty():
		return
	_narration_token += 1
	var token := _narration_token
	_is_narrating = true
	_duck_music(true)
	_run_narration(lines, shot_id, speaker, token)


## Immediately cancel any in-flight narration.
## @param shot_id: String — if provided, only cancels narration for that shot;
##                          pass "" to cancel any narration unconditionally.
func stop_narration(shot_id: String = "") -> void:
	_narration_token += 1
	_is_narrating = false
	_duck_music(false)
	# Emit finished so subtitle UI clears
	if not shot_id.is_empty():
		EventBus.narration_finished.emit(shot_id)


var is_narrating: bool:
	get: return _is_narrating


# ── INTERNAL ────────────────────────────────────────────────────────────────────

func _run_narration(lines: Array[String], shot_id: String, speaker: String, token: int) -> void:
	for i in lines.size():
		if token != _narration_token:
			return  # Shot changed — discard stale narration

		var text: String = lines[i]
		if text.is_empty():
			# Empty string is an intentional pause line
			await get_tree().create_timer(LINE_GAP_SECONDS).timeout
			continue

		# Attempt to play voice audio (silently skips if key not registered)
		var voice_key := VOICE_KEY_PREFIX + shot_id + "_line_%02d" % (i + 1)
		var line_duration := _try_play_voice(voice_key)

		# Emit subtitle signal
		EventBus.narration_line_shown.emit(shot_id, speaker, text, line_duration)

		# Wait for the line duration
		await get_tree().create_timer(line_duration).timeout

		if token != _narration_token:
			return

		# Gap between lines
		if i < lines.size() - 1:
			await get_tree().create_timer(LINE_GAP_SECONDS).timeout

	if token == _narration_token:
		_is_narrating = false
		_duck_music(false)
		EventBus.narration_finished.emit(shot_id)


func _try_play_voice(key: String) -> float:
	## Returns estimated duration: voice player length if playing, else default.
	if StoryAudioManager.voice_streams.has(key):
		StoryAudioManager.play_voice(key)
		var stream: AudioStream = StoryAudioManager.voice_streams[key]
		if stream and stream.get_length() > 0.0:
			return stream.get_length()
	return DEFAULT_LINE_DURATION


func _duck_music(duck: bool) -> void:
	if duck == _music_ducked:
		return
	_music_ducked = duck
	if duck:
		StoryAudioManager.set_volume("Music", MUSIC_DUCK_DB, 0.4)
	else:
		StoryAudioManager.set_volume("Music", StoryAudioManager._MUSIC_DEFAULT_DB, 0.6)
