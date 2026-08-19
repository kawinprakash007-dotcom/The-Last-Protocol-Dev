extends CharacterBody3D
class_name AdvancedLocomotion

@export var animation_tree: AnimationTree
@export var blend_parameter_name: String = "parameters/BlendSpace1D/blend_position"

const WALK_SPEED = 2.5
const RUN_SPEED = 5.0

# Example simple state logic
func update_animation_state(delta: float):
	if not animation_tree:
		return
		
	var speed = velocity.length()
	var blend_target = 0.0 # Idle
	
	if speed > 0.1:
		blend_target = 0.5 # Walk
	if speed > WALK_SPEED + 0.5:
		blend_target = 1.0 # Run
		
	# Smoothly blend the current parameter towards the target
	var current_blend = animation_tree.get(blend_parameter_name)
	if current_blend != null:
		var new_blend = lerp(current_blend, blend_target, delta * 10.0)
		animation_tree.set(blend_parameter_name, new_blend)

func _physics_process(delta):
	# Movement logic is handled by existing gameplay scripts
	# This script purely listens to the velocity and updates the animation tree
	update_animation_state(delta)
