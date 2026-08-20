## CinematicLetterbox — Animated widescreen bars for cinematic sequences.
##
## Bars animate in when the cinematic begins and out when gameplay resumes.
## Listens to EventBus.letterbox_toggled.
## Can also be called directly: show_letterbox() / hide_letterbox().
##
## Team Ownership: Story Team
##
extends CanvasLayer


@onready var _top_bar: ColorRect = $TopBar
@onready var _bottom_bar: ColorRect = $BottomBar

## Height of each bar as fraction of viewport height.
const BAR_HEIGHT_RATIO: float = 0.075
const ANIMATE_IN_DURATION: float = 0.6
const ANIMATE_OUT_DURATION: float = 0.5

var _active_tween: Tween = null
var _bars_visible: bool = false


func _ready() -> void:
	# Start hidden (bars off-screen)
	_top_bar.modulate.a = 0.0
	_bottom_bar.modulate.a = 0.0
	EventBus.letterbox_toggled.connect(_on_letterbox_toggled)


func show_letterbox(duration: float = ANIMATE_IN_DURATION) -> void:
	if _bars_visible:
		return
	_bars_visible = true
	_animate(1.0, duration)


func hide_letterbox(duration: float = ANIMATE_OUT_DURATION) -> void:
	if not _bars_visible:
		return
	_bars_visible = false
	_animate(0.0, duration)


func _on_letterbox_toggled(visible: bool) -> void:
	if visible:
		show_letterbox()
	else:
		hide_letterbox()


func _animate(target_alpha: float, duration: float) -> void:
	if _active_tween:
		_active_tween.kill()
	_active_tween = create_tween().set_parallel(true)
	_active_tween.tween_property(_top_bar, "modulate:a", target_alpha, duration)
	_active_tween.tween_property(_bottom_bar, "modulate:a", target_alpha, duration)
