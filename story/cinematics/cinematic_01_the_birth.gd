extends Node3D

@onready var _fade: CinematicFade = $CinematicFade
@onready var _animation_player: AnimationPlayer = $AnimationPlayer

var _transitioning: bool = false

func _ready() -> void:
	if _fade != null:
		_fade.fade_to_black(0.0)

	var objective_hud = get_node_or_null("ObjectiveHUD")
	if objective_hud != null:
		objective_hud.visible = false

	EventBus.story_event_triggered.connect(_on_story_event_triggered)
	EventBus.cinematic_finished.connect(_on_cinematic_finished, CONNECT_ONE_SHOT)

	await get_tree().process_frame

	var builder_script = preload("res://story/cinematics/cinematic_01_builder.gd")
	var sequence: CinematicSequence = builder_script.build()
	CinematicManager.play_sequence(sequence)

func _on_story_event_triggered(event_id: String) -> void:
	if _animation_player == null:
		return
	
	if event_id == "components_reveal":
		if _animation_player.has_animation("component_reveal"):
			_animation_player.play("component_reveal")
	elif event_id == "assembly_start":
		if _animation_player.has_animation("assembly_process"):
			_animation_player.play("assembly_process")
	elif event_id == "cables_connect":
		if _animation_player.has_animation("cables_connect"):
			_animation_player.play("cables_connect")
	elif event_id == "head_install":
		if _animation_player.has_animation("head_install"):
			_animation_player.play("head_install")
	elif event_id == "activation_start":
		if _animation_player.has_animation("activation"):
			_animation_player.play("activation")
	elif event_id == "scientist_observe":
		if _animation_player.has_animation("scientist_observe"):
			_animation_player.play("scientist_observe")
	elif event_id == "contact_start":
		if _animation_player.has_animation("first_contact"):
			_animation_player.play("first_contact")
	elif event_id == "stand_start":
		if _animation_player.has_animation("first_walk"):
			_animation_player.play("first_walk")

func _on_cinematic_finished(sequence_id: String) -> void:
	if sequence_id != "cinematic_01_the_birth":
		return
	if _transitioning:
		return
	_transitioning = true
	_begin_scene_transition()

func _begin_scene_transition() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)

	var overlay := ColorRect.new()
	overlay.color = Color.BLACK
	overlay.modulate.a = 0.0
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)

	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.8)
	await tween.finished
	get_tree().change_scene_to_file("res://main.tscn")



