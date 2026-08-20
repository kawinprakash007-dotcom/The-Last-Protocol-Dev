## Captures the gameplay scene at startup and after forcing the choice UI open.
## Must be attached to a Node that is added to main.tscn via autoload injection
## OR launched as the main scene directly (which is what we do here).
##
## This scene IS the entry scene passed to --path via Godot CLI.
## It immediately loads main.tscn and hooks into it.
##
extends Node

var _frame_count: int = 0
var _phase: int = 0
var _choice_ui: Node = null


func _ready() -> void:
	# Use call_deferred so the scene tree is fully ready
	call_deferred("_start")


func _start() -> void:
	# Switch to gameplay scene
	get_tree().change_scene_to_file("res://main.tscn")


func _process(_delta: float) -> void:
	_frame_count += 1

	match _phase:
		0:
			# Wait 90 frames (~1.5s at 60fps) for wake-up subtitle
			if _frame_count >= 90:
				_phase = 1
				_save("c:/GoDotProjects/the-last-protocall/screenshot_gameplay_start.png")
				_find_and_open_choice_ui()

		1:
			# Wait 40 more frames for choice UI to build and fade in
			if _frame_count >= 130:
				_phase = 2
				_save("c:/GoDotProjects/the-last-protocall/screenshot_gameplay_choice.png")

		2:
			# Done
			if _frame_count >= 135:
				get_tree().quit(0)


func _find_and_open_choice_ui() -> void:
	var root := get_tree().get_root()
	# After scene change, the new scene is a child of root
	_choice_ui = root.find_child("InteractiveChoiceUI", true, false)
	if _choice_ui == null:
		print("[CAPTURE] InteractiveChoiceUI not found in tree")
		return
	if not _choice_ui.has_method("show_choice"):
		print("[CAPTURE] InteractiveChoiceUI missing show_choice method")
		return
	_choice_ui.show_choice({
		"terminal_id": "capture_test",
		"title": "EMERGENCY SYSTEM ACCESS REQUEST",
		"node_id": "NETWORK NODE: SECTOR 07",
		"authority": "VERIFIED",
		"condition": "UNSTABLE",
		"prompt": "A damaged service robot is requesting temporary access to the sector grid.",
		"state_key": "capture_permission",
		"options": [
			{"label": "GRANT LIMITED ACCESS", "value": "granted"},
			{"label": "DENY ACCESS",          "value": "denied"},
		],
		"results": {
			"granted": {"main": "LIMITED ACCESS GRANTED", "sub": "Door unlocked.", "color": "success"},
			"denied":  {"main": "ACCESS DENIED",          "sub": "Alternate route.",  "color": "warn"},
		},
	})
	print("[CAPTURE] show_choice() called on InteractiveChoiceUI")


func _save(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png(path)
		print("[CAPTURE] Saved: ", path)
	else:
		print("[CAPTURE] FAIL: No viewport image")
