extends SceneTree

func _init():
	print("--- GODOT TEST START ---")
	var timer = create_timer(3.0)
	await timer.timeout
	print("--- GODOT TEST END ---")
	quit()
