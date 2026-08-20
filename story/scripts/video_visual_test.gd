extends Node

@onready var video_player: VideoStreamPlayer = $CanvasLayer/VideoStreamPlayer
@onready var label: Label = $CanvasLayer/DebugLabel

func _ready() -> void:
	print("\n=== isolated video visual test start ===")
	
	# Load video
	var path = "res://story/assets/videos/ogv/TLP_SEQ01_HERO_ENTRY_FINAL.ogv"
	var stream = load(path)
	if stream == null:
		print("ERROR: Failed to load stream at ", path)
		get_tree().quit(1)
		return
		
	video_player.stream = stream
	video_player.play()
	
	# Wait for 1.5 seconds to allow playback to start and decode frames
	await get_tree().create_timer(1.5).timeout
	
	# Print all VideoStreamPlayer states
	print("VideoStreamPlayer path: ", video_player.get_path())
	print("visible: ", video_player.visible)
	print("modulate: ", video_player.modulate)
	print("self_modulate: ", video_player.self_modulate)
	print("position: ", video_player.position)
	print("size: ", video_player.size)
	print("scale: ", video_player.scale)
	print("anchors: left=", video_player.anchor_left, " top=", video_player.anchor_top, " right=", video_player.anchor_right, " bottom=", video_player.anchor_bottom)
	print("offsets: left=", video_player.offset_left, " top=", video_player.offset_top, " right=", video_player.offset_right, " bottom=", video_player.offset_bottom)
	print("z_index: ", video_player.z_index)
	print("mouse_filter: ", video_player.mouse_filter)
	print("show_behind_parent: ", video_player.show_behind_parent)
	print("clip_contents: ", video_player.clip_contents)
	print("expand: ", video_player.expand)
	print("autoplay: ", video_player.autoplay)
	print("paused: ", video_player.paused)
	print("loop: ", video_player.loop)
	print("stream: ", video_player.stream)
	if video_player.stream:
		print("stream resource type: ", video_player.stream.get_class())
		print("stream file path: ", video_player.stream.resource_path)
	print("is_playing(): ", video_player.is_playing())
	print("stream_position: ", video_player.stream_position)
	
	var texture = video_player.get_video_texture()
	print("get_video_texture(): ", texture)
	if texture != null:
		print("FRAME_TEXTURE_EXISTS = true")
		print("FRAME_WIDTH = ", texture.get_width())
		print("FRAME_HEIGHT = ", texture.get_height())
		label.text = "VIDEO TEST\nSTREAM OK\nPLAYING: " + str(video_player.is_playing()) + "\nTEXTURE: true\nSIZE: " + str(texture.get_size()) + "\nPOSITION: " + str(video_player.global_position)
	else:
		print("FRAME_TEXTURE_EXISTS = false")
		print("FRAME_WIDTH = 0")
		print("FRAME_HEIGHT = 0")
		label.text = "VIDEO TEST\nSTREAM OK\nPLAYING: " + str(video_player.is_playing()) + "\nTEXTURE: false\nSIZE: N/A\nPOSITION: " + str(video_player.global_position)
		
	# Capture screenshot
	await get_tree().process_frame
	await get_tree().process_frame
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("c:/GoDotProjects/the-last-protocall/screenshot_video.png")
		print("DIAGNOSTIC: Screenshot saved successfully to c:/GoDotProjects/the-last-protocall/screenshot_video.png")
	else:
		print("ERROR: Failed to capture viewport image")
		
	print("=== isolated video visual test end ===\n")
	get_tree().quit(0)
