extends Interactable

var is_activated: bool = false
var ui_canvas: CanvasLayer
var question_index: int = 0

var questions = [
	{
		"q": "SECURITY VERIFICATION 1/3: What is the primary directive of Autonomous Unit SN-4712?",
		"options": ["A) Protect civilian assets", "B) Enforce Quarantine Protocol Delta", "C) Maintain network uptime"],
		"correct": 1
	},
	{
		"q": "SECURITY VERIFICATION 2/3: Identify the system override code for Sector 04.",
		"options": ["A) OMEGA-7", "B) SIGMA-9", "C) PROTOCOL-X"],
		"correct": 0
	},
	{
		"q": "FINAL VERIFICATION 3/3: Confirm execution of THE LAST PROTOCOL.",
		"options": ["A) ABORT", "B) CONFIRM AND EXECUTE", "C) BYPASS"],
		"correct": 1
	}
]

func interact() -> void:
	if is_activated or ui_canvas != null:
		if is_activated:
			_log_player("TERMINAL ALREADY ACCESSED")
		return
		
	print("LAST PROTOCOL TERMINAL ACCESSED")
	GameState.access_last_protocol()
	
	_show_ui()

func _show_ui() -> void:
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player:
		player.is_control_disabled = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	ui_canvas = CanvasLayer.new()
	ui_canvas.layer = 20
	add_child(ui_canvas)
	
	# Hide all Label3D nodes to prevent mirrored 3D text bleeding through
	var labels = get_tree().current_scene.find_children("*", "Label3D", true, false)
	for l in labels:
		if l is Label3D:
			l.visible = false
	
	_build_question_ui()

func _build_question_ui() -> void:
	for child in ui_canvas.get_children():
		child.queue_free()
		
	var root = ColorRect.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.color = Color(0, 0, 0, 0.85)
	ui_canvas.add_child(root)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(750, 0)
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "SYSTEM OVERRIDE"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var q_label = Label.new()
	q_label.text = questions[question_index]["q"]
	q_label.add_theme_font_size_override("font_size", 22)
	q_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(q_label)
	
	var options = questions[question_index]["options"]
	for i in range(options.size()):
		var btn = Button.new()
		btn.text = options[i]
		btn.add_theme_font_size_override("font_size", 20)
		btn.custom_minimum_size = Vector2(0, 55)
		btn.pressed.connect(func(): _on_answer_selected(i))
		vbox.add_child(btn)
		
	var cancel_btn = Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.custom_minimum_size = Vector2(0, 55)
	cancel_btn.pressed.connect(func(): _close_ui(false))
	vbox.add_child(cancel_btn)

func _on_answer_selected(index: int) -> void:
	if index == questions[question_index]["correct"]:
		question_index += 1
		if question_index >= questions.size():
			_close_ui(true)
		else:
			_build_question_ui()
	else:
		_log_player("SECURITY CHECK FAILED. ACCESS DENIED.")
		_close_ui(false)

func _close_ui(success: bool) -> void:
	if ui_canvas:
		ui_canvas.queue_free()
		ui_canvas = null
		
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player:
		player.is_control_disabled = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Restore Label3Ds
	var labels = get_tree().current_scene.find_children("*", "Label3D", true, false)
	for l in labels:
		if l is Label3D:
			l.visible = true
	
	if success:
		is_activated = true
		GameState.pass_security_questions()
		GameState.activate_last_protocol()
	else:
		question_index = 0

func _log_player(msg: String) -> void:
	print(msg)
	if Mission01.has_method("shelter_console_log"):
		Mission01.shelter_console_log(msg)
