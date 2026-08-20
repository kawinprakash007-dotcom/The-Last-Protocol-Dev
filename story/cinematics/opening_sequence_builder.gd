## OpeningSequenceBuilder — Constructs the opening CinematicSequence.
##
## PHASE 9B — FIRST HALF CINEMATIC sequence: 8 shots (0:00–1:30)

class_name OpeningSequenceBuilder
extends RefCounted


static func build() -> CinematicSequence:
	var sequence := CinematicSequence.new()
	sequence.sequence_id = "opening_protocol"
	sequence.shots = [
		_shot_01_hero_working(),
		_shot_02_robot_construction(),
		_shot_03_cooperation(),
		_shot_04_year3(),
		_shot_05_year5(),
		_shot_06_year7(),
		_shot_07_year10(),
		_shot_08_authority(),
	]
	return sequence


# ── ACT SHOT BUILDERS ─────────────────────────────────────────────────────────

## SHOT 01 — HERO WORKING (0:00–0:10) — 10s
static func _shot_01_hero_working() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "01_hero_working"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Lab_HeroFocus"
	shot.camera_transition = "EASE_OUT"
	shot.camera_transition_duration = 10.0
	shot.duration = 10.0
	shot.lock_player = true
	shot.fade_action = "FADE_FROM_BLACK"
	shot.fade_duration = 2.0
	shot.music_key = "curiosity_theme"
	shot.ambience_key = "facility_hum"
	shot.story_event_on_start = "hero_intro_start"
	shot.dialogue_sequence = _dlg_01()
	return shot


## SHOT 02 — ROBOT CONSTRUCTION (0:10–0:22) — 12s
static func _shot_02_robot_construction() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "02_robot_construction"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Assembly_Close"
	shot.camera_transition = "EASE_IN_OUT"
	shot.camera_transition_duration = 12.0
	shot.duration = 12.0
	shot.lock_player = true
	shot.sfx_keys = ["welding_sparks", "steam_release"]
	shot.story_event_on_start = "assembly_weld_start"
	shot.dialogue_sequence = _dlg_02()
	return shot


## SHOT 03 — HUMAN-MACHINE COOPERATION (0:22–0:35) — 13s
static func _shot_03_cooperation() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "03_cooperation"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Lab_WalkTrack"
	shot.camera_transition = "EASE_OUT"
	shot.camera_transition_duration = 13.0
	shot.duration = 13.0
	shot.lock_player = true
	shot.story_event_on_start = "human_machine_start"
	shot.dialogue_sequence = _dlg_03()
	return shot


## SHOT 04 — YEAR 3 (0:35–0:48) — 13s
static func _shot_04_year3() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "04_year3"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Year3_Dolly"
	shot.camera_transition = "EASE_OUT"
	shot.camera_transition_duration = 13.0
	shot.duration = 13.0
	shot.lock_player = true
	shot.ui_event = "SHOW_YEAR3"
	shot.music_key = "growth_theme"
	shot.story_event_on_start = "year3_start"
	return shot


## SHOT 05 — YEAR 5 (0:48–1:00) — 12s
static func _shot_05_year5() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "05_year5"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Year5_City"
	shot.camera_transition = "EASE_IN_OUT"
	shot.camera_transition_duration = 12.0
	shot.duration = 12.0
	shot.lock_player = true
	shot.ui_event = "SHOW_YEAR5"
	shot.story_event_on_start = "year5_start"
	return shot


## SHOT 06 — YEAR 7 (1:00–1:12) — 12s
static func _shot_06_year7() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "06_year7"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Year7_Traffic"
	shot.camera_transition = "EASE_OUT"
	shot.camera_transition_duration = 12.0
	shot.duration = 12.0
	shot.lock_player = true
	shot.ui_event = "SHOW_YEAR7"
	shot.story_event_on_start = "year7_start"
	return shot


## SHOT 07 — YEAR 10 (1:12–1:22) — 10s
static func _shot_07_year10() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "07_year10"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Year10_HighPoint"
	shot.camera_transition = "EASE_IN_OUT"
	shot.camera_transition_duration = 10.0
	shot.duration = 10.0
	shot.lock_player = true
	shot.ui_event = "SHOW_YEAR10"
	shot.story_event_on_start = "year10_start"
	shot.dialogue_sequence = _dlg_07()
	return shot


## SHOT 08 — THE AUTHORITY (1:22–1:30) — 8s
static func _shot_08_authority() -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = "08_authority"
	shot.camera_action = "MOVE_TO"
	shot.camera_target = ^"CinematicMarkers/Control_Authorize"
	shot.camera_transition = "EASE_IN_OUT"
	shot.camera_transition_duration = 8.0
	shot.duration = 8.0
	shot.lock_player = false # Cut to black handoff transition
	shot.music_key = "decision_theme"
	shot.ui_event = "SHOW_AUTHORIZATION"
	shot.story_event_on_start = "authority_activate_start"
	return shot


# ── DIALOGUE BUILDERS ─────────────────────────────────────────────────────────

static func _dlg_01() -> DialogueSequence:
	var seq := DialogueSequence.new()
	seq.sequence_id = "dlg_01"
	seq.lines = [
		_line("NARRATION", "Ten years ago, the world was still waiting for its future."),
		_line("NARRATION", "He decided to build it."),
	]
	return seq


static func _dlg_02() -> DialogueSequence:
	var seq := DialogueSequence.new()
	seq.sequence_id = "dlg_02"
	seq.lines = [
		_line("NARRATION", "He didn't invent one machine."),
		_line("NARRATION", "He built a way forward."),
	]
	return seq


static func _dlg_03() -> DialogueSequence:
	var seq := DialogueSequence.new()
	seq.sequence_id = "dlg_03"
	seq.lines = [
		_line("NARRATION", "He gave humanity a world that could think for itself."),
	]
	return seq


static func _dlg_07() -> DialogueSequence:
	var seq := DialogueSequence.new()
	seq.sequence_id = "dlg_07"
	seq.lines = [
		_line("NARRATION", "He didn't simply invent machines."),
		_line("NARRATION", "He rebuilt civilization."),
	]
	return seq


# ── HELPERS ───────────────────────────────────────────────────────────────────

static func _line(speaker_id: String, text: String) -> DialogueLine:
	var line := DialogueLine.new()
	line.speaker_id = speaker_id
	line.text = text
	return line
