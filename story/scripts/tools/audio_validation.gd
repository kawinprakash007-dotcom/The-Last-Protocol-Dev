extends SceneTree

var master: Node
var time_elapsed: float = 0.0

func _init():
	print("--- Starting Runtime Audio Validation ---")
	master = load("res://story/scripts/cinematic_audio_master.gd").new()
	root.add_child(master)
	master.play()
	
	while time_elapsed <= 155.0:
		master._process(1.0)
		time_elapsed += 1.0
		
	print("--- Runtime Audio Validation Complete ---")
	quit()
