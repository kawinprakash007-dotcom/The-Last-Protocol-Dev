extends Node
class_name AudioSpawner

## Spawns an AudioStreamPlayer3D at a specific global position, plays it, and frees it.
static func play_3d_sound(stream: AudioStream, global_pos: Vector3, parent: Node, bus: String = "SFX", max_dist: float = 30.0) -> AudioStreamPlayer3D:
	if not stream or not parent: return null
	
	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = bus
	player.max_distance = max_dist
	player.position = global_pos
	
	# Connect to finished signal to auto-free
	player.finished.connect(player.queue_free)
	
	parent.add_child(player)
	player.play()
	return player

## Spawns a 2D/Global AudioStreamPlayer, plays it, and frees it.
static func play_2d_sound(stream: AudioStream, parent: Node, bus: String = "SFX", volume_db: float = 0.0) -> AudioStreamPlayer:
	if not stream or not parent: return null
	
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	player.volume_db = volume_db
	
	player.finished.connect(player.queue_free)
	
	parent.add_child(player)
	player.play()
	return player
