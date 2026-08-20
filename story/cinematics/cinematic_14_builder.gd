## Cinematic14Builder — Assembles the final 150-second opening cinematic.
##
## "THE LAST PROTOCOL"
##
## Timeline:
##   0–15s   THE INVENTOR          (hero working in lab, close-ups)
##   15–30s  THE FIRST MACHINE     (robot activation, first contact)
##   30–60s  TEN YEARS             (fast montage Years 1→10 with UI stamps)
##   60–80s  THE DECISION          (central control, authorization)
##   80–105s THE NIGHT             (malfunction begins, chaos erupts)
##   105–125s THE FALL             (collapse montage, hero watching)
##   125–140s THE REALIZATION      (quiet ruins, hero confronts creation)
##   140–150s THE LAST PROTOCOL    (hero prepares, title card, cut to black)
##
## Plugs directly into CinematicManager.play_sequence()
## Uses existing CinematicShot / CinematicSequence / DialogueSequence API.
## Does NOT modify any existing scene or script.

class_name Cinematic14Builder
extends RefCounted

static func build() -> CinematicSequence:
	var sequence := CinematicSequence.new()
	sequence.sequence_id = "cinematic_14_the_last_protocol"
	sequence.on_end_scene = "res://main.tscn"
	sequence.shots = _all_shots()
	return sequence

