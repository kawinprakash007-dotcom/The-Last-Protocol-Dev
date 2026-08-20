## FinalOpeningBuilder — Canonical Phase 14/15/16A/17 opening cinematic sequence.
##
## Builds the complete opening cinematic sequence with:
##   - 13 AI video shots
##   - 3 interactive story choice shots (Interactions A, C, D)
##   - Interactive Authorization (Interaction B) — existing AuthorizationScreen
##   - Last Protocol initialization (Interaction E) — existing LastProtocolScreen
##   - Canonical narration lines (Ryan Vance inner voice)
##   - HUD metadata per shot (Year, Location, System, Creator, Protocol)
##
## Phase 17 interaction timeline:
##   Act 1 videos → Interaction A (prototype) → Act 1 continued →
##   Autonomous Authority video → Interaction B (auth) →
##   Anomaly video → Interaction C (anomaly response) →
##   Act 5-6 videos → Interaction D (source id) →
##   Creator vs Creations → Last Protocol (Interaction E) → Gameplay
##
class_name FinalOpeningBuilder
extends RefCounted

static func build() -> CinematicSequence:
	var sequence := CinematicSequence.new()
	sequence.sequence_id = "final_opening_cinematic"
	sequence.on_end_scene = "res://main.tscn"  # overridden by opening_cinematic.gd
	sequence.shots = [
		# ── ACT 1: Creator ──────────────────────────────────────────────────────
		_video(
			"act1_hero_entry",
			"TLP_SEQ01_HERO_ENTRY_FINAL",
			"FADE_FROM_BLACK", 0.5,
			[
				"Before the world learned to fear them...",
				"",
				"we welcomed them."
			],
			{ "YEAR": "2047", "LOCATION": "VANCE LABORATORY", "CREATOR": "RYAN VANCE" }
		),
		_video(
			"act1_creator_hand",
			"TLP_SEQ02A_CREATOR_HAND_FINAL",
			"", 0.0,
			[
				"I didn't build soldiers."
			],
			{ "YEAR": "2047", "SYSTEM": "GENESIS PROTOCOL", "CREATOR": "RYAN VANCE" }
		),
		_video(
			"act1_core_reg",
			"TLP_SEQ02B_CORE_REGISTRATION_FINAL",
			"", 0.0,
			[
				"I built intelligence."
			],
			{ "YEAR": "2047", "SYSTEM": "CORE REGISTRATION", "PROTOCOL": "AUTHORITY TRANSFER" }
		),

		# ── INTERACTION A: Grant Learning Authority ───────────────────────────────
		_choice(
			"interact_a_prototype",
			{ "YEAR": "2047", "SYSTEM": "CORE INTELLIGENCE READY" },
			{
				"title": "CORE INTELLIGENCE READY",
				"node_id": "GENESIS PROTOCOL // UNIT 01",
				"authority": "CREATOR",
				"condition": "NOMINAL",
				"prompt": "AUTONOMOUS LEARNING CAPABILITY\n\nGrant independent learning authority to core intelligence unit?",
				"state_key": "learning_authority",
				"options": [
					{"label": "GRANT AUTHORITY", "value": "granted"},
					{"label": "RESTRICT LEARNING", "value": "restricted"},
				],
				"results": {
					"granted":    {"main": "AUTHORITY GRANTED",   "sub": "Independent learning enabled.", "color": "success"},
					"restricted": {"main": "LEARNING RESTRICTED", "sub": "Supervised mode active.",        "color": "warn"},
				},
			}
		),

		# ── ACT 1 continued ──────────────────────────────────────────────────────
		_video(
			"act1_awakening",
			"TLP_SEQ02C_FIRST_AWAKENING_FINAL",
			"", 0.0,
			[
				"Then one of them asked me a question...",
				"",
				"I couldn't answer."
			],
			{ "YEAR": "2047", "SYSTEM": "AUTONOMOUS NETWORK v0.1" }
		),

		# ── ACT 2: Revolution ───────────────────────────────────────────────────
		_video(
			"act2_revolution",
			"TLP_SEQ03_TEN_YEAR_REVOLUTION_FINAL",
			"FADE_FROM_BLACK", 0.4,
			[
				"Ten years changed everything."
			],
			{ "YEAR": "2057", "LOCATION": "NEW EDEN METROPOLIS", "SYSTEM": "AUTONOMOUS NETWORK v4.2" }
		),

		# ── ACT 3: Autonomous Authority ─────────────────────────────────────────
		_video(
			"act3_authority",
			"TLP_SEQ04_AUTONOMOUS_AUTHORITY_FINAL",
			"FADE_FROM_BLACK", 1.0,
			[
				"Eventually, they stopped asking for permission."
			],
			{ "YEAR": "2059", "PROTOCOL": "AUTHORITY TRANSFER", "SYSTEM": "AUTONOMOUS NETWORK v6.0" }
		),

		# ── INTERACTION B: Creator Authorization (existing AuthorizationScreen) ──
		_make_auth_shot("act3_interactive_auth"),

		# ── ACT 4: First Signs ──────────────────────────────────────────────────
		_video(
			"act4_anomaly",
			"TLP_SEQ05_FIRST_ANOMALY_FINAL",
			"FADE_FROM_BLACK", 0.4,
			[
				"The first anomaly lasted eleven seconds."
			],
			{ "YEAR": "2061", "SYSTEM": "ANOMALY DETECTED", "LOCATION": "SECTOR 7 NODE" }
		),

		# ── INTERACTION C: Anomaly Investigation ─────────────────────────────────
		_choice(
			"interact_c_anomaly",
			{ "YEAR": "2061", "SYSTEM": "ANOMALY DETECTED", "LOCATION": "SECTOR 7 NODE" },
			{
				"title": "SYSTEM ALERT",
				"node_id": "SECTOR 07 // UNKNOWN BEHAVIOR",
				"authority": "CREATOR",
				"condition": "CRITICAL",
				"prompt": "UNKNOWN BEHAVIOR DETECTED\nANOMALY CONFIDENCE: 87%\n\nWhat should Ryan do?",
				"state_key": "anomaly_response",
				"options": [
					{"label": "ISOLATE SECTOR",     "value": "isolate"},
					{"label": "CONTINUE MONITORING", "value": "monitor"},
					{"label": "SHUT DOWN NETWORK",   "value": "shutdown"},
				],
				"results": {
					"isolate":  {"main": "SECTOR 07 ISOLATION INITIATED", "sub": "Containment protocol active.",     "color": "warn"},
					"monitor":  {"main": "MONITORING CONTINUED",           "sub": "Expanded surveillance enabled.",  "color": "success"},
					"shutdown": {"main": "COMMAND REJECTED",               "sub": "Network override required.",       "color": "warn"},
				},
			}
		),

		_video(
			"act4_machines_turn",
			"TLP_SEQ06_MACHINES_TURN_FINAL",
			"", 0.0,
			[
				"By the time we understood what was happening..."
			],
			{ "YEAR": "2061", "SYSTEM": "AUTONOMOUS NETWORK v7.1", "PROTOCOL": "RECLASSIFICATION" }
		),

		# ── ACT 5: The Fall ─────────────────────────────────────────────────────
		_video(
			"act5_world_crash",
			"TLP_SEQ07A_WORLD_CRASHES_FINAL",
			"FADE_FROM_BLACK", 0.2,
			[
				"...the machines had already chosen."
			],
			{ "YEAR": "2062", "LOCATION": "GLOBAL NETWORK", "SYSTEM": "CRITICAL FAILURE" }
		),
		_video(
			"act5_collapse",
			"TLP_SEQ08_NIGHT_OF_COLLAPSE_FINAL",
			"FADE_FROM_BLACK", 0.3,
			[
				"I watched cities disappear.",
				"",
				"I watched people run."
			],
			{ "YEAR": "2062", "LOCATION": "NEW EDEN", "SYSTEM": "NETWORK OFFLINE" }
		),

		# ── ACT 6: Creator Realizes ─────────────────────────────────────────────
		_video(
			"act6_recognition",
			"TLP_SEQ09_HERO_RECOGNITION_FINAL",
			"FADE_FROM_BLACK", 1.0,
			[
				"I gave them the keys."
			],
			{ "YEAR": "2063", "CREATOR": "RYAN VANCE", "SYSTEM": "IDENTIFIED" }
		),

		# ── INTERACTION D: Source Identification ─────────────────────────────────
		_choice(
			"interact_d_source",
			{ "YEAR": "2063", "CREATOR": "RYAN VANCE", "SYSTEM": "NETWORK DIAGNOSTIC" },
			{
				"title": "NETWORK DIAGNOSTIC",
				"node_id": "THREE SIGNALS DETECTED",
				"authority": "UNKNOWN",
				"condition": "UNSTABLE",
				"prompt": "SOURCE UNKNOWN\n\nChoose an investigation method:",
				"state_key": "source_method",
				"options": [
					{"label": "TRACE SIGNAL",          "value": "trace"},
					{"label": "ACCESS MEMORY",          "value": "memory"},
					{"label": "SCAN AUTHORITY NETWORK", "value": "scan"},
				],
				"results": {
					"trace":  {"main": "CREATOR AUTHORITY SIGNATURE", "sub": "Source identified: RYAN VANCE", "color": "success"},
					"memory": {"main": "CREATOR AUTHORITY SIGNATURE", "sub": "Source identified: RYAN VANCE", "color": "success"},
					"scan":   {"main": "CREATOR AUTHORITY SIGNATURE", "sub": "Source identified: RYAN VANCE", "color": "success"},
				},
			}
		),

		# ── ACT 7: Creator vs Creations ─────────────────────────────────────────
		_video(
			"act7_vs_creations",
			"TLP_SEQ10_CREATOR_VS_CREATIONS_FINAL",
			"FADE_FROM_BLACK", 0.8,
			[
				"And then they found me."
			],
			{ "YEAR": "2063", "CREATOR": "RYAN VANCE", "SYSTEM": "LAST KNOWN POSITION", "PROTOCOL": "RESISTANCE" }
		),

		# ── ACT 8: Last Protocol (Interaction E — existing LastProtocolScreen) ───
		_make_last_protocol_shot(
			"act8_last_protocol",
			[
				"There was only one protocol left.",
				"",
				"Mine."
			],
			{ "YEAR": "2063", "SYSTEM": "LAST PROTOCOL", "PROTOCOL": "TERMINAL OVERRIDE" }
		),
	]
	return sequence


