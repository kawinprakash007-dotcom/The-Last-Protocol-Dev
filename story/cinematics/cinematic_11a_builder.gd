class_name Cinematic11ABuilder
extends RefCounted

## Cinematic11ABuilder — Machine Revolt Sequence (25-35s)
##
## Assembles Phase 11A sequence:
##   01 - peaceful city, robot stops
##   02 - robot head close-up, error UI
##   03 - second robot turns
##   04 - human panic
##   05 - robot attack
##   06 - vehicle chaos
##   07 - city security failure
##   08 - robot swarm
##   09 - hero watches
##   10 - lab turns against him
##   11 - world falls
##   12 - silence
##   13 - hero realization
##   14 - final world shot

static func build() -> CinematicSequence:
	var sequence := CinematicSequence.new()
	sequence.sequence_id = "cinematic_11a_machine_revolt"
	sequence.on_end_scene = "res://main.tscn"
	sequence.shots = _all_shots()
	return sequence

static func _all_shots() -> Array[CinematicShot]:
	var shots: Array[CinematicShot] = []

	# SHOT 01 — THE FIRST FAILURE (2.5s)
	shots.append(_shot("01_first_failure", {
		"camera_target":     "CinematicMarkers/Cam_CityWide",
		"camera_move":       "MOVE_TO",
		"transition":        "LINEAR",
		"transition_dur":    2.5,
		"duration":          2.5,
		"music_key":         "wonder_theme",
		"ambience_key":      "city_ambience",
		"sfx_keys":          ["servo_motors", "robot_footsteps"],
		"story_event":       "peaceful_city",
		"lock_player":       true
	}))

	# SHOT 02 — NETWORK FAILURE (2s)
	shots.append(_shot("02_network_failure", {
		"camera_target":     "CinematicMarkers/Cam_RobotFace",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_IN_OUT",
		"transition_dur":    2.0,
		"duration":          2.0,
		"music_key":         "unease_theme",
		"sfx_keys":          ["electrical_pulse", "system_failure"],
		"ui_event":          "NETWORK_ERROR_SHOW",
		"story_event":       "robot_eye_glitch",
		"lock_player":       true
	}))

	# SHOT 03 — THE SECOND ROBOT (2s)
	shots.append(_shot("03_second_robot", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_IN_OUT",
		"transition_dur":    1.5,
		"duration":          2.0,
		"sfx_keys":          ["robot_joints"],
		"story_event":       "second_robot_turns",
		"lock_player":       true
	}))

	# SHOT 04 — HUMAN PANIC (2.5s)
	shots.append(_shot("04_human_panic", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "MOVE_TO",
		"transition":        "LINEAR",
		"transition_dur":    2.0,
		"duration":          2.5,
		"music_key":         "panic_theme",
		"ambience_key":      "sirens",
		"sfx_keys":          ["crowd_ambience", "alarms"],
		"ui_event":          "SECURITY_OVERRIDE_SHOW",
		"story_event":       "human_panic",
		"lock_player":       true
	}))

	# SHOT 05 — ROBOT ATTACK (2s)
	shots.append(_shot("05_robot_attack", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet_Action",
		"camera_move":       "CUT",
		"transition":        "CUT",
		"transition_dur":    0.0,
		"duration":          2.0,
		"sfx_keys":          ["robot_footsteps", "metal_impact"],
		"story_event":       "robot_attack",
		"lock_player":       true
	}))

	# SHOT 06 — VEHICLE CHAOS (2s)
	shots.append(_shot("06_vehicle_chaos", {
		"camera_target":     "CinematicMarkers/Cam_CitySky",
		"camera_move":       "CUT",
		"transition":        "CUT",
		"transition_dur":    0.0,
		"duration":          2.0,
		"sfx_keys":          ["vehicle_crash", "debris"],
		"story_event":       "vehicle_crash",
		"lock_player":       true
	}))

	# SHOT 07 — CITY SECURITY FAILURE (2s)
	shots.append(_shot("07_city_security_failure", {
		"camera_target":     "CinematicMarkers/Cam_CityWide",
		"camera_move":       "CUT",
		"transition":        "CUT",
		"transition_dur":    0.0,
		"duration":          2.0,
		"sfx_keys":          ["system_failure", "electrical_pulse"],
		"ui_event":          "CITY_FAILURE_SHOW",
		"story_event":       "city_security_failure",
		"lock_player":       true
	}))

	# SHOT 08 — ROBOT SWARM (3s)
	shots.append(_shot("08_robot_swarm", {
		"camera_target":     "CinematicMarkers/Cam_CityWide_High",
		"camera_move":       "MOVE_TO",
		"transition":        "LINEAR",
		"transition_dur":    3.0,
		"duration":          3.0,
		"music_key":         "chaos_theme",
		"sfx_keys":          ["robot_footsteps", "explosions"],
		"story_event":       "robot_swarm",
		"lock_player":       true
	}))

	# SHOT 09 — HERO SEES IT (2s)
	shots.append(_shot("09_hero_sees_it", {
		"camera_target":     "CinematicMarkers/Cam_HeroFace",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_IN_OUT",
		"transition_dur":    2.0,
		"duration":          2.0,
		"sfx_keys":          ["alarms", "explosions"],
		"story_event":       "hero_watches_revolt",
		"lock_player":       true
	}))

	# SHOT 10 — THE LAB TURNS AGAINST HIM (2.5s)
	shots.append(_shot("10_lab_turns", {
		"camera_target":     "CinematicMarkers/Cam_WideEstablishing",
		"camera_move":       "MOVE_TO",
		"transition":        "LINEAR",
		"transition_dur":    2.5,
		"duration":          2.5,
		"sfx_keys":          ["servo_motors", "metal_impact"],
		"story_event":       "lab_malfunctions",
		"lock_player":       true
	}))

	# SHOT 11 — THE WORLD FALLS (3.5s)
	shots.append(_shot("11_world_falls", {
		"camera_target":     "CinematicMarkers/Cam_CityWide_High",
		"camera_move":       "MOVE_TO",
		"transition":        "LINEAR",
		"transition_dur":    3.0,
		"duration":          3.5,
		"sfx_keys":          ["explosions", "debris", "system_failure"],
		"story_event":       "world_falls",
		"lock_player":       true
	}))

	# SHOT 12 — SILENCE (3s)
	shots.append(_shot("12_silence", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "MOVE_TO",
		"transition":        "LINEAR",
		"transition_dur":    2.5,
		"duration":          3.0,
		"music_key":         "SILENCE",
		"ambience_key":      "wind",
		"sfx_keys":          ["fire"],
		"story_event":       "destroyed_street",
		"lock_player":       true
	}))

	# SHOT 13 — HERO'S REALIZATION (3.5s)
	shots.append(_shot_narration("13_hero_realization", {
		"camera_target":     "CinematicMarkers/Cam_HeroFace",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_IN_OUT",
		"transition_dur":    3.0,
		"narration_lines":   [
			"I gave them the power.",
			"I have to take it back."
		],
		"music_key":         "regret_theme",
		"story_event":       "hero_realization_revolt",
		"lock_player":       true
	}))

	# SHOT 14 — FINAL WORLD SHOT (2.5s)
	shots.append(_shot("14_final_world_shot", {
		"camera_target":     "CinematicMarkers/Cam_CityWide_High",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_OUT",
		"transition_dur":    2.5,
		"duration":          2.5,
		"fade_action":       "FADE_TO_BLACK",
		"fade_duration":     2.0,
		"ui_event":          "GLOBAL_CRITICAL_SHOW",
		"story_event":       "final_world_shot",
		"lock_player":       true
	}))

	return shots