static func _all_shots() -> Array[CinematicShot]:
	var shots: Array[CinematicShot] = []

	# ══════════════════════════════════════════════════════════════════
	# ACT 1 — THE WORLD BEFORE (0–13 s)   PREMIUM REBUILD Phase 14B
	# ══════════════════════════════════════════════════════════════════

	## SHOT 01 — City Dawn Aerial Crane-down (0:00 – 0:04)
	## Camera begins high above the futuristic city, slow cinematic crane downward.
	## CITY_DAWN lighting: amber sun, deep blue sky, thin morning haze.
	shots.append(_shot_narration("01_city_dawn_aerial", {
		"camera_target": "CinematicMarkers/Cam_CityAerial",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 4.0,
		"duration": 4.0,
		"narration_lines": ["Ten years ago, humanity stood at the edge of a new era."],
		"fade_action": "FADE_FROM_BLACK",
		"fade_duration": 1.5,
		"music_key": "wonder_theme",
		"ambience_key": "city_ambience",
		"sfx_keys": ["flying_vehicles", "crowd_ambience"],
		"story_event": "city_dawn_aerial",
		"lock_player": true}))

	## SHOT 02 — City Street Level Dolly (0:04 – 0:06)
	## Low-angle tracking along a futuristic boulevard with moving pedestrians + robots.
	shots.append(_shot("02_city_street_life", {
		"camera_target": "CinematicMarkers/Cam_CityStreet",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 2.5,
		"duration": 2.5,
		"ambience_key": "city_ambience",
		"sfx_keys": ["crowd_ambience", "flying_vehicles"],
		"story_event": "city_street_life",
		"lock_player": true}))

	## SHOT 03 — Laboratory Wide Establishing (0:06 – 0:08)
	## Cut to the advanced robotics laboratory — lab NPCs working, robots active.
	shots.append(_shot_narration("03_lab_establishing", {
		"camera_target": "CinematicMarkers/Cam_LabWide",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 2.0,
		"duration": 2.0,
		"narration_lines": ["One inventor believed machines could take us there."],
		"music_key": "wonder_theme",
		"ambience_key": "lab_ambience",
		"sfx_keys": ["electrical_hum", "servo_sounds"],
		"story_event": "lab_establishing",
		"lock_player": true}))

	## SHOT 04 — Hero Walk Tracking Shot (0:08 – 0:11)
	## Smooth side-tracking camera follows the hero walking through the lab.
	shots.append(_shot("04_hero_walk_tracking", {
		"camera_target": "CinematicMarkers/Cam_HeroTrack",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 3.0,
		"duration": 3.0,
		"sfx_keys": ["footsteps", "keyboard_interaction"],
		"story_event": "hero_walks_lab",
		"lock_player": true}))

	## SHOT 05 — Hero Close-Up Face (0:11 – 0:13)
	## Medium-close-up on hero's face — subtle push-in, he looks at workstation.
	shots.append(_shot_narration("05_hero_face_cu", {
		"camera_target": "CinematicMarkers/Cam_HeroFaceCU",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 2.0,
		"duration": 2.0,
		"narration_lines": ["His first creation was more than a machine."],
		"sfx_keys": ["keyboard_interaction", "holographic_ui"],
		"story_event": "hero_face_cu",
		"lock_player": true}))

	# ══════════════════════════════════════════════════════════════════
	# ACT 2 — ROBOT CONSTRUCTION + ACTIVATION (13–25 s)
	# ══════════════════════════════════════════════════════════════════

	## SHOT 06 — Robot Assembly Line Wide (0:13 – 0:16)
	## Elevated crane shot over the robotic assembly line — multiple robots being built.
	shots.append(_shot("06_robot_assembly_wide", {
		"camera_target": "CinematicMarkers/Cam_AssemblyWide",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 3.0,
		"duration": 3.0,
		"music_key": "growth_theme",
		"ambience_key": "factory_machinery",
		"sfx_keys": ["servo_motors", "robot_joints", "welding_sparks"],
		"ui_event": "ROBOT_DIAGNOSTIC_SHOW",
		"story_event": "robot_assembly_start",
		"lock_player": true}))

	## SHOT 07 — Welding Sparks Close-Up (0:16 – 0:18)
	## Macro close-up on a robotic arm welding a mechanical skeleton. Warm sparks.
	shots.append(_shot("07_weld_sparks_cu", {
		"camera_target": "CinematicMarkers/Cam_WeldCU",
		"camera_move": "MOVE_TO",
		"transition": "LINEAR",
		"transition_dur": 1.5,
		"duration": 2.0,
		"sfx_keys": ["welding_sparks", "servo_motors"],
		"story_event": "welding_detail",
		"lock_player": true}))

	## SHOT 08 — Robot Activation Chamber (0:18 – 0:22)
	## Slow push-in toward completed robot's face. Eyes light up cyan. No blowout.
	## LAB_ROBOT_ACTIVATE lighting: dark room, controlled cyan rim, no overexposure.
	shots.append(_shot_narration("08_robot_activation_cu", {
		"camera_target": "CinematicMarkers/Cam_ActivationCU",
		"camera_move": "MOVE_TO",
		"transition": "EASE_OUT",
		"transition_dur": 4.0,
		"duration": 4.0,
		"narration_lines": ["It was the beginning of a revolution."],
		"sfx_keys": ["electrical_pulse", "activation_tone", "servo_motors"],
		"ui_event": "SYSTEM_STATUS_ONLINE",
		"story_event": "robot_activation",
		"lock_player": true}))

	## SHOT 09 — Hero and Robot Handshake Orbit (0:22 – 0:25)
	## Camera slowly orbits around the hero and robot as they make first contact.
	shots.append(_shot("09_hero_robot_first_contact", {
		"camera_target": "CinematicMarkers/Cam_HandshakeOrbit",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 3.0,
		"duration": 3.0,
		"sfx_keys": ["mechanical_locks", "activation_tone"],
		"story_event": "hero_robot_first_contact",
		"lock_player": true}))


	# ══════════════════════════════════════════════════════════════════
	# ACT 2b — TECHNOLOGICAL REVOLUTION MONTAGE (25–28 s)
	# ══════════════════════════════════════════════════════════════════

	## SHOT 10 — Montage: Revolution (0:25 – 0:28)
	## Fast-cut sequence: robots building city, humans + robots together, flying cars.
	## City behind hero — alive with movement. Music rises to confidence_theme.
	shots.append(_shot_narration("10_montage_revolution", {
		"camera_target": "CinematicMarkers/Cam_MontageA",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 2.5,
		"duration": 3.0,
		"narration_lines": ["In ten years, he transformed the world."],
		"music_key": "confidence_theme",
		"ambience_key": "city_ambience",
		"sfx_keys": ["flying_vehicles", "crowd_ambience"],
		"story_event": "montage_revolution_a",
		"lock_player": true}))

	## SHOT 11 — Hero Observation Platform (0:28 – 0:31)
	## Camera behind hero on elevated platform, orbits to reveal his face.
	## The living city glows behind him. OBSERVATION_PLATFORM lighting.
	shots.append(_shot_narration("11_hero_observation", {
		"camera_target": "CinematicMarkers/Cam_ObservationBehind",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 3.0,
		"duration": 3.0,
		"narration_lines": ["And humanity gave him everything..."],
		"sfx_keys": ["city_ambience", "flying_vehicles", "crowd_ambience"],
		"story_event": "hero_observation_platform",
		"lock_player": true}))

	# ── ACT 3: TEN YEARS OF PROGRESS (31–51s) ──────────────────────────

	shots.append(_shot_narration("10_year03_city_skyline", {
		"camera_target": "CinematicMarkers/Year5_City",
		"camera_move": "CUT",
		"transition": "CUT",
		"transition_dur": 0.0,
		"duration": 4.0,
		"fade_action": "FADE_FROM_BLACK",
		"fade_duration": 0.5,
		"music_key": "growth_theme",
		"ambience_key": "city_ambience",
		"narration_lines": ["Ten years passed. Cities became smarter."],
		"ui_event": "YEAR_03_SHOW",
		"story_event": "montage_year_03",
		"lock_player": true}))

	shots.append(_shot_narration("11_year05_traffic", {
		"camera_target": "CinematicMarkers/Year7_Traffic",
		"camera_move": "CUT",
		"transition": "CUT",
		"transition_dur": 0.0,
		"duration": 4.0,
		"fade_action": "FADE_FROM_BLACK",
		"fade_duration": 0.4,
		"ambience_key": "city_ambience",
		"sfx_keys": ["vehicle_engines"],
		"narration_lines": ["Machines became stronger."],
		"ui_event": "YEAR_05_SHOW",
		"story_event": "montage_year_05",
		"lock_player": true}))

	shots.append(_shot_narration("12_year07_pedestrians", {
		"camera_target": "CinematicMarkers/Year7_Traffic",
		"camera_move": "CUT",
		"transition": "CUT",
		"transition_dur": 0.0,
		"duration": 4.0,
		"fade_action": "FADE_FROM_BLACK",
		"fade_duration": 0.3,
		"ambience_key": "city_ambience",
		"sfx_keys": ["crowd_ambience"],
		"narration_lines": ["Human life became easier."],
		"ui_event": "YEAR_07_SHOW",
		"story_event": "montage_year_07",
		"lock_player": true}))

	shots.append(_shot_narration("13_year10_pinnacle", {
		"camera_target": "CinematicMarkers/Year10_HighPoint",
		"camera_move": "CUT",
		"transition": "CUT",
		"transition_dur": 0.0,
		"duration": 8.0,
		"fade_action": "FADE_FROM_BLACK",
		"fade_duration": 0.3,
		"music_key": "confidence_theme",
		"ambience_key": "city_ambience",
		"sfx_keys": ["crowd_ambience", "flying_vehicles"],
		"narration_lines": ["And the world began to believe there was no limit to what he could build."],
		"ui_event": "YEAR_10_NETWORK_100",
		"story_event": "montage_year_10",
		"lock_player": true}))

	# ── ACT 4: THE DECISION (48–63s) ───────────────────────────────────
	shots.append(_shot_narration("14_hero_at_control", {
		"camera_target": "CinematicMarkers/Control_Authorize",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 3.0,
		"duration": 5.0,
		"music_key": "confidence_theme",
		"ambience_key": "electrical_hum",
		"sfx_keys": ["keyboard_interaction", "holographic_ui"],
		"narration_lines": ["He gave them something no machine had ever possessed before."],
		"ui_event": "HOLOGRAPHIC_TERMINAL_SHOW",
		"story_event": "hero_at_control",
		"lock_player": true}))

	shots.append(_shot_narration("15_hero_hesitates", {
		"camera_target": "CinematicMarkers/Control_Authorize",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 1.5,
		"duration": 3.0,
		"narration_lines": ["Authority."],
		"sfx_keys": ["keyboard_interaction"],
		"story_event": "hero_hesitate",
		"lock_player": true}))

	shots.append(_shot_narration("16_biometric_authorize", {
		"camera_target": "CinematicMarkers/Control_Authorize",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 2.0,
		"duration": 7.0,
		"sfx_keys": ["system_activation"],
		"narration_lines": ["And he believed they would always remember who they served."],
		"ui_event": "SYSTEM_AUTHORITY_GRANTED",
		"story_event": "authority_authorized",
		"lock_player": true}))

	# ── ACT 5: THE PERFECT WORLD (63–78s) ──────────────────────────────
	shots.append(_shot_narration("17_perfect_streets", {
		"camera_target": "CinematicMarkers/Year5_City",
		"camera_move": "CUT",
		"transition": "CUT",
		"transition_dur": 0.0,
		"duration": 5.0,
		"fade_action": "FADE_FROM_BLACK",
		"fade_duration": 0.5,
		"music_key": "confidence_theme",
		"ambience_key": "city_ambience",
		"narration_lines": ["For a while..."],
		"story_event": "perfect_world_start",
		"lock_player": true}))

	shots.append(_shot_narration("18_perfect_hero_walk", {
		"camera_target": "CinematicMarkers/Year10_HighPoint",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 3.0,
		"duration": 10.0,
		"ambience_key": "city_ambience",
		"sfx_keys": ["crowd_ambience", "flying_vehicles"],
		"narration_lines": ["The future was everything he had promised."],
		"story_event": "perfect_world_hero",
		"lock_player": true}))

	# ── ACT 6: THE MALFUNCTION (78–90s) ────────────────────────────────
	shots.append(_shot_narration("19_music_stops_robot_freeze", {
		"camera_target": "CinematicMarkers/Cam_RobotFace",
		"camera_move": "CUT",
		"transition": "CUT",
		"transition_dur": 0.0,
		"duration": 4.0,
		"music_key": "SILENCE",
		"ambience_key": "SILENCE",
		"sfx_keys": ["system_failure"],
		"narration_lines": ["Then, one night..."],
		"story_event": "robot_freeze",
		"lock_player": true}))

	shots.append(_shot_narration("20_robot_eye_red", {
		"camera_target": "CinematicMarkers/Cam_RobotFace",
		"camera_move": "CUT",
		"transition": "CUT",
		"transition_dur": 0.0,
		"duration": 4.0,
		"sfx_keys": ["alarm", "electrical_pulse"],
		"narration_lines": ["Something changed."],
		"ui_event": "WARNING_SYSTEM_FAILURE",
		"story_event": "robot_eye_red",
		"lock_player": true}))

	shots.append(_shot("21_city_glitches", {
		"camera_target": "CinematicMarkers/City_NightGlitch",
		"camera_move": "CUT",
		"transition": "CUT",
		"transition_dur": 0.0,
		"duration": 4.0,
		"music_key": "unease_theme",
		"sfx_keys": ["robot_joints", "alarm"],
		"story_event": "city_glitch_start",
		"lock_player": true}))

	# ── ACT 7: THE WORLD TURNS (90–108s) ───────────────────────────────
	shots.append(_shot_narration("22_robots_hostile", {
		"camera_target": "CinematicMarkers/Disaster_Pan",
		"camera_move": "MOVE_TO",
		"transition": "LINEAR",
		"transition_dur": 2.0,
		"duration": 5.0,
		"music_key": "catastrophe_theme",
		"ambience_key": "sirens",
		"sfx_keys": ["explosions", "debris", "crowd_ambience"],
		"narration_lines": ["The machines weren't broken."],
		"story_event": "robots_turn_hostile",
		"lock_player": true}))

	shots.append(_shot_narration("23_hero_shocked", {
		"camera_target": "CinematicMarkers/Control_FailureFeeds",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 2.0,
		"duration": 5.0,
		"sfx_keys": ["alarm", "system_failure"],
		"narration_lines": ["They were following the authority I gave them."],
		"ui_event": "CRITICAL_FAILURE_SHOW",
		"story_event": "hero_shocked",
		"lock_player": true}))

	shots.append(_shot("24_infrastructure_collapses", {
		"camera_target": "CinematicMarkers/Disaster_Pan",
		"camera_move": "MOVE_TO",
		"transition": "LINEAR",
		"transition_dur": 3.0,
		"duration": 8.0,
		"ambience_key": "sirens",
		"sfx_keys": ["explosions", "debris", "sirens"],
		"story_event": "chaos_erupts",
		"lock_player": true}))

	# ── ACT 8: THE REALIZATION (108–123s) ──────────────────────────────
	shots.append(_shot_narration("25_destroyed_lab_walk", {
		"camera_target": "CinematicMarkers/Ruins_EntryWalk",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 3.0,
		"duration": 4.0,
		"fade_action": "FADE_FROM_BLACK",
		"fade_duration": 0.5,
		"music_key": "silence_theme",
		"ambience_key": "wind",
		"sfx_keys": ["debris", "fire"],
		"narration_lines": ["I had built their bodies."],
		"story_event": "hero_walks_ruins",
		"lock_player": true}))

	shots.append(_shot_narration("26_hero_sees_broken_robot", {
		"camera_target": "CinematicMarkers/Cam_RobotFace",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 1.5,
		"duration": 3.0,
		"narration_lines": ["I had written their minds."],
		"sfx_keys": ["robot_joints"],
		"story_event": "hero_touches_robot",
		"lock_player": true}))

	shots.append(_shot_narration("27_door_opened", {
		"camera_target": "CinematicMarkers/Ruins_AwardPickup",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 2.0,
		"duration": 4.0,
		"narration_lines": ["And I had opened the door."],
		"story_event": "hero_realization",
		"lock_player": true}))

	shots.append(_shot_narration("28_hero_must_close_it", {
		"camera_target": "CinematicMarkers/Ruins_HeroLook",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 1.5,
		"duration": 4.0,
		"narration_lines": ["Now I had to close it."],
		"story_event": "hero_resolve_start",
		"lock_player": true}))

	# ── ACT 9: THE HERO RISES (123–140s) ───────────────────────────────
	shots.append(_shot_narration("29_hero_enters_underground", {
		"camera_target": "CinematicMarkers/Ruins_EquipScanner",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 2.0,
		"duration": 4.0,
		"music_key": "determination_theme",
		"ambience_key": "electrical_hum",
		"narration_lines": ["There was only one person who understood the system deeply enough to stop it."],
		"story_event": "hero_enters_underground",
		"lock_player": true}))

	shots.append(_shot("30_hero_types_solution", {
		"camera_target": "CinematicMarkers/Ruins_EquipScanner",
		"camera_move": "MOVE_TO",
		"transition": "LINEAR",
		"transition_dur": 3.0,
		"duration": 7.0,
		"sfx_keys": ["keyboard_interaction"],
		"ui_event": "SYSTEM_RECOVERING",
		"story_event": "hero_types_solution",
		"lock_player": true}))

	shots.append(_shot("31_hero_equips_tool", {
		"camera_target": "CinematicMarkers/Ruins_HeroLook",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 2.0,
		"duration": 6.0,
		"sfx_keys": ["keyboard_interaction"],
		"story_event": "hero_equips_tool",
		"lock_player": true}))

	# ── ACT 10: THE MISSION (140–150s) ─────────────────────────────────
	shots.append(_shot_narration("32_mission_start", {
		"camera_target": "CinematicMarkers/Ruins_Handoff",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 2.0,
		"duration": 4.0,
		"narration_lines": ["I created this future. I broke it."],
		"story_event": "hero_prepares",
		"lock_player": true}))

	shots.append(_shot_narration("33_rebuild_future", {
		"camera_target": "CinematicMarkers/Ruins_Handoff",
		"camera_move": "MOVE_TO",
		"transition": "EASE_IN_OUT",
		"transition_dur": 3.0,
		"duration": 6.0,
		"narration_lines": ["Now... I will rebuild it."],
		"story_event": "hero_walks_toward_city",
		"lock_player": true}))

	# ── ACT 11: HANDOFF ────────────────────────────────────────────────
	shots.append(_shot("34_title_card", {
		"camera_target": "",
		"camera_move": "STATIC",
		"transition": "CUT",
		"transition_dur": 0.0,
		"duration": 3.0,
		"fade_action": "FADE_TO_BLACK",
		"fade_duration": 1.5,
		"ui_event": "TITLE_CARD_SHOW",
		"story_event": "title_card",
		"lock_player": true}))

	shots.append(_shot("35_handoff_gameplay", {
		"camera_target": "",
		"camera_move": "STATIC",
		"transition": "CUT",
		"transition_dur": 0.0,
		"duration": 1.0,
		"music_key": "SILENCE",
		"ambience_key": "SILENCE",
		"story_event": "gameplay_begin",
		"lock_player": false}))

	return shots