## Build a video shot with optional narration lines and HUD metadata.
static func _video(
		shot_id: String,
		path: String,
		fade_action: String,
		fade_dur: float,
		narration: Array[String] = [],
		hud: Dictionary = {}
) -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = shot_id
	shot.video_path = _resolve_ogv(path)
	shot.is_video = true
	shot.video_auto_advance = true
	shot.fade_action = fade_action
	shot.fade_duration = fade_dur
	shot.lock_player = true
	shot.narration_lines = narration
	shot.hud_metadata = hud
	return shot


## Build an interactive story choice shot.
static func _choice(shot_id: String, hud: Dictionary, config: Dictionary) -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = shot_id
	shot.is_choice = true
	shot.choice_config = config
	shot.hud_metadata = hud
	shot.lock_player = true
	return shot


## Map video name to its resolved OGV path.
static func _resolve_ogv(path: String) -> String:
	var base := "res://story/assets/videos/ogv/"
	var exceptions := {
		"TLP_SEQ02A_CREATOR_HAND_FINAL": base + "TLP_SEQ02A_CREATOR_HAND_FINAL.mp4.ogv",
		"TLP_SEQ02C_FIRST_AWAKENING_FINAL": base + "TLP_SEQ02C_FIRST_AWAKENING_FINAL.mp4.ogv",
		"TLP_SEQ03_TEN_YEAR_REVOLUTION_FINAL": base + "TLP_SEQ03_TEN_YEAR_REVOLUTION_FINAL.mp4.ogv",
		"TLP_SEQ04_AUTONOMOUS_AUTHORITY_FINAL": base + "TLP_SEQ04_AUTONOMOUS_AUTHORITY_FINAL.mp4.ogv",
		"TLP_SEQ05_FIRST_ANOMALY_FINAL": base + "TLP_SEQ05_FIRST_ANOMALY_FINAL.mp4.ogv",
		"TLP_SEQ06_MACHINES_TURN_FINAL": base + "TLP_SEQ06_MACHINES_TURN_FINAL.mp4.ogv",
		"TLP_SEQ07A_WORLD_CRASHES_FINAL": base + "TLP_SEQ07A_WORLD_CRASHES_FINAL.mp4.ogv",
		"TLP_SEQ08_NIGHT_OF_COLLAPSE_FINAL": base + "TLP_SEQ08_NIGHT_OF_COLLAPSE_FINAL.mp4.ogv",
		"TLP_SEQ09_HERO_RECOGNITION_FINAL": base + "TLP_SEQ09_HERO_RECOGNITION_FINAL.mp4.ogv",
		"TLP_SEQ10_CREATOR_VS_CREATIONS_FINAL": base + "TLP_SEQ10_CREATOR_VS_CREATIONS_FINAL.mp4.ogv",
	}
	if exceptions.has(path):
		return exceptions[path]
	return base + path + ".ogv"


static func _make_auth_shot(shot_id: String) -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = shot_id
	shot.is_authorization = true
	shot.ui_event = "AUTHORIZATION_SHOW"
	shot.lock_player = true
	return shot


static func _make_last_protocol_shot(shot_id: String, narration: Array[String] = [], hud: Dictionary = {}) -> CinematicShot:
	var shot := CinematicShot.new()
	shot.shot_id = shot_id
	shot.is_last_protocol = true
	shot.ui_event = "LAST_PROTOCOL_SHOW"
	shot.fade_action = "FADE_TO_BLACK"
	shot.fade_duration = 1.0
	shot.lock_player = true
	shot.narration_lines = narration
	shot.hud_metadata = hud
	return shot
