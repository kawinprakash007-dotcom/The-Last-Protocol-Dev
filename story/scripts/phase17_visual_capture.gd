extends Node

## Phase 17 Visual Capture Runner
## Runs through the real screens and interactions and captures screenshots to disk.

var _brain_path := "C:/Users/priya shakthi/.gemini/antigravity-ide/brain/780d0f84-3d2c-4eaa-b574-8e19432d6a5d/"

func _ready() -> void:
	# Set window size
	get_window().size = Vector2i(1280, 720)
	await get_tree().process_frame
	await get_tree().process_frame
	_run_captures()


func _run_captures() -> void:
	print("--- PHASE 17 VISUAL CAPTURE STARTING ---")

	# 1. Capture Title / Boot Screen
	print("[1/10] Capturing Title / Boot Screen...")
	var intro_scene: PackedScene = load("res://story/ui/story_intro.tscn")
	var intro_node = intro_scene.instantiate()
	add_child(intro_node)
	await get_tree().create_timer(3.0).timeout
	await _capture("phase17_01_boot_title.png")

	# 2. Capture Signal Transmission Screen
	print("[2/10] Capturing Signal Transmission Screen...")
	intro_node.call("_on_boot_confirmed")
	await get_tree().create_timer(5.0).timeout
	await _capture("phase17_02_signal_screen.png")

	# 3. Capture Mission Initialization Screen
	print("[3/10] Capturing Mission Initialization Screen...")
	intro_node.call("_on_signal_accepted")
	await get_tree().create_timer(1.5).timeout
	await _capture("phase17_03_mission_init.png")

	intro_node.queue_free()
	await get_tree().process_frame

	# 4. Capture First Cinematic Video (Hero Entry)
	print("[4/10] Capturing First Cinematic Video (Hero Entry)...")
	var cinematic_scene: PackedScene = load("res://story/cinematics/opening_cinematic.tscn")
	var cinematic_node = cinematic_scene.instantiate()
	add_child(cinematic_node)
	await get_tree().create_timer(2.0).timeout
	await _capture("phase17_04_cinematic_hero_entry.png")

	# 5. Capture Interaction A (Prototype Choice)
	print("[5/10] Capturing Interaction A (Prototype Choice)...")
	var seq = FinalOpeningBuilder.build()
	CinematicManager.stop()
	await get_tree().process_frame
	var seq_a = CinematicSequence.new()
	seq_a.sequence_id = "cap_a"
	var shots_a: Array[CinematicShot] = [seq.shots[3]] # interact_a_prototype
	seq_a.shots = shots_a
	CinematicManager.play_sequence(seq_a)
	await get_tree().create_timer(1.0).timeout
	await _capture("phase17_05_interaction_a_prototype.png")

	# 6. Capture Interaction B (Authorization Screen)
	print("[6/10] Capturing Interaction B (Authorization Screen)...")
	CinematicManager.stop()
	await get_tree().process_frame
	var seq_b = CinematicSequence.new()
	seq_b.sequence_id = "cap_b"
	var shots_b: Array[CinematicShot] = [seq.shots[7]] # act3_interactive_auth
	seq_b.shots = shots_b
	CinematicManager.play_sequence(seq_b)
	await get_tree().create_timer(1.0).timeout
	await _capture("phase17_06_interaction_b_auth.png")

	# 7. Capture Interaction C (Anomaly Response)
	print("[7/10] Capturing Interaction C (Anomaly Response)...")
	CinematicManager.stop()
	await get_tree().process_frame
	var seq_c = CinematicSequence.new()
	seq_c.sequence_id = "cap_c"
	var shots_c: Array[CinematicShot] = [seq.shots[9]] # interact_c_anomaly
	seq_c.shots = shots_c
	CinematicManager.play_sequence(seq_c)
	await get_tree().create_timer(1.0).timeout
	await _capture("phase17_07_interaction_c_anomaly.png")

	# 8. Capture Interaction D (Source Identification)
	print("[8/10] Capturing Interaction D (Source Identification)...")
	CinematicManager.stop()
	await get_tree().process_frame
	var seq_d = CinematicSequence.new()
	seq_d.sequence_id = "cap_d"
	var shots_d: Array[CinematicShot] = [seq.shots[14]] # interact_d_source
	seq_d.shots = shots_d
	CinematicManager.play_sequence(seq_d)
	await get_tree().create_timer(1.0).timeout
	await _capture("phase17_08_interaction_d_source.png")

	# 9. Capture Creator vs Creations Video
	print("[9/10] Capturing Creator vs Creations Video...")
	CinematicManager.stop()
	await get_tree().process_frame
	var seq_v = CinematicSequence.new()
	seq_v.sequence_id = "cap_v"
	var shots_v: Array[CinematicShot] = [seq.shots[15]] # act7_vs_creations
	seq_v.shots = shots_v
	CinematicManager.play_sequence(seq_v)
	await get_tree().create_timer(1.5).timeout
	await _capture("phase17_09_creator_vs_creations.png")

	# 10. Capture Interaction E (Last Protocol)
	print("[10/10] Capturing Interaction E (Last Protocol)...")
	CinematicManager.stop()
	await get_tree().process_frame
	var seq_e = CinematicSequence.new()
	seq_e.sequence_id = "cap_e"
	var shots_e: Array[CinematicShot] = [seq.shots[16]] # act8_last_protocol
	seq_e.shots = shots_e
	CinematicManager.play_sequence(seq_e)
	await get_tree().create_timer(1.0).timeout
	await _capture("phase17_10_interaction_e_last_protocol.png")

	cinematic_node.queue_free()
	CinematicManager.stop()
	await get_tree().process_frame

	# 11. Capture Gameplay Handoff (Main Scene)
	print("[Bonus] Capturing Gameplay Corridor (Main Scene)...")
	var main_scene: PackedScene = load("res://main.tscn")
	var main_node = main_scene.instantiate()
	add_child(main_node)
	await get_tree().create_timer(1.0).timeout
	await _capture("phase17_11_gameplay_handoff.png")
	main_node.queue_free()

	print("--- ALL PHASE 17 VISUAL CAPTURES COMPLETED ---")
	get_tree().quit(0)


func _capture(filename: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png(filename)
		img.save_png(_brain_path + filename)
		print("  Saved: ", filename)
