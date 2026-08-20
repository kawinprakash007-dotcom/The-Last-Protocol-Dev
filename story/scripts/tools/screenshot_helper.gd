extends Node

const OUT_DIR = "C:/Users/priya shakthi/.gemini/antigravity-ide/brain/7c41abfb-80ae-448a-9d90-b0a389a0eea3/"

# Target timestamps in seconds
const TARGET_TIMES = [
	5.0, 15.0, 25.0, 40.0, 55.0, 70.0, 85.0, 100.0, 110.0, 120.0, 130.0, 140.0, 148.0
]

var _captured = {}
var _elapsed = 0.0
var _pending_screenshots = 0

func _ready() -> void:
	# Speed up time so it completes quickly (5x speed)
	Engine.time_scale = 5.0
	print("--- Screenshot Helper Ready (5x speed scale) ---")

func _process(delta: float) -> void:
	_elapsed += delta
	
	for target in TARGET_TIMES:
		if _elapsed >= target and not _captured.has(target):
			_captured[target] = true
			_take_screenshot(target)
			
	# Quit once all timestamps are captured and no screen writes are pending
	if ((_captured.size() == TARGET_TIMES.size() or _elapsed > 152.0) 
		and _pending_screenshots == 0):
		print("--- All screenshots captured successfully! ---")
		Engine.time_scale = 1.0
		get_tree().quit()

func _take_screenshot(timestamp: float) -> void:
	_pending_screenshots += 1
	# Wait two frames to allow the renderer to flush
	await get_tree().process_frame
	await get_tree().process_frame
	
	var viewport = get_viewport()
	var image = viewport.get_texture().get_image()
	if image:
		var minutes = int(timestamp) / 60
		var seconds = int(timestamp) % 60
		var filename = "screenshot_%02d_%02d.png" % [minutes, seconds]
		var full_path = OUT_DIR + filename
		image.save_png(full_path)
		print("Saved screenshot for %02d:%02d to %s" % [minutes, seconds, filename])
	_pending_screenshots -= 1
