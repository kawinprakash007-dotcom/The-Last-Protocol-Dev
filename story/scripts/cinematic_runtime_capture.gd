## Diagnostic script: runs opening_cinematic sequence and captures a screenshot
## after the first video shot has had time to render.
extends Node

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Wait 2s for the first video to begin rendering frames
	await get_tree().create_timer(2.0).timeout
	
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png("c:/GoDotProjects/the-last-protocall/screenshot_cinematic_runtime.png")
		print("[CAPTURE] Screenshot saved: c:/GoDotProjects/the-last-protocall/screenshot_cinematic_runtime.png")
	else:
		print("[CAPTURE] ERROR: Failed to get viewport image")
	
	# Print video player state
	var players := get_tree().get_nodes_in_group("cinematic_video_player")
	if players.size() > 0:
		var vp := players[0] as VideoStreamPlayer
		print("[VIDEO] visible=", vp.visible, " modulate=", vp.modulate, " playing=", vp.is_playing(), " pos=", vp.stream_position)
		var tx := vp.get_video_texture()
		print("[VIDEO] texture_exists=", tx != null, " size=", vp.size)
		if tx:
			print("[VIDEO] FRAME_WIDTH=", tx.get_width(), " FRAME_HEIGHT=", tx.get_height())
		# Check parent CanvasLayer
		var parent := vp.get_parent()
		if parent is CanvasLayer:
			print("[VIDEO] CanvasLayer.layer=", parent.layer, " visible=", parent.visible)
	else:
		print("[VIDEO] No node found in group cinematic_video_player!")
	
	# Print CinematicFade state
	var fades := get_tree().get_nodes_in_group("cinematic_fade")
	if fades.size() > 0:
		var cf := fades[0]
		print("[FADE] layer=", cf.layer if cf is CanvasLayer else "N/A", " visible=", cf.visible)
		var rect := cf.get_node_or_null("FadeRect")
		if rect:
			print("[FADE] FadeRect.visible=", rect.visible, " modulate.a=", rect.modulate.a, " color=", rect.color)
	
	get_tree().quit(0)
