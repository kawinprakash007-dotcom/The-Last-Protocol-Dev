extends Node
class_name CinematicAudioMaster

## Cinematic Audio Master handles the 150-second timeline sequence
## and triggers appropriate music tracks and SFX transitions.

enum MusicPhase {
	WONDER = 0,
	DISCOVERY = 1,
	GROWTH = 2,
	CONFIDENCE = 3,
	UNEASE = 4,
	CATASTROPHE = 5,
	SILENCE = 6,
	DETERMINATION = 7
}

var current_time: float = 0.0
var is_playing: bool = false
var current_phase: MusicPhase = MusicPhase.WONDER

@onready var music_player_1: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var music_player_2: AudioStreamPlayer = AudioStreamPlayer.new()
var active_player: AudioStreamPlayer

func _ready():
	add_child(music_player_1)
	add_child(music_player_2)
	music_player_1.bus = "Music"
	music_player_2.bus = "Music"
	active_player = music_player_1

func play():
	current_time = 0.0
	is_playing = true
	current_phase = MusicPhase.WONDER
	_trigger_phase(current_phase)
	print("[AudioMaster] Started playback at 0s: WONDER / INVENTION")

func stop():
	is_playing = false
	music_player_1.stop()
	music_player_2.stop()

func _process(delta: float):
	if not is_playing: return
	
	current_time += delta
	_check_timeline(current_time)

func _check_timeline(t: float):
	if t >= 20.0 and current_phase == MusicPhase.WONDER:
		current_phase = MusicPhase.DISCOVERY
		_trigger_phase(current_phase)
		print("[AudioMaster] %0.1fs -> DISCOVERY" % t)
	elif t >= 45.0 and current_phase == MusicPhase.DISCOVERY:
		current_phase = MusicPhase.GROWTH
		_trigger_phase(current_phase)
		print("[AudioMaster] %0.1fs -> GROWTH / ACHIEVEMENT" % t)
	elif t >= 70.0 and current_phase == MusicPhase.GROWTH:
		current_phase = MusicPhase.CONFIDENCE
		_trigger_phase(current_phase)
		print("[AudioMaster] %0.1fs -> CONFIDENCE" % t)
	elif t >= 85.0 and current_phase == MusicPhase.CONFIDENCE:
		current_phase = MusicPhase.UNEASE
		_trigger_phase(current_phase)
		print("[AudioMaster] %0.1fs -> UNEASE" % t)
	elif t >= 100.0 and current_phase == MusicPhase.UNEASE:
		current_phase = MusicPhase.CATASTROPHE
		_trigger_phase(current_phase)
		print("[AudioMaster] %0.1fs -> CATASTROPHE" % t)
	elif t >= 120.0 and current_phase == MusicPhase.CATASTROPHE:
		current_phase = MusicPhase.SILENCE
		_trigger_phase(current_phase)
		print("[AudioMaster] %0.1fs -> SILENCE / REALIZATION" % t)
	elif t >= 135.0 and current_phase == MusicPhase.SILENCE:
		current_phase = MusicPhase.DETERMINATION
		_trigger_phase(current_phase)
		print("[AudioMaster] %0.1fs -> DETERMINATION" % t)
	elif t >= 150.0 and current_phase == MusicPhase.DETERMINATION:
		stop()
		print("[AudioMaster] %0.1fs -> SEQUENCE COMPLETE" % t)

func _trigger_phase(phase: MusicPhase):
	# Synthesize a fallback tone using Godot's AudioStreamGenerator if assets are missing
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100
	stream.buffer_length = 0.1
	
	var next_player = music_player_1 if active_player == music_player_2 else music_player_2
	next_player.stream = stream
	
	if phase == MusicPhase.SILENCE:
		next_player.stream = null # Explicit silence
		
	# Crossfade logic
	var fade_tween = create_tween()
	fade_tween.tween_property(active_player, "volume_db", -60.0, 2.0)
	
	if next_player.stream:
		next_player.volume_db = -60.0
		next_player.play()
		fade_tween.parallel().tween_property(next_player, "volume_db", 0.0, 2.0)
		
	active_player = next_player
