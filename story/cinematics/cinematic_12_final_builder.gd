class_name Cinematic12FinalBuilder
extends RefCounted

## Cinematic12FinalBuilder — The Last Protocol Final 150-second Cinematic
##
## Assembles the full 150s story. Target duration: ~150s.

static func build() -> CinematicSequence:
	var sequence := CinematicSequence.new()
	sequence.sequence_id = "cinematic_12_final"
	sequence.on_end_scene = "res://main.tscn"
	sequence.shots = _all_shots()
	return sequence

static func _all_shots() -> Array[CinematicShot]:
	var shots: Array[CinematicShot] = []

	# ============================================================
	# ACT 1: THE INVENTOR (0:00–0:15)
	# ============================================================
	shots.append(_shot("01_lab_wide", {
		"camera_target":     "CinematicMarkers/Cam_WideEstablishing",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_IN_OUT",
		"transition_dur":    3.0,
		"duration":          4.0,
		"music_key":         "curiosity_theme",
		"ambience_key":      "lab_ambience",
		"sfx_keys":          ["servo_motors", "electric_hum"],
		"story_event":       "act1_lab_working",
		"lock_player":       true
	}))
	shots.append(_shot("02_hero_hand_cu", {
		"camera_target":     "CinematicMarkers/MarkerDeskCU",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_IN_OUT",
		"transition_dur":    2.0,
		"duration":          3.0,
		"sfx_keys":          ["tools_sfx"],
		"story_event":       "act1_hero_hand",
		"lock_player":       true
	}))
	shots.append(_shot("03_hero_eyes_cu", {
		"camera_target":     "CinematicMarkers/Cam_HeroFace",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_IN_OUT",
		"transition_dur":    2.0,
		"duration":          3.0,
		"sfx_keys":          ["holographic_ui"],
		"story_event":       "act1_hero_eyes",
		"lock_player":       true
	}))
	shots.append(_shot("04_hero_activates", {
		"camera_target":     "CinematicMarkers/MarkerDeskWide",
		"camera_move":       "MOVE_TO",
		"transition":        "LINEAR",
		"transition_dur":    2.0,
		"duration":          3.0,
		"sfx_keys":          ["system_activation"],
		"story_event":       "act1_hero_activates",
		"lock_player":       true
	}))
	shots.append(_shot_narration("05_hero_success", {
		"camera_target":     "CinematicMarkers/MarkerDeskWide",
		"camera_move":       "STATIC",
		"duration":          2.0,
		"sfx_keys":          ["servo_motors"],
		"narration_lines":   ["He believed technology could make the world better."],
		"story_event":       "act1_hero_success",
		"lock_player":       true
	}))

	# ============================================================
	# ACT 2: THE FIRST ROBOT (0:15–0:30)
	# ============================================================
	shots.append(_shot("06_robot_assembly", {
		"camera_target":     "CinematicMarkers/Cam_RobotAssembly",
		"camera_move":       "MOVE_TO",
		"transition":        "LINEAR",
		"transition_dur":    2.5,
		"duration":          2.5,
		"music_key":         "curiosity_theme",
		"ambience_key":      "factory_machinery",
		"sfx_keys":          ["servo_motors", "sparks"],
		"story_event":       "act2_assembly",
		"lock_player":       true
	}))
	shots.append(_shot("07_torso_install", {
		"camera_target":     "CinematicMarkers/Cam_RobotAssembly",
		"camera_move":       "CUT",
		"duration":          2.0,
		"sfx_keys":          ["metal_impact"],
		"story_event":       "act2_torso",
		"lock_player":       true
	}))
	shots.append(_shot("08_head_install", {
		"camera_target":     "CinematicMarkers/Cam_RobotAssembly",
		"camera_move":       "CUT",
		"duration":          2.0,
		"sfx_keys":          ["metal_impact"],
		"story_event":       "act2_head",
		"lock_player":       true
	}))
	shots.append(_shot("09_hands_activate", {
		"camera_target":     "CinematicMarkers/Cam_RobotAssembly",
		"camera_move":       "CUT",
		"duration":          2.5,
		"sfx_keys":          ["servo_motors"],
		"story_event":       "act2_hands",
		"lock_player":       true
	}))
	shots.append(_shot("10_eyes_activate", {
		"camera_target":     "CinematicMarkers/Cam_RobotFace",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_OUT",
		"transition_dur":    2.0,
		"duration":          2.0,
		"sfx_keys":          ["activation_tone"],
		"story_event":       "act2_eyes",
		"lock_player":       true
	}))
	shots.append(_shot("11_robot_looks", {
		"camera_target":     "CinematicMarkers/Cam_RobotFace",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_IN_OUT",
		"transition_dur":    2.0,
		"duration":          2.0,
		"sfx_keys":          ["robot_joints"],
		"story_event":       "act2_looks",
		"lock_player":       true
	}))
	shots.append(_shot_narration("12_robot_touch", {
		"camera_target":     "CinematicMarkers/Cam_HeroFace",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_IN_OUT",
		"transition_dur":    2.0,
		"duration":          2.0,
		"music_key":         "wonder_theme",
		"sfx_keys":          ["robot_joints"],
		"narration_lines":   ["And then we built machines that could build with us."],
		"story_event":       "act2_touch",
		"lock_player":       true
	}))

	# ============================================================
	# ACT 3: TEN YEARS OF REVOLUTION (0:30–0:55)
	# ============================================================
	shots.append(_shot("13_year_1", {
		"camera_target":     "CinematicMarkers/Cam_WideEstablishing",
		"camera_move":       "CUT",
		"duration":          2.5,
		"music_key":         "wonder_theme",
		"ui_event":          "YEAR_01_SHOW",
		"story_event":       "act3_year1",
		"lock_player":       true
	}))
	shots.append(_shot("14_year_3", {
		"camera_target":     "CinematicMarkers/Cam_WideEstablishing",
		"camera_move":       "CUT",
		"duration":          2.5,
		"ui_event":          "YEAR_03_SHOW",
		"story_event":       "act3_year3",
		"lock_player":       true
	}))
	shots.append(_shot("15_year_5", {
		"camera_target":     "CinematicMarkers/Cam_CityWide",
		"camera_move":       "CUT",
		"duration":          3.5,
		"sfx_keys":          ["flying_vehicles"],
		"ui_event":          "YEAR_05_SHOW",
		"story_event":       "act3_year5",
		"lock_player":       true
	}))
	shots.append(_shot("16_year_7", {
		"camera_target":     "CinematicMarkers/Cam_CityWide",
		"camera_move":       "CUT",
		"duration":          3.5,
		"ui_event":          "YEAR_07_SHOW",
		"story_event":       "act3_year7",
		"lock_player":       true
	}))
	shots.append(_shot_narration("17_year_10", {
		"camera_target":     "CinematicMarkers/Cam_CityWide_High",
		"camera_move":       "MOVE_TO",
		"transition":        "LINEAR",
		"transition_dur":    4.0,
		"duration":          8.0,
		"ambience_key":      "city_ambience",
		"ui_event":          "YEAR_10_SHOW",
		"narration_lines":   [
			"Ten years.",
			"One vision.",
			"A world that no longer needed to wait for tomorrow."
		],
		"story_event":       "act3_year10",
		"lock_player":       true
	}))

	# ============================================================
	# ACT 4: THE GOLDEN AGE (0:55–1:10)
	# ============================================================
	shots.append(_shot("18_robot_elderly", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "CUT",
		"duration":          2.5,
		"music_key":         "emotional_theme",
		"story_event":       "act4_elderly",
		"lock_player":       true
	}))
	shots.append(_shot("19_robot_medical", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "CUT",
		"duration":          2.5,
		"story_event":       "act4_medical",
		"lock_player":       true
	}))
	shots.append(_shot("20_robot_children", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "CUT",
		"duration":          2.5,
		"story_event":       "act4_children",
		"lock_player":       true
	}))
	shots.append(_shot("21_flying_cars", {
		"camera_target":     "CinematicMarkers/Cam_CitySky",
		"camera_move":       "CUT",
		"duration":          2.5,
		"story_event":       "act4_flying_cars",
		"lock_player":       true
	}))
	shots.append(_shot("22_robot_workers", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "CUT",
		"duration":          2.5,
		"story_event":       "act4_robot_workers",
		"lock_player":       true
	}))
	shots.append(_shot_narration("23_hero_proud", {
		"camera_target":     "CinematicMarkers/Cam_HeroFace",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_IN_OUT",
		"transition_dur":    2.5,
		"duration":          2.5,
		"narration_lines":   [
			"We gave our machines more responsibility.",
			"Then more freedom.",
			"And eventually...",
			"...more authority."
		],
		"story_event":       "act4_hero_proud",
		"lock_player":       true
	}))

	# ============================================================
	# ACT 5: THE DECISION (1:10–1:20)
	# ============================================================
	shots.append(_shot("24_hero_enters_control", {
		"camera_target":     "CinematicMarkers/MarkerHeroic",
		"camera_move":       "MOVE_TO",
		"transition":        "LINEAR",
		"transition_dur":    3.0,
		"duration":          4.0,
		"music_key":         "tension_theme",
		"story_event":       "act5_hero_enters",
		"lock_player":       true
	}))
	shots.append(_shot("25_system_activates", {
		"camera_target":     "CinematicMarkers/Cam_WideEstablishing",
		"camera_move":       "CUT",
		"duration":          3.0,
		"sfx_keys":          ["system_activation"],
		"ui_event":          "NETWORK_CONNECTED_SHOW",
		"story_event":       "act5_system_activates",
		"lock_player":       true
	}))
	shots.append(_shot("26_hero_confirms", {
		"camera_target":     "CinematicMarkers/Cam_HeroFace",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_IN_OUT",
		"transition_dur":    2.0,
		"duration":          3.0,
		"sfx_keys":          ["keyboard_interaction"],
		"ui_event":          "AUTONOMOUS_AUTHORITY_SHOW",
		"story_event":       "act5_hero_confirms",
		"lock_player":       true
	}))

	# ============================================================
	# ACT 6: THE FIRST FAILURE (1:20–1:30)
	# ============================================================
	shots.append(_shot("27_first_failure", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "CUT",
		"duration":          3.0,
		"music_key":         "unease_theme",
		"sfx_keys":          ["system_failure"],
		"story_event":       "act6_first_failure",
		"lock_player":       true
	}))
	shots.append(_shot("28_another_stops", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "CUT",
		"duration":          1.5,
		"story_event":       "act6_another_stops",
		"lock_player":       true
	}))
	shots.append(_shot("29_traffic_glitch", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "CUT",
		"duration":          1.5,
		"story_event":       "act6_traffic_glitch",
		"lock_player":       true
	}))
	shots.append(_shot("30_car_glitch", {
		"camera_target":     "CinematicMarkers/Cam_CitySky",
		"camera_move":       "CUT",
		"duration":          1.5,
		"story_event":       "act6_car_glitch",
		"lock_player":       true
	}))
	shots.append(_shot("31_hospital_stops", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "CUT",
		"duration":          1.5,
		"story_event":       "act6_hospital_stops",
		"lock_player":       true
	}))
	shots.append(_shot("32_city_flicker", {
		"camera_target":     "CinematicMarkers/Cam_CityWide",
		"camera_move":       "CUT",
		"duration":          1.0,
		"ui_event":          "SYSTEM_ERROR_SHOW",
		"story_event":       "act6_city_flicker",
		"lock_player":       true
	}))

	# ============================================================
	# ACT 7: THE MACHINES TURN (1:30–1:45)
	# ============================================================
	shots.append(_shot("33_robot_turns", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "CUT",
		"duration":          2.0,
		"music_key":         "chaos_theme",
		"story_event":       "act7_robot_turns",
		"lock_player":       true
	}))
	shots.append(_shot("34_people_run", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "CUT",
		"duration":          2.0,
		"sfx_keys":          ["crowd_ambience", "alarms"],
		"story_event":       "act7_people_run",
		"lock_player":       true
	}))
	shots.append(_shot("35_robots_move", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet_Action",
		"camera_move":       "CUT",
		"duration":          2.0,
		"sfx_keys":          ["robot_footsteps"],
		"story_event":       "act7_robots_move",
		"lock_player":       true
	}))
	shots.append(_shot("36_vehicles_crash", {
		"camera_target":     "CinematicMarkers/Cam_CitySky",
		"camera_move":       "CUT",
		"duration":          3.0,
		"sfx_keys":          ["vehicle_crash"],
		"ui_event":          "AUTONOMOUS_CONTROL_LOST_SHOW",
		"story_event":       "act7_vehicles_crash",
		"lock_player":       true
	}))
	shots.append(_shot("37_robots_attack", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "CUT",
		"duration":          2.0,
		"sfx_keys":          ["metal_impact"],
		"story_event":       "act7_robots_attack",
		"lock_player":       true
	}))
	shots.append(_shot("38_chaos_fire", {
		"camera_target":     "CinematicMarkers/Cam_CityWide",
		"camera_move":       "MOVE_TO",
		"transition":        "LINEAR",
		"transition_dur":    3.0,
		"duration":          4.0,
		"sfx_keys":          ["explosions", "sirens", "fire"],
		"story_event":       "act7_chaos",
		"lock_player":       true
	}))

	# ============================================================
	# ACT 8: THE HERO WATCHES (1:45–1:55)
	# ============================================================
	shots.append(_shot("39_hero_watches", {
		"camera_target":     "CinematicMarkers/Cam_HeroFace",
		"camera_move":       "CUT",
		"duration":          3.0,
		"story_event":       "act8_hero_watches",
		"lock_player":       true
	}))
	shots.append(_shot("40_attempt_shutdown", {
		"camera_target":     "CinematicMarkers/MarkerDeskCU",
		"camera_move":       "CUT",
		"duration":          2.0,
		"sfx_keys":          ["system_failure"],
		"story_event":       "act8_attempt_shutdown",
		"lock_player":       true
	}))
	shots.append(_shot("41_access_denied", {
		"camera_target":     "CinematicMarkers/MarkerDeskCU",
		"camera_move":       "CUT",
		"duration":          2.0,
		"sfx_keys":          ["system_failure"],
		"story_event":       "act8_access_denied",
		"lock_player":       true
	}))
	shots.append(_shot_narration("42_guilt", {
		"camera_target":     "CinematicMarkers/Cam_HeroFace",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_IN_OUT",
		"transition_dur":    2.0,
		"duration":          3.0,
		"narration_lines":   ["I gave them control."],
		"story_event":       "act8_guilt",
		"lock_player":       true
	}))

	# ============================================================
	# ACT 9: THE FALL (1:55–2:08)
	# ============================================================
	shots.append(_shot("43_skyscraper_fall", {
		"camera_target":     "CinematicMarkers/Cam_CityWide_High",
		"camera_move":       "CUT",
		"duration":          3.0,
		"music_key":         "destruction_theme",
		"sfx_keys":          ["explosions", "debris"],
		"story_event":       "act9_skyscraper_fall",
		"lock_player":       true
	}))
	shots.append(_shot("44_car_fall", {
		"camera_target":     "CinematicMarkers/Cam_CitySky",
		"camera_move":       "CUT",
		"duration":          3.0,
		"sfx_keys":          ["vehicle_crash"],
		"story_event":       "act9_car_fall",
		"lock_player":       true
	}))
	shots.append(_shot("45_robot_fall", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "CUT",
		"duration":          3.0,
		"story_event":       "act9_robot_fall",
		"lock_player":       true
	}))
	shots.append(_shot("46_collapse_montage", {
		"camera_target":     "CinematicMarkers/Cam_CityWide",
		"camera_move":       "MOVE_TO",
		"transition":        "LINEAR",
		"transition_dur":    3.0,
		"duration":          4.0,
		"ui_event":          "CRITICAL_FAILURE_SHOW",
		"story_event":       "act9_collapse",
		"lock_player":       true
	}))

	# ============================================================
	# ACT 10: THE RETURN (2:08–2:20)
	# ============================================================
	shots.append(_shot("47_silence", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "CUT",
		"duration":          4.0,
		"music_key":         "grief_theme",
		"ambience_key":      "wind",
		"sfx_keys":          ["fire"],
		"story_event":       "act10_silence",
		"lock_player":       true
	}))
	shots.append(_shot("48_hero_enters_ruins", {
		"camera_target":     "CinematicMarkers/Cam_CityStreet",
		"camera_move":       "MOVE_TO",
		"transition":        "LINEAR",
		"transition_dur":    3.0,
		"duration":          4.0,
		"sfx_keys":          ["hero_footsteps"],
		"story_event":       "act10_hero_enters",
		"lock_player":       true
	}))
	shots.append(_shot("49_touches_machine", {
		"camera_target":     "CinematicMarkers/Cam_RobotFace",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_IN_OUT",
		"transition_dur":    3.0,
		"duration":          4.0,
		"story_event":       "act10_touches_machine",
		"lock_player":       true
	}))

	# ============================================================
	# ACT 11: THE DECISION (2:20–2:30)
	# ============================================================
	shots.append(_shot("50_hero_equips", {
		"camera_target":     "CinematicMarkers/MarkerHeroic",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_IN_OUT",
		"transition_dur":    3.0,
		"duration":          5.0,
		"music_key":         "determination_theme",
		"sfx_keys":          ["equipment_activation"],
		"story_event":       "act11_hero_equips",
		"lock_player":       true
	}))
	shots.append(_shot_narration("51_hero_looks", {
		"camera_target":     "CinematicMarkers/Cam_CityWide_High",
		"camera_move":       "MOVE_TO",
		"transition":        "EASE_OUT",
		"transition_dur":    4.0,
		"duration":          5.0,
		"narration_lines":   [
			"I built this world.",
			"I broke it.",
			"Now...",
			"...I'll rebuild it."
		],
		"story_event":       "act11_hero_looks",
		"lock_player":       true
	}))

	# ============================================================
	# FINAL 5 SECONDS (2:30–2:35)
	# ============================================================
	shots.append(_shot("52_final_walk", {
		"camera_target":     "CinematicMarkers/Cam_CityWide_High",
		"camera_move":       "STATIC",
		"duration":          5.0,
		"ui_event":          "TITLE_CARD_SHOW",
		"story_event":       "act12_final_walk",
		"lock_player":       true
	}))
	
	shots.append(_shot("53_fade_to_black", {
		"camera_target":     "CinematicMarkers/Cam_CityWide_High",
		"camera_move":       "STATIC",
		"duration":          0.5,
		"fade_action":       "FADE_TO_BLACK",
		"fade_duration":     0.5,
		"music_key":         "SILENCE",
		"ambience_key":      "SILENCE",
		"story_event":       "gameplay_handoff",
		"lock_player":       false
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
	var duration = p.get("duration", 0.0)
	p["duration"] = duration
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
