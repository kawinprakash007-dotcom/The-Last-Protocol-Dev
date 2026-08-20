## GameplayScreenshotAutoload
## Injected as a temporary autoload to capture main.tscn gameplay.
## Waits 2 seconds then saves a screenshot and quits.
extends Node

var _timer: float = 0.0
var _shot1_done: bool = false
var _choice_triggered: bool = false
var _shot2_done: bool = false


func _process(delta: float) -> void:
	_timer += delta

	# Screenshot 1: gameplay environment (2s after start)
	if not _shot1_done and _timer >= 2.0:
		_shot1_done = true
		_save("c:/GoDotProjects/the-last-protocall/screenshot_gameplay_start.png")
		_trigger_choice_panel()

	# Screenshot 2: choice panel visible (3s after start)
	if _shot1_done and not _shot2_done and _timer >= 3.2:
		_shot2_done = true
		_save("c:/GoDotProjects/the-last-protocall/screenshot_gameplay_choice.png")

	# Quit (4s after start)
	if _shot2_done and _timer >= 4.0:
		get_tree().quit(0)


func _trigger_choice_panel() -> void:
	var choice_ui = get_tree().get_root().find_child("InteractiveChoiceUI", true, false)
	if choice_ui == null:
		print("[CAPTURE] InteractiveChoiceUI not found")
		return
	if not choice_ui.has_method("show_choice"):
		print("[CAPTURE] show_choice not available")
		return
	choice_ui.show_choice({
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
	print("[CAPTURE] show_choice() triggered on InteractiveChoiceUI")


func _save(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png(path)
		print("[CAPTURE] Saved: ", path)
	else:
		print("[CAPTURE] FAIL: no viewport image at ", path)
