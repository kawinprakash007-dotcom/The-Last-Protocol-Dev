class_name Cinematic01Builder
extends RefCounted

static func build() -> CinematicSequence:
	var sequence := CinematicSequence.new()
	sequence.sequence_id = "cinematic_01_the_birth"
	sequence.shots = [
		_shot_01_establishing(),
		_shot_02_component_close(),
		_shot_03_arm_assembly(),
		_shot_04_cable_connection(),
		_shot_05_head_installation(),
		_shot_06_sensor_activation(),
		_shot_07_scientist_reaction(),
		_shot_08_first_contact(),
		_shot_09_complete_laboratory()
	]
	return sequence

static func _shot_01_establishing() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "01_establishing"
	shot.fade_action = "FADE_FROM_BLACK"
	shot.fade_duration = 2.0
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Establishing_Wide"
	shot.camera_transition = "LINEAR"
	shot.camera_transition_duration = 5.0
	shot.duration = 1.0
	shot.lock_player = true
	shot.ambience_key = "electrical_ambience"
	shot.sfx_keys = ["electrical_pulse", "servo_sounds"]
	shot.story_event_on_start = "darkness_start"
	return shot

static func _shot_02_component_close() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "02_component_close"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Component_Close"
	shot.camera_transition = "EASE_IN_OUT"
	shot.camera_transition_duration = 3.0
	shot.duration = 2.0
	shot.lock_player = true
	shot.sfx_keys = ["servo_sounds", "metal_resonance"]
	shot.story_event_on_start = "components_reveal"
	return shot

static func _shot_03_arm_assembly() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "03_arm_assembly"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Arm_Assembly"
	shot.camera_transition = "LINEAR"
	shot.camera_transition_duration = 4.0
	shot.duration = 2.0
	shot.lock_player = true
	shot.sfx_keys = ["mechanical_rhythm", "welding_sfx"]
	shot.story_event_on_start = "assembly_start"
	return shot

static func _shot_04_cable_connection() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "04_cable_connection"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Cable_Connection"
	shot.camera_transition = "EASE_IN_OUT"
	shot.camera_transition_duration = 3.0
	shot.duration = 2.0
	shot.lock_player = true
	shot.sfx_keys = ["hydraulic_hiss"]
	shot.story_event_on_start = "cables_connect"
	return shot

static func _shot_05_head_installation() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "05_head_installation"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Head_Installation"
	shot.camera_transition = "EASE_OUT"
	shot.camera_transition_duration = 3.0
	shot.duration = 2.0
	shot.lock_player = true
	shot.sfx_keys = ["metal_impact"]
	shot.story_event_on_start = "head_install"
	return shot

static func _shot_06_sensor_activation() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "06_sensor_activation"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Sensor_Activation"
	shot.camera_transition = "EASE_IN_OUT"
	shot.camera_transition_duration = 2.0
	shot.duration = 2.0
	shot.lock_player = true
	shot.ambience_key = "near_silence"
	shot.sfx_keys = ["activation_tone"]
	shot.story_event_on_start = "activation_start"
	return shot

static func _shot_07_scientist_reaction() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "07_scientist_reaction"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Scientist_Reaction"
	shot.camera_transition = "EASE_IN_OUT"
	shot.camera_transition_duration = 3.0
	shot.duration = 2.0
	shot.lock_player = true
	shot.story_event_on_start = "scientist_observe"
	return shot

static func _shot_08_first_contact() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "08_first_contact"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/First_Contact"
	shot.camera_transition = "EASE_IN_OUT"
	shot.camera_transition_duration = 4.0
	shot.lock_player = true
	shot.music_key = "warm_theme"
	shot.story_event_on_start = "contact_start"
	
	var seq := DialogueSequence.new()
	seq.sequence_id = "the_birth_narration"
	
	var line1 := DialogueLine.new()
	line1.speaker_id = "NARRATION"
	line1.text = "We built machines to carry what our hands could not."
	
	var line2 := DialogueLine.new()
	line2.speaker_id = "NARRATION"
	line2.text = "To think where we could not."
	
	var line3 := DialogueLine.new()
	line3.speaker_id = "NARRATION"
	line3.text = "To protect what we feared to lose."
	
	seq.lines = [line1, line2, line3]
	shot.dialogue_sequence = seq
	return shot

static func _shot_09_complete_laboratory() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "09_complete_laboratory"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Complete_Laboratory"
	shot.camera_transition = "EASE_OUT"
	shot.camera_transition_duration = 5.0
	shot.duration = 3.0
	shot.lock_player = true
	shot.music_key = "wonder_theme"
	shot.story_event_on_start = "stand_start"
	return shot
