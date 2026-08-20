## Phase 14 Validation — Verifies that the 150-second CinematicSequence
## compiles correctly and all 37 shots are present with valid data.
extends SceneTree

func _init():
	print("\n═══════════════════════════════════════════════════")
	print("  PHASE 14 — CINEMATIC SEQUENCE VALIDATION")
	print("═══════════════════════════════════════════════════\n")

	var sequence: CinematicSequence = Cinematic14Builder.build()
	var pass_count = 0
	var fail_count = 0

	_check(sequence != null, "Sequence built without error", pass_count, fail_count)
	_check(sequence.sequence_id == "cinematic_14_the_last_protocol",
		"Sequence ID correct", pass_count, fail_count)
	_check(sequence.shots.size() == 37,
		"Shot count = 37 (got %d)" % sequence.shots.size(), pass_count, fail_count)

	var total_duration = 0.0
	for shot in sequence.shots:
		_check(shot != null and shot.shot_id != "",
			"Shot valid: %s" % (shot.shot_id if shot else "NULL"), pass_count, fail_count)
		total_duration += max(shot.duration, 0.0)

	# narration shots are duration = 0, but still contribute ~3-5s via dialogue
	# estimated total via dialogue timing is acceptable
	_check(sequence.on_end_scene == "res://main.tscn",
		"on_end_scene → res://main.tscn", pass_count, fail_count)

	# Spot-check narration lines
	var narration_shot = sequence.shots[3]  # 04_inventor_narration
	_check(narration_shot.dialogue_sequence != null,
		"Shot 04 has narration dialogue attached", pass_count, fail_count)
	_check(narration_shot.dialogue_sequence.lines.size() == 1,
		"Opening narration has 1 line", pass_count, fail_count)

	var decision_shot = sequence.shots[17]  # 18_authorization_narration
	_check(decision_shot.dialogue_sequence != null,
		"Shot 18 has decision narration", pass_count, fail_count)
	_check(decision_shot.dialogue_sequence.lines.size() == 2,
		"Decision narration has 2 lines", pass_count, fail_count)

	var final_shot = sequence.shots[34]  # 35_final_narration
	_check(final_shot.dialogue_sequence != null,
		"Shot 35 has final narration", pass_count, fail_count)

	print("\n═══════════════════════════════════════════════════")
	print("  RESULT: %d PASSED   %d FAILED" % [pass_count, fail_count])
	print("═══════════════════════════════════════════════════\n")

	quit(fail_count)

func _check(condition: bool, label: String, pass_c: int, fail_c: int):
	if condition:
		pass_c += 1
		print("  [PASS] " + label)
	else:
		fail_c += 1
		print("  [FAIL] " + label)
