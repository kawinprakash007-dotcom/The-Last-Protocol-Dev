extends Node

## Centralized AudioManager Architecture
## Handles music, ambience, SFX, and UI audio with graceful fallback for missing assets.

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_size: int = 8
var _ui_pool: Array[AudioStreamPlayer] = []
var _ui_pool_size: int = 4

var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _current_sfx_volume_db: float = 0.0

# Sound dictionary mapping IDs to file paths
var _sound_registry = {
	# PLAYER
	"player_footstep": [
		"res://assets/audio/player/footstep_01.wav.wav",
		"res://assets/audio/player/footstep_02.wav.wav"
	],
	"player_reload": "res://assets/audio/player/player_reload.wav",
	"player_damage": "res://assets/audio/player/player_damage.wav",
	
	# ROBOT
	"robot_alert": "res://assets/audio/robot/robot_alert.wav",
	"robot_shot": "res://assets/audio/weapons/robot_shot.wav.mp3",
	"robot_hit": "res://assets/audio/robot/robot_hit.wav",
	"robot_shutdown": "res://assets/audio/robot/shutdown.wav.mp3",
	
	# WEAPONS
	"player_shot": "res://assets/audio/weapons/player_shot.wav.mp3",
	
	# UI
	"ui_select": "res://assets/audio/ui/ui_select.wav",
	"ui_confirm": "res://assets/audio/ui/ui_confirm.wav",
	"ui_error": "res://assets/audio/ui/ui_error.wav",
	"objective_update": "res://assets/audio/ui/objective_update.wav",
	
	# TERMINALS
	"terminal_open": "res://assets/audio/terminals/terminal_open.wav",
	"terminal_confirm": "res://assets/audio/terminals/terminal_confirm.wav.wav",
	"terminal_error": "res://assets/audio/terminals/terminal_error.wav",
	
	# ENVIRONMENT
	"wind": "res://assets/audio/environment/wind.ogg",
	"electrical_hum": "res://assets/audio/environment/electrical_hum.ogg",
	"metal_creak": "res://assets/audio/environment/metal_creak.wav",
	"spark": "res://assets/audio/environment/spark.wav",
	
	# MISSION
	"mission_update": "res://assets/audio/ui/mission_update.wav",
	"mission_failed": "res://assets/audio/ui/mission_failed.wav",
	"last_protocol_activation": "res://assets/audio/ui/last_protocol_activation.wav",
	
	# MUSIC
	"music_main": "res://assets/audio/music/Sector.mp3",
	"music_ruined_city": "res://assets/audio/music/Pulse.mp3",
	"music_shelter": "res://assets/audio/music/Airy.mp3",
	"music_final": "res://assets/audio/music/Urgent.mp3",
	"music_ending": "res://assets/audio/music/Victory.mp3",
	"music_title": "res://assets/audio/music/Title.mp3",
	"music_terminal": "res://assets/audio/music/Transmission.mp3",
	"ui_hover": "res://assets/audio/music/Hover.mp3",
}

# Cache for loaded streams
var _loaded_streams = {}

func _ready() -> void:
	_init_pools()
	
func _init_pools() -> void:
	_ensure_music_player()
	
	# Ambience
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	add_child(_ambience_player)
	
	# SFX Pool
	for i in range(_sfx_pool_size):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_" + str(i)
		add_child(p)
		_sfx_pool.append(p)
		
	# UI Pool
	for i in range(_ui_pool_size):
		var p = AudioStreamPlayer.new()
		p.name = "UIPlayer_" + str(i)
		add_child(p)
		_ui_pool.append(p)

func _get_stream(sound_name: String) -> AudioStream:
	if not _sound_registry.has(sound_name):
		print("[AudioManager] Warning: Sound ID not found in registry: ", sound_name)
		return null
		
	var entry = _sound_registry[sound_name]
	var path = ""
	
	if typeof(entry) == TYPE_ARRAY:
		path = entry[randi() % entry.size()]
	else:
		path = entry
		
	if _loaded_streams.has(path):
		return _loaded_streams[path]
		
	if ResourceLoader.exists(path):
		var stream = ResourceLoader.load(path)
		if stream is AudioStream:
			_loaded_streams[path] = stream
			return stream
	
	print("[AudioManager] Note: Audio file missing (placeholder): ", path)
	return null

