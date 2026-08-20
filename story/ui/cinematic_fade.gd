class_name CinematicFade
extends CanvasLayer

@onready var fade_rect: ColorRect = $FadeRect

var _active_tween: Tween = null


func _ready() -> void:
	add_to_group("cinematic_fade")
	fade_rect.visible = false
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0


func run_fade(action: String, duration: float) -> void:
	match action:
		"FADE_IN", "FADE_FROM_BLACK":
			await fade_from_black(duration)
		"FADE_OUT", "FADE_TO_BLACK":
			await fade_to_black(duration)
		_:
			push_warning("CinematicFade: Unsupported fade action '%s'." % action)


func fade_to_black(duration: float = 0.5) -> void:
	await _fade_to(1.0, duration, false)


func fade_from_black(duration: float = 0.5) -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	await _fade_to(0.0, duration, true)


func clear_fade() -> void:
	if _active_tween != null:
		_active_tween.kill()
		_active_tween = null
	fade_rect.modulate.a = 0.0
	fade_rect.visible = false


func is_black() -> bool:
	return fade_rect.visible and fade_rect.modulate.a >= 0.99


func is_clear() -> bool:
	return not fade_rect.visible or fade_rect.modulate.a <= 0.01


func _fade_to(target_alpha: float, duration: float, hide_when_clear: bool) -> void:
	if _active_tween != null:
		_active_tween.kill()
	fade_rect.visible = true
	if duration <= 0.0:
		fade_rect.modulate.a = target_alpha
		if hide_when_clear and target_alpha <= 0.0:
			fade_rect.visible = false
		return
	_active_tween = create_tween()
	_active_tween.tween_property(fade_rect, "modulate:a", target_alpha, duration)
	await _active_tween.finished
	_active_tween = null
	if hide_when_clear and target_alpha <= 0.0:
		fade_rect.visible = false
