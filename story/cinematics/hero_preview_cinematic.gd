extends Node3D

## Entrance and workstation locations
const ENTRANCE_POS := Vector3(-4.5, 0.0, 4.0)
const WORKSTATION_POS := Vector3(-0.5, 0.0, 0.5)
const CONSOLE_POS := Vector3(-0.5, 1.1, -0.5)
const ROBOT_POS := Vector3(2.5, 0.8, -1.5)

## Animation state constants mapped from CinematicHero.State
const HERO_IDLE = 0
const HERO_WALK = 1
const HERO_RUN = 2
const HERO_WORK = 3
const HERO_LOOK = 4
const HERO_INTERACT = 5
const HERO_REACT = 6
const HERO_HEROIC_STANCE = 7

@onready var hero: Node3D = $CinematicHero
@onready var fade: CinematicFade = $CinematicFade
@onready var camera_controller: CinematicCameraController = $CinematicCameraController

# Dynamic autoload resolution to allow compile-clean tool scene generation
@onready var _event_bus: Node = get_node("/root/EventBus")
@onready var _cinematic_manager: Node = get_node("/root/CinematicManager")

var _tween: Tween

func _ready() -> void:
	print("HeroPreviewCinematic: _ready() starting...")
	# Hide any UI overlays or fade-in
	if fade != null:
		fade.fade_from_black(1.0)
		
	# Wire story events
	if _event_bus != null:
		_event_bus.story_event_triggered.connect(_on_story_event_triggered)
		_event_bus.cinematic_finished.connect(_on_cinematic_finished)
	else:
		push_error("HeroPreviewCinematic: EventBus autoload not found!")
	
	# Position hero at entrance initially
	if hero != null:
		hero.global_position = ENTRANCE_POS
		# Face towards workstation
		hero.look_at(WORKSTATION_POS, Vector3.UP)
		hero.rotate_y(PI) # Mixamo model faces Z-forward usually, adjust if needed
		if hero.has_method("play_state"):
			hero.play_state(HERO_IDLE)
		
	# Build and play the cinematic sequence
	var sequence = build_preview_sequence()
	if _cinematic_manager != null:
		print("HeroPreviewCinematic: Playing cinematic sequence...")
		_cinematic_manager.call_deferred("play_sequence", sequence)
	else:
		push_error("HeroPreviewCinematic: CinematicManager autoload not found!")

func build_preview_sequence() -> CinematicSequence:
	var seq = CinematicSequence.new()
	seq.sequence_id = "hero_preview"
	
	# Shot 1: Hero enters laboratory
	var shot1 = CinematicShot.new()
	shot1.shot_id = "shot_01_entrance"
	shot1.duration = 3.0
	shot1.camera_action = "CUT"
	shot1.camera_target = "Environment/CameraMarkers/MarkerEntrance"
	shot1.look_target = "CinematicHero"
	shot1.story_event_on_start = "preview_hero_enter"
	seq.shots.append(shot1)
	
	# Shot 2: Walk toward workstation
	var shot2 = CinematicShot.new()
	shot2.shot_id = "shot_02_walk_to_desk"
	shot2.duration = 4.0
	shot2.camera_action = "MOVE_AND_LOOK"
	shot2.camera_target = "Environment/CameraMarkers/MarkerDeskWide"
	shot2.look_target = "CinematicHero"
	shot2.camera_transition = "LINEAR"
	shot2.camera_transition_duration = 3.5
	shot2.story_event_on_start = "preview_hero_walk_to_desk"
	seq.shots.append(shot2)
	
	# Shot 3: Arrives, looks at holographic interface
	var shot3 = CinematicShot.new()
	shot3.shot_id = "shot_03_workstation_work"
	shot3.duration = 4.0
	shot3.camera_action = "CUT"
	shot3.camera_target = "Environment/CameraMarkers/MarkerDeskMCU"
	shot3.look_target = "CinematicHero"
	shot3.story_event_on_start = "preview_hero_work"
	seq.shots.append(shot3)
	
	# Shot 4: Interacts with technology
	var shot4 = CinematicShot.new()
	shot4.shot_id = "shot_04_workstation_interact"
	shot4.duration = 3.0
	shot4.camera_action = "STATIC"
	shot4.camera_target = "Environment/CameraMarkers/MarkerDeskCU"
	shot4.look_target = "Environment/WorkstationConsole/Screen"
	shot4.story_event_on_start = "preview_hero_interact"
	seq.shots.append(shot4)
	
	# Shot 5: Looks toward robot prototype
	var shot5 = CinematicShot.new()
	shot5.shot_id = "shot_05_look_at_robot"
	shot5.duration = 4.0
	shot5.camera_action = "MOVE_AND_LOOK"
	shot5.camera_target = "Environment/CameraMarkers/MarkerRobotView"
	shot5.look_target = "Environment/RobotPrototype"
	shot5.camera_transition = "EASE_IN_OUT"
	shot5.camera_transition_duration = 3.0
	shot5.story_event_on_start = "preview_hero_look_robot"
	seq.shots.append(shot5)
	
	# Shot 6: Heroic stance
	var shot6 = CinematicShot.new()
	shot6.shot_id = "shot_06_heroic_stance"
	shot6.duration = 4.0
	shot6.camera_action = "CUT"
	shot6.camera_target = "Environment/CameraMarkers/MarkerHeroic"
	shot6.look_target = "CinematicHero"
	shot6.story_event_on_start = "preview_hero_stance"
	seq.shots.append(shot6)
	
	return seq