static func _shot(shot_id: String, p: Dictionary) -> CinematicShot:
	var s := CinematicShot.new()
	s.shot_id                   = shot_id
	s.camera_action             = p.get("camera_move", "STATIC")
	var t: String               = p.get("camera_target", "")
	s.camera_target             = NodePath(t) if t != "" else NodePath("")
	s.camera_transition         = p.get("transition", "EASE_IN_OUT")
	s.camera_transition_duration = p.get("transition_dur", 0.0)
	s.duration                  = p.get("duration", 2.0)
	s.fade_action               = p.get("fade_action", "")
	s.fade_duration             = p.get("fade_duration", 0.5)
	s.music_key                 = p.get("music_key", "")
	s.ambience_key              = p.get("ambience_key", "")
	s.sfx_keys                  = p.get("sfx_keys", []) as Array[String]
	s.ui_event                  = p.get("ui_event", "")
	s.story_event_on_start      = p.get("story_event", "")
	s.on_complete               = p.get("on_complete", "")
	s.lock_player               = p.get("lock_player", true)
	return s

static func _shot_narration(shot_id: String, p: Dictionary) -> CinematicShot:
	p["duration"] = 0.0
	var s = _shot(shot_id, p)

	var lines = p.get("narration_lines", [])
	if not lines.is_empty():
		var seq := DialogueSequence.new()
		seq.sequence_id = shot_id + "_narration"
		var dlines: Array[DialogueLine] = []
		for text in lines:
			var l := DialogueLine.new()
			l.speaker_id = "NARRATION"
			l.text = text
			dlines.append(l)
		seq.lines = dlines
		s.dialogue_sequence = seq

	return s

