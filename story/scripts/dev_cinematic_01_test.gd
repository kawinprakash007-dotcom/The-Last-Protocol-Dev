extends Node3D

@onready var camera_controller: Node = $CinematicCameraController
@onready var cinematic_camera: Camera3D = $CinematicCamera
@onready var gameplay_camera: Camera3D = $GameplayCamera
@onready var fade: Node = $CinematicFade
@onready var dialogue_ui: DialogueUI = $DialogueUI
@onready var objective_hud: Node = $ObjectiveHUD
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var markers: Node3D = $CinematicMarkers

var _pass_count: int = 0
var _fail_count: int = 0
var _cinematic_started_count: int = 0
var _cinematic_finished_count: int = 0
var _lock_count: int = 0
var _unlock_count: int = 0

func _ready() -> void:
	EventBus.cinematic_started.connect(func(_id: String): _cinematic_started_count += 1)
	EventBus.cinematic_finished.connect(func(_id: String): _cinematic_finished_count += 1)
	EventBus.cinematic_mode_toggled.connect(func(locked: bool):
		if locked:
			_lock_count += 1
		else:
			_unlock_count += 1
	)
	
	# Wire up local animations
	EventBus.story_event_triggered.connect(_on_story_event_triggered)

	var obj_hud = get_node_or_null("ObjectiveHUD")
	if obj_hud != null:
		obj_hud.visible = false

	await get_tree().process_frame
	await _run_tests()


func _on_story_event_triggered(event_id: String) -> void:
	if animation_player == null:
		return
	if event_id == "components_reveal":
		animation_player.play("component_reveal")
	elif event_id == "assembly_start":
		animation_player.play("assembly_process")
	elif event_id == "cables_connect":
		animation_player.play("cables_connect")
	elif event_id == "head_install":
		animation_player.play("head_install")
	elif event_id == "activation_start":
		animation_player.play("activation")
	elif event_id == "scientist_observe":
		animation_player.play("scientist_observe")
	elif event_id == "contact_start":
		animation_player.play("first_contact")
	elif event_id == "stand_start":
		animation_player.play("first_walk")


func _run_tests() -> void:
	print("\n====================================================")
	print("  THE LAST PROTOCOL - CINEMATIC 01 VALIDATION")
	print("====================================================\n")

	var builder_script = preload("res://story/cinematics/cinematic_01_builder.gd")
	var seq := builder_script.build()
	_check(seq != null, "01 Cinematic01Builder.build() returns a CinematicSequence")
	_check(seq.sequence_id == "cinematic_01_the_birth", "02 sequence_id is correct")
	_check(seq.shots.size() == 9, "03 sequence has exactly 9 shots")

	var valid_ids = true
	var unique_ids = {}
	for s in seq.shots:
		if s.shot_id.is_empty():
			valid_ids = false
		if unique_ids.has(s.shot_id):
			valid_ids = false
		unique_ids[s.shot_id] = true
	_check(valid_ids, "04 all shot IDs are non-empty and unique")

	var shot_01 = seq.shots[0]
	_check(shot_01.sfx_keys.has("electrical_pulse"), "05 shot 01 has electrical_pulse SFX")
	_check(shot_01.ambience_key == "electrical_ambience", "06 shot 01 has electrical_ambience")
	
	var shot_02 = seq.shots[1]
	_check(shot_02.story_event_on_start == "components_reveal", "07 shot 02 triggers component_reveal")

	var shot_08 = seq.shots[7]
	_check(_has_speaker(shot_08, "NARRATION"), "08 shot 08 contains NARRATION dialogue")

	_check(camera_controller != null, "09 CinematicCameraController loads")
	_check(fade != null, "10 CinematicFade loads")
	_check(dialogue_ui != null, "11 DialogueUI loads")
	
	var expected_markers := ["Establishing_Wide", "Component_Close", "Arm_Assembly", "Cable_Connection", "Head_Installation", "Sensor_Activation", "Scientist_Reaction", "First_Contact", "Complete_Laboratory"]
	var missing_markers := 0
	for m_name in expected_markers:
		if not markers.has_node(m_name):
			missing_markers += 1
	_check(missing_markers == 0, "12 all required camera markers exist in test scene")

	CinematicManager.play_sequence(seq)
	await get_tree().create_timer(0.2).timeout

	_check(_cinematic_started_count == 1, "13 cinematic_started emitted when opening plays")
	_check(_lock_count == 1, "14 player is locked during cinematic")
	_check(CinematicManager.is_active, "15 CinematicManager reports active during opening")

	CinematicManager.stop()
	await get_tree().process_frame

	_check(not CinematicManager.is_active, "16 CinematicManager is inactive after stop()")
	_check(_unlock_count == 1, "17 player unlocked after stop()")
	_check(camera_controller.is_gameplay_camera_current(), "18 gameplay camera restored after stop()")
	_check(not cinematic_camera.current, "19 cinematic camera released after stop()")

	print("\n====================================================")
	print("  RESULTS: %d PASSED   %d FAILED" % [_pass_count, _fail_count])
	print("====================================================\n")
	get_tree().quit(_fail_count)


func _check(condition: bool, label: String) -> void:
	if condition:
		_pass_count += 1
		print("  [PASS] " + label)
	else:
		_fail_count += 1
		print("  [FAIL] " + label)


func _has_speaker(shot: CinematicShot, speaker_id: String) -> bool:
	if shot.dialogue_sequence == null:
		return false
	for line in shot.dialogue_sequence.lines:
		if line.speaker_id == speaker_id:
			return true
	return false
