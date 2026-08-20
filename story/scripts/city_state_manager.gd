@tool
extends Node3D

enum VisualState { CITY_DAY, CITY_NIGHT, CITY_COLLAPSE }
enum TemporalPhase { YEAR_1, YEAR_3, YEAR_5, YEAR_7, YEAR_10 }

@export var current_visual_state: VisualState = VisualState.CITY_DAY : set = set_visual_state
@export var current_temporal_phase: TemporalPhase = TemporalPhase.YEAR_1 : set = set_temporal_phase

@onready var main_light: DirectionalLight3D = $Environment/MainLight
@onready var environment: WorldEnvironment = $Environment/WorldEnvironment
@onready var collapse_particles: Node3D = $VFX/CollapseParticles
@onready var night_lights: Node3D = $Lighting/NightLights

@onready var group_advanced_tech: Node3D = $Infrastructure/AdvancedTech
@onready var group_flying_cars: Node3D = $Infrastructure/FlyingCars
@onready var group_holograms: Node3D = $Details/Holograms
@onready var group_robots: Node3D = $Infrastructure/Robots
@onready var group_construction: Node3D = $Infrastructure/Construction

func _ready():
	_apply_visual_state()
	_apply_temporal_phase()

func set_visual_state(value: VisualState):
	current_visual_state = value
	if is_inside_tree():
		_apply_visual_state()

func set_temporal_phase(value: TemporalPhase):
	current_temporal_phase = value
	if is_inside_tree():
		_apply_temporal_phase()

func _apply_visual_state():
	if not main_light: return
	
	match current_visual_state:
		VisualState.CITY_DAY:
			main_light.light_energy = 2.0
			main_light.light_color = Color(1.0, 0.95, 0.9)
			collapse_particles.visible = false
			night_lights.visible = false
			
		VisualState.CITY_NIGHT:
			main_light.light_energy = 0.1
			main_light.light_color = Color(0.1, 0.15, 0.3)
			collapse_particles.visible = false
			night_lights.visible = true
			
		VisualState.CITY_COLLAPSE:
			main_light.light_energy = 0.5
			main_light.light_color = Color(0.6, 0.2, 0.1)
			collapse_particles.visible = true
			night_lights.visible = false

func _apply_temporal_phase():
	if not group_advanced_tech: return
	
	group_advanced_tech.visible = false
	group_flying_cars.visible = false
	group_holograms.visible = false
	group_robots.visible = false
	group_construction.visible = false
	
	match current_temporal_phase:
		TemporalPhase.YEAR_1: # developing technology
			group_construction.visible = true
		TemporalPhase.YEAR_3: # automated infrastructure
			group_construction.visible = true
			group_advanced_tech.visible = true
		TemporalPhase.YEAR_5: # robots integrated into society
			group_advanced_tech.visible = true
			group_robots.visible = true
		TemporalPhase.YEAR_7: # advanced transportation
			group_advanced_tech.visible = true
			group_robots.visible = true
			group_flying_cars.visible = true
			group_holograms.visible = true
		TemporalPhase.YEAR_10: # fully automated civilization
			group_advanced_tech.visible = true
			group_robots.visible = true
			group_flying_cars.visible = true
			group_holograms.visible = true
