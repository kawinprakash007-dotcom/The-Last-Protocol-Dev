extends Node

func _ready() -> void:
	var gen = preload("res://story/scripts/tools/lighting_generator.gd").new()
	gen._run()
	print("Lighting presets regenerated successfully.")
	get_tree().quit()
