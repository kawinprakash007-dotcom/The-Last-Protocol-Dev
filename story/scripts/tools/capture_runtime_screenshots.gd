extends SceneTree

func _init() -> void:
	print("====================================================")
	print("  Starting Runtime Cinematic Screenshot Capturer")
	print("====================================================")

	var scene_path = "res://story/cinematics/opening_cinematic.tscn"
	if not ResourceLoader.exists(scene_path):
		printerr("Error: Scene not found: ", scene_path)
		quit()
		return
		
	var scene = load(scene_path)
	var scene_inst = scene.instantiate()
	root.add_child(scene_inst)
	
	# Load and attach helper
	var helper_script = load("res://story/scripts/tools/screenshot_helper.gd")
	if helper_script:
		var helper = Node.new()
		helper.set_script(helper_script)
		root.add_child(helper)
	else:
		printerr("Error: Could not load screenshot helper script")
		quit()
