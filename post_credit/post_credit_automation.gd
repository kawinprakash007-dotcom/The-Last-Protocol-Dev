## PostCreditAutomation — Automated test player for final premium post-credit sequence.
##
## Instantiated automatically when environment variable AUTOMATE_TEST is set to true.
## Simulates user inputs and records screenshots to the brain directory.
##
extends Node

const OUT_DIR := "C:/Users/priya shakthi/.gemini/antigravity-ide/brain/be754168-bd17-479c-ae55-c1ae4f4f756d/"


func _ready() -> void:
	print("--- PostCredit Automation Helper Started ---")
	
	# Create target output directory if it doesn't exist
	var dir := DirAccess.open("C:/Users/priya shakthi/.gemini/antigravity-ide/brain/")
	if dir:
		dir.make_dir_recursive("be754168-bd17-479c-ae55-c1ae4f4f756d")
		
	var post_credit := get_node("/root/PostCredit")
	if post_credit == null:
		printerr("Automation Error: PostCredit root node not found")
		get_tree().quit()
		return

	# ── 1. Intro ──
	while post_credit._phase != post_credit.Phase.INTRO:
		await get_tree().process_frame
	await get_tree().create_timer(1.5).timeout
	await _take_screenshot("01_intro")

	# ── 2. PC01 Video ──
	while post_credit._phase != post_credit.Phase.PC01:
		await get_tree().process_frame
	await get_tree().create_timer(2.0).timeout
	await _take_screenshot("02_pc01_visible")

	# ── 3. Interactive choice ──
	while post_credit._phase != post_credit.Phase.INTERACTIVE:
		await get_tree().process_frame
		
	# Wait for choice UI to animate in (takes a bit because of narration text fade cycles)
	# Narration 1 takes about 9-10 seconds total. Let's wait in frame loop until ButtonRow is visible.
	var ui_layer = get_node("/root/PostCredit/UILayer")
	var btn_row: HBoxContainer = null
	while btn_row == null or not btn_row.visible or btn_row.modulate.a < 0.2:
		await get_tree().process_frame
		btn_row = ui_layer.find_child("ButtonRow", true, false)
		
	await get_tree().create_timer(0.5).timeout
	await _take_screenshot("03_interactive_moment")

	# Click CONTROL THEM AGAIN (Choice A) first to verify loop back
	if btn_row and btn_row.get_child_count() > 1:
		var btn_a = btn_row.get_child(0) as Button
		if btn_a:
			print("Clicking CONTROL THEM AGAIN button: ", btn_a.text)
			btn_a.pressed.emit()

	# Wait for loop warning and return to choices
	await get_tree().create_timer(3.5).timeout
	
	# Wait for buttons to show again
	btn_row = ui_layer.find_child("ButtonRow", true, false)
	while btn_row == null or not btn_row.visible or btn_row.modulate.a < 0.2:
		await get_tree().process_frame
		btn_row = ui_layer.find_child("ButtonRow", true, false)

	# Click BUILD WITH THEM (Choice B) to proceed
	if btn_row and btn_row.get_child_count() > 1:
		var btn_b = btn_row.get_child(1) as Button
		if btn_b:
			print("Clicking BUILD WITH THEM button: ", btn_b.text)
			btn_b.pressed.emit()

	# ── 4. PC02 Video ──
	while post_credit._phase != post_credit.Phase.PC02:
		await get_tree().process_frame
	await get_tree().create_timer(2.0).timeout
	await _take_screenshot("04_pc02_visible")

	# ── 5. Rebuild Task ──
	while post_credit._phase != post_credit.Phase.REBUILD:
		await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	
	# Rebuild Task 1: Power Grid nodes connection
	var power_labels := ["POWER CORE", "NODE A", "NODE B", "CITY GRID"]
	for label in power_labels:
		var btn = _find_button_by_text(ui_layer, [label])
		if btn:
			print("Clicking power node: ", label)
			btn.pressed.emit()
		await get_tree().create_timer(0.4).timeout

	# Wait for transition to Task 2
	await get_tree().create_timer(4.5).timeout
	await _take_screenshot("05_rebuild_task")

	# Rebuild Task 2: Structural Frame logical placement
	var struct_labels := ["FOUNDATION", "SUPPORT", "ENERGY CORE"]
	for label in struct_labels:
		var btn = _find_button_by_text(ui_layer, [label])
		if btn:
			print("Clicking structural component: ", label)
			btn.pressed.emit()
		await get_tree().create_timer(0.4).timeout

	# Wait for transition to Act 3: Robot moment dialogue (detect continue button)
	var btn_continue = _find_button_by_text(ui_layer, ["[ CONTINUE ]"])
	while btn_continue == null or not btn_continue.visible or btn_continue.disabled:
		await get_tree().process_frame
		btn_continue = _find_button_by_text(ui_layer, ["[ CONTINUE ]"])

	# Click [ CONTINUE ] 5 times for Funny Robot Moment dialogue
	for i in range(5):
		var btn = _find_button_by_text(ui_layer, ["[ CONTINUE ]"])
		if btn:
			print("Clicking funny moment continue: step ", i+1)
			btn.pressed.emit()
		await get_tree().create_timer(0.6).timeout

	# Wait for transition to Task 3: City Priority Restoration
	await get_tree().create_timer(1.2).timeout

	# Click WATER restoration priority button
	var priority_btn = _find_button_by_text(ui_layer, ["WATER"])
	if priority_btn:
		print("Clicking city restoration priority: WATER")
		priority_btn.pressed.emit()

	# ── 6. Ending Narration ──
	while post_credit._phase != post_credit.Phase.ENDING:
		await get_tree().process_frame
		
	# Wait for ending dashboard (SECTOR 07 RECOVERY METRICS) to reveal
	await get_tree().create_timer(8.0).timeout
	await _take_screenshot("06_ending")

	# Wait for final [ THE END ] button to appear
	var end_btn: Button = null
	while end_btn == null or not end_btn.visible or end_btn.modulate.a < 0.2:
		await get_tree().process_frame
		end_btn = _find_button_by_text(ui_layer, ["[ THE END ]"])
		
	await get_tree().create_timer(0.5).timeout
	await _take_screenshot("06_ending_button_visible")
	
	print("Clicking final end button: ", end_btn.text)
	end_btn.pressed.emit()

	# ── 7. Complete Black ──
	while post_credit._phase != post_credit.Phase.DONE:
		await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	await _take_screenshot("07_complete_black")
	
	print("--- PostCredit Automation Helper Completed! ---")
	get_tree().quit()


func _take_screenshot(label: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	var viewport := get_viewport()
	var image := viewport.get_texture().get_image()
	if image:
		var filename := "post_credit_%s.png" % label
		var full_path := OUT_DIR + filename
		image.save_png(full_path)
		print("Saved screenshot to %s" % full_path)


func _find_button_by_text(root_node: Node, target_texts: Array) -> Button:
	var stack := [root_node]
	while stack.size() > 0:
		var current = stack.pop_back()
		if current is Button:
			for text in target_texts:
				if current.text == text:
					return current
		for child in current.get_children():
			stack.push_back(child)
	return null
