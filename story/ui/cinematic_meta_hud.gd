## CinematicMetaHUD — Contextual technical metadata overlay.
##
## Shows small technical labels (YEAR, LOCATION, SYSTEM, CREATOR, PROTOCOL)
## during cinematic shots when shot.hud_metadata is non-empty.
## Fades in at shot start and out when the next shot begins or clears.
##
## Team Ownership: Story Team
##
## FIX: CanvasLayer extends Node (not CanvasItem), so it has no modulate property.
## All fade operations are applied to _anchor (the inner Control child), which
## does inherit CanvasItem.modulate.
##
extends CanvasLayer


@onready var _anchor: Control = $MetaAnchor
@onready var _container: VBoxContainer = $MetaAnchor/MetaContainer

const FADE_DURATION: float = 0.4
const HOLD_BEFORE_FADE_OUT: float = 3.5

## Canonical display order of metadata keys.
const KEY_ORDER: Array[String] = ["YEAR", "LOCATION", "SYSTEM", "CREATOR", "PROTOCOL"]

var _active_tween: Tween = null
var _fade_out_timer: SceneTreeTimer = null


func _ready() -> void:
	_anchor.modulate.a = 0.0
	EventBus.hud_metadata_shown.connect(_on_hud_metadata_shown)


func _on_hud_metadata_shown(metadata: Dictionary) -> void:
	if metadata.is_empty():
		_fade_out()
		return
	_build_labels(metadata)
	_fade_in()


func _build_labels(metadata: Dictionary) -> void:
	# Clear existing labels
	for child in _container.get_children():
		child.queue_free()

	for key in KEY_ORDER:
		if not metadata.has(key):
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var key_lbl := Label.new()
		key_lbl.text = key
		key_lbl.add_theme_font_size_override("font_size", 9)
		key_lbl.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0, 0.7))
		key_lbl.uppercase = true
		key_lbl.custom_minimum_size = Vector2(72, 0)

		var val_lbl := Label.new()
		val_lbl.text = str(metadata[key])
		val_lbl.add_theme_font_size_override("font_size", 9)
		val_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.9))
		val_lbl.uppercase = true

		row.add_child(key_lbl)
		row.add_child(val_lbl)
		_container.add_child(row)


func _fade_in() -> void:
	if _active_tween:
		_active_tween.kill()
	if _fade_out_timer:
		_fade_out_timer = null

	_active_tween = create_tween()
	_active_tween.tween_property(_anchor, "modulate:a", 1.0, FADE_DURATION)
	_active_tween.tween_callback(func():
		_fade_out_timer = get_tree().create_timer(HOLD_BEFORE_FADE_OUT)
		_fade_out_timer.timeout.connect(_fade_out)
	)


func _fade_out() -> void:
	_fade_out_timer = null
	if _active_tween:
		_active_tween.kill()
	_active_tween = create_tween()
	_active_tween.tween_property(_anchor, "modulate:a", 0.0, FADE_DURATION)
