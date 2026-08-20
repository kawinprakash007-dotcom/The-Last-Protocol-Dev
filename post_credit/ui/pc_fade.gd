## PCFade — Post-credit screen fade overlay.
##
## Completely isolated from res://story/ui/cinematic_fade.
## Used only by res://post_credit/.
##
## fade_in()  → reveal from black (overlay: opaque → transparent)
## fade_out() → go to black      (overlay: transparent → opaque)
##
extends ColorRect


func _ready() -> void:
	color = Color.BLACK
	modulate.a = 1.0   # Start fully opaque — screen begins black
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func fade_in(duration: float = 0.75) -> void:
	## Reveal: fades the overlay from opaque to transparent.
	modulate.a = 1.0
	var t := create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 0.0, duration)
	await t.finished


func fade_out(duration: float = 0.75) -> void:
	## Black: fades the overlay from transparent to opaque.
	modulate.a = 0.0
	var t := create_tween()
	t.set_ease(Tween.EASE_IN)
	t.tween_property(self, "modulate:a", 1.0, duration)
	await t.finished


func instant_black() -> void:
	modulate.a = 1.0


func instant_clear() -> void:
	modulate.a = 0.0