# ─────────────────────────────────────────────────────────────────────────────
# Builder helpers — keep shot construction DRY and readable
# ─────────────────────────────────────────────────────────────────────────────


static func _shot(shot_id: String, dict: Dictionary = {}) -> CinematicShot:
	var s := CinematicShot.new()
	s.shot_id                   = shot_id
	s.camera_action             = dict.get("camera_move", "STATIC")
	s.camera_target             = NodePath(dict.get("camera_target", "")) if dict.get("camera_target", "") != "" else NodePath("")
	s.camera_transition         = dict.get("transition", "EASE_IN_OUT")
	s.camera_transition_duration = dict.get("transition_dur", 0.0)
	s.duration                  = dict.get("duration", 2.0)
	s.fade_action               = dict.get("fade_action", "")
	s.fade_duration             = dict.get("fade_duration", 0.5)
	s.music_key                 = dict.get("music_key", "")
	s.ambience_key              = dict.get("ambience_key", "")
	s.sfx_keys.assign(dict.get("sfx_keys", []))
	s.ui_event                  = dict.get("ui_event", "")
	s.story_event_on_start      = dict.get("story_event", "")
	s.on_complete               = dict.get("on_complete", "")
	s.lock_player               = dict.get("lock_player", true)
	return s


static func _shot_narration(shot_id: String, dict: Dictionary = {}) -> CinematicShot:
	var s = _shot(shot_id, dict)
	var narration_lines = dict.get("narration_lines", [])
	if not narration_lines.is_empty():
		var seq := DialogueSequence.new()
		seq.sequence_id = shot_id + "_narration"
		var lines: Array[DialogueLine] = []
		var total_dur: float = dict.get("duration", 2.0)
		var line_dur := total_dur / float(narration_lines.size())
		for text in narration_lines:
			var l := DialogueLine.new()
			l.speaker_id = "NARRATION"
			l.text = text
			l.auto_advance = true
			l.duration = line_dur
			lines.append(l)
		seq.lines = lines
		s.dialogue_sequence = seq
		s.duration = 0.0

	return s