func play_sfx(sound_name: String) -> void:
	_ensure_music_player()
	var stream = _get_stream(sound_name)
	if stream == null:
		return
		
	# FORCE DISABLE LOOPING - fixes footstep root cause
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	elif stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = false
		
	var target_volume = _current_sfx_volume_db
	if sound_name == "terminal_confirm":
		target_volume = _current_sfx_volume_db + 12.0
		
	# Find an available player
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = target_volume
			p.play()
			return
			
	# If all playing, override the oldest (or just the first)
	var p = _sfx_pool[0]
	p.stream = stream
	p.volume_db = target_volume
	p.play()

func play_ui(sound_name: String) -> void:
	var stream = _get_stream(sound_name)
	if stream == null:
		return
		
	# FORCE DISABLE LOOPING
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	elif stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = false
		
	for p in _ui_pool:
		if not p.playing:
			p.stream = stream
			p.play()
			return
			
	var p = _ui_pool[0]
	p.stream = stream
	p.play()

func _ensure_music_player() -> void:
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "MusicPlayer"
		if AudioServer.get_bus_index("Music") != -1:
			_music_player.bus = "Music"
		_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
		_music_player.volume_db = 6.0
		add_child(_music_player)

func play_music(sound_name: String) -> void:
	_ensure_music_player()
	var stream = _get_stream(sound_name)
	if stream == null:
		return
	if _music_player.stream == stream and _music_player.playing:
		return
		
	if _music_player.playing:
		var tw = create_tween()
		tw.tween_property(_music_player, "volume_db", -80.0, 1.0)
		tw.tween_callback(func():
			_music_player.stream = stream
			_music_player.volume_db = 6.0
			_music_player.play()
		)
	else:
		_music_player.stream = stream
		_music_player.volume_db = 6.0
		_music_player.play()

func fade_music(duration: float, target_volume_linear: float = 0.0) -> void:
	_ensure_music_player()
	if not _music_player.playing: return
	var target_db = -80.0
	if target_volume_linear > 0.001:
		target_db = linear_to_db(clamp(target_volume_linear, 0.001, 1.0))
		
	var tw = create_tween()
	tw.tween_property(_music_player, "volume_db", target_db, duration)
	if target_volume_linear <= 0.001:
		tw.tween_callback(func(): _music_player.stop())

func stop_music() -> void:
	_ensure_music_player()
	_music_player.stop()

# Volume controls (Linear 0.0 to 1.0)
func set_music_volume(volume: float) -> void:
	_ensure_music_player()
	_music_player.volume_db = linear_to_db(clamp(volume, 0.001, 1.0))

func set_sfx_volume(volume: float) -> void:
	_current_sfx_volume_db = linear_to_db(clamp(volume, 0.001, 1.0))
	for p in _sfx_pool:
		p.volume_db = _current_sfx_volume_db

func set_ambience_volume(volume: float) -> void:
	_ambience_player.volume_db = linear_to_db(clamp(volume, 0.001, 1.0))

# ── Testing Function ──
func test_audio_system() -> void:
	print("--- AUDIO MANAGER TEST ---")
	print("Attempting to play registered missing UI sound...")
	play_ui("ui_select")
	print("Attempting to play unregistered sound...")
	play_sfx("non_existent_sound")
	print("Attempting to play music...")
	play_music("music_track_1")
	print("Setting volumes...")
	set_music_volume(0.5)
	set_sfx_volume(0.8)
	print("Test complete. No crashes should have occurred.")

# ── Old Placeholder Hook Wrappers ──
func play_robot_alert(position: Vector3) -> void:
	play_sfx("robot_alert")

func play_robot_fire(position: Vector3) -> void:
	play_sfx("robot_shot")

func play_player_fire() -> void:
	play_sfx("player_shot")

func play_player_damage() -> void:
	play_sfx("player_damage")

func play_robot_damage(position: Vector3) -> void:
	play_sfx("robot_hit")

func play_robot_destroyed(position: Vector3) -> void:
	play_sfx("robot_shutdown")

func play_relay_explosion(position: Vector3) -> void:
	play_sfx("spark")

func play_relay_interact(position: Vector3) -> void:
	play_ui("ui_confirm")

func play_ambient_facility() -> void:
	var stream = _get_stream("electrical_hum")
	if stream:
		_ambience_player.stream = stream
		_ambience_player.play()
