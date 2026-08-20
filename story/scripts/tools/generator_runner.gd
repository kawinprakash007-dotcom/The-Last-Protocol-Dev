extends SceneTree

func _init() -> void:
	print("====================================================")
	print("  Procedural Asset Generation Runner Started")
	print("====================================================")

	# 1. Run Lighting Generator
	var lighting_script = load("res://story/scripts/tools/lighting_generator.gd")
	if lighting_script:
		print("Running Lighting Generator...")
		var inst = lighting_script.new()
		if inst.has_method("_run"):
			inst._run()
		else:
			print("Error: lighting_generator has no _run method")
	else:
		print("Error: Could not load lighting_generator")

	# 2. Run VFX Generator
	var vfx_script = load("res://story/scripts/tools/vfx_generator.gd")
	if vfx_script:
		print("Running VFX Generator...")
		var inst = vfx_script.new()
		if inst.has_method("_run"):
			inst._run()
		else:
			print("Error: vfx_generator has no _run method")
	else:
		print("Error: Could not load vfx_generator")

	# 3. Run Laboratory Generator
	var lab_script = load("res://story/scripts/tools/laboratory_generator.gd")
	if lab_script:
		print("Running Laboratory Generator...")
		var inst = lab_script.new()
		if inst.has_method("_run"):
			inst._run()
		else:
			print("Error: laboratory_generator has no _run method")
	else:
		print("Error: Could not load laboratory_generator")

	# 4. Run City Generator
	var city_script = load("res://story/scripts/tools/city_generator.gd")
	if city_script:
		print("Running City Generator...")
		var inst = city_script.new()
		if inst.has_method("_run"):
			inst._run()
		else:
			print("Error: city_generator has no _run method")
	else:
		print("Error: Could not load city_generator")

	print("====================================================")
	print("  Procedural Asset Generation Complete!")
	print("====================================================")
	quit()
