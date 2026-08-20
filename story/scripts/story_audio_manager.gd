## StoryAudioManager — Safe, centralized audio API for all story/cinematic audio.
##
## AUTOLOAD: Registered as "StoryAudioManager" in project.godot.
##
## All audio calls are null-safe. Missing streams are silently skipped.
## Audio assets are assigned via the @export dictionaries below, or populated
## at runtime by the project's audio designer.
##
## Team Ownership: Story Team
## Audio Bus Layout expected: Master → Music, Ambience, SFX, Voice, UI
##
extends Node


# ── STREAM REGISTRIES ──────────────────────────────────────────────────────────
## AUDIO DESIGNER: Populate these dictionaries with AudioStream resources.
## Key = string identifier used by CinematicShot and StoryAudioManager calls.
## Example: music_streams["DRONE_C"] = preload("res://story/audio/music/drone_c.ogg")

var music_streams: Dictionary = {}
var ambience_streams: Dictionary = {}
var sfx_streams: Dictionary = {}
var voice_streams: Dictionary = {}


# ── INTERNAL PLAYERS ───────────────────────────────────────────────────────────
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _voice_player: AudioStreamPlayer

## Default conservative volumes (dB). Adjust per bus in the Audio panel.
var _MUSIC_DEFAULT_DB: float = -12.0
const _AMBIENCE_DEFAULT_DB: float = -15.0
const _SFX_DEFAULT_DB: float = -8.0
const _VOICE_DEFAULT_DB: float = -6.0


func _ready() -> void:
	_music_player = _make_player("MusicPlayer", _MUSIC_DEFAULT_DB)
	_ambience_player = _make_player("AmbiencePlayer", _AMBIENCE_DEFAULT_DB)
	_sfx_player = _make_player("SFXPlayer", _SFX_DEFAULT_DB)
	_voice_player = _make_player("VoicePlayer", _VOICE_DEFAULT_DB)

	# Listen to EventBus audio requests
	EventBus.music_change_requested.connect(_on_music_change_requested)
	EventBus.ambience_change_requested.connect(_on_ambience_change_requested)


func _make_player(player_name: String, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.volume_db = volume
	add_child(player)
	return player


# ── PUBLIC API ─────────────────────────────────────────────────────────────────

## Play a music track by key. Fades in over fade_in seconds.
## Safe to call with an unregistered key — emits a warning, does not crash.
func play_music(key: String, fade_in: float = 1.0) -> void:
	var stream: AudioStream = _get_stream(music_streams, key, "music")
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = -80.0
	_music_player.play()
	_fade_player(_music_player, _MUSIC_DEFAULT_DB, fade_in)


## Stop the current music. Fades out over fade_out seconds.
func stop_music(fade_out: float = 1.0) -> void:
	_fade_player(_music_player, -80.0, fade_out, true)


## Crossfade from the current music to a new track over duration seconds.
func crossfade_music(key: String, duration: float = 2.0) -> void:
	var stream: AudioStream = _get_stream(music_streams, key, "music")
	if stream == null:
		return
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -80.0, duration * 0.5)
	tween.tween_callback(func():
		_music_player.stream = stream
		_music_player.play()
	)
	tween.tween_property(_music_player, "volume_db", _MUSIC_DEFAULT_DB, duration * 0.5)


## Play an ambience loop by key.
func play_ambience(key: String) -> void:
	var stream: AudioStream = _get_stream(ambience_streams, key, "ambience")
	if stream == null:
		return
	_ambience_player.stream = stream
	_ambience_player.play()


## Stop the ambience loop.
func stop_ambience(fade_out: float = 1.0) -> void:
	_fade_player(_ambience_player, -80.0, fade_out, true)


## Play a one-shot sound effect by key.
func play_sfx(key: String) -> void:
	var stream: AudioStream = _get_stream(sfx_streams, key, "sfx")
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.play()


## Play a voice line by key.
func play_voice(key: String) -> void:
	var stream: AudioStream = _get_stream(voice_streams, key, "voice")
	if stream == null:
		return
	_voice_player.stream = stream
	_voice_player.play()


## Set the volume (in dB) on a named bus with an optional fade.
## bus_name examples: "Music", "SFX", "Voice", "Ambience"
func set_volume(bus_name: String, target_db: float, fade: float = 0.5) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		push_warning("StoryAudioManager: Bus '%s' not found in Audio panel." % bus_name)
		return
	if fade <= 0.0:
		AudioServer.set_bus_volume_db(bus_index, target_db)
	else:
		var tween := create_tween()
		var current_db := AudioServer.get_bus_volume_db(bus_index)
		tween.tween_method(
			func(v: float): AudioServer.set_bus_volume_db(bus_index, v),
			current_db, target_db, fade
		)


# ── INTERNAL ───────────────────────────────────────────────────────────────────

func _get_stream(registry: Dictionary, key: String, registry_name: String) -> AudioStream:
	if key.is_empty():
		return null
	if not registry.has(key):
		push_warning(
			"StoryAudioManager: Key '%s' not found in %s_streams. "
			% [key, registry_name] +
			"Assign the stream in StoryAudioManager or an StoryAudioManager-extending script."
		)
		return null
	return registry[key]


func _fade_player(player: AudioStreamPlayer, target_db: float,
		duration: float, stop_after: bool = false) -> void:
	if duration <= 0.0:
		player.volume_db = target_db
		if stop_after:
			player.stop()
		return
	var tween := create_tween()
	tween.tween_property(player, "volume_db", target_db, duration)
	if stop_after:
		tween.tween_callback(player.stop)


func _on_music_change_requested(key: String) -> void:
	play_music(key)


func _on_ambience_change_requested(key: String) -> void:
	play_ambience(key)