func _process(_delta: float) -> void:
	# Keep updating secondary looking motion based on state
	if hero != null and hero.get("skeleton") != null:
		var current_state = hero.get("current_state")
		if current_state == HERO_WORK:
			if hero.has_method("look_at_target"):
				hero.look_at_target(CONSOLE_POS, 0.1)
		elif current_state == HERO_LOOK:
			if hero.has_method("look_at_target"):
				hero.look_at_target(ROBOT_POS, 0.1)

func _on_story_event_triggered(event_id: String) -> void:
	print("Preview Event Triggered: ", event_id)
	if hero == null or not hero.has_method("play_state"):
		return
		
	match event_id:
		"preview_hero_enter":
			hero.global_position = ENTRANCE_POS
			hero.look_at(WORKSTATION_POS, Vector3.UP)
			hero.rotate_y(PI)
			hero.play_state(HERO_WALK)
			
			# Tween walking motion to workstation
			_cancel_tween()
			_tween = create_tween()
			_tween.tween_property(hero, "global_position", WORKSTATION_POS, 6.0)
			_tween.finished.connect(func():
				if hero.get("current_state") == HERO_WALK:
					hero.play_state(HERO_IDLE)
					hero.look_at(CONSOLE_POS, Vector3.UP)
					hero.rotate_y(PI)
			)
			
		"preview_hero_walk_to_desk":
			# Let the walk continue slerping
			if hero.get("current_state") != HERO_WALK:
				hero.play_state(HERO_WALK)
				
		"preview_hero_work":
			# Stop walk tween, snap to desk and play WORK
			_cancel_tween()
			hero.global_position = WORKSTATION_POS
			hero.look_at(CONSOLE_POS, Vector3.UP)
			hero.rotate_y(PI)
			hero.play_state(HERO_WORK)
			
		"preview_hero_interact":
			hero.play_state(HERO_INTERACT)
			
		"preview_hero_look_robot":
			hero.play_state(HERO_LOOK)
			
		"preview_hero_stance":
			if hero.has_method("reset_look_at"):
				hero.reset_look_at()
			hero.play_state(HERO_HEROIC_STANCE)

func _on_cinematic_finished(sequence_id: String) -> void:
	if sequence_id == "hero_preview":
		print("Hero preview cinematic finished successfully.")
		# Loop the preview cinematic after a short delay
		await get_tree().create_timer(2.0).timeout
		if is_inside_tree() and _cinematic_manager != null:
			var sequence = build_preview_sequence()
			_cinematic_manager.play_sequence(sequence)

func _cancel_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
