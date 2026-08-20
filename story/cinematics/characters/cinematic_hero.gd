extends Node3D

class_name CinematicHero

# Animation states matching the requested spec
enum State {
	IDLE,
	WALK,
	RUN,
	WORK,
	LOOK,
	INTERACT,
	REACT,
	HEROIC_STANCE
}

@export var current_state: State = State.IDLE

@onready var anim_player: AnimationPlayer = $HeroModel/AnimationPlayer
@onready var skeleton: Skeleton3D = $HeroModel/Skeleton3D

func _ready() -> void:
	# Start with the idle state
	play_state(current_state)

func play_state(state: State, custom_blend_time: float = 0.3) -> void:
	current_state = state
	var anim_name = get_state_name(state)
	
	if anim_player:
		if anim_player.has_animation(anim_name):
			anim_player.play(anim_name, custom_blend_time)
		else:
			# Fallback to lowercase or uppercase
			var fallback_name = anim_name.to_lower()
			if anim_player.has_animation(fallback_name):
				anim_player.play(fallback_name, custom_blend_time)
			else:
				push_warning("Animation state not found: " + anim_name)
	else:
		push_error("AnimationPlayer not found on CinematicHero!")

func get_state_name(state: State) -> String:
	match state:
		State.IDLE: return "IDLE"
		State.WALK: return "WALK"
		State.RUN: return "RUN"
		State.WORK: return "WORK"
		State.LOOK: return "LOOK"
		State.INTERACT: return "INTERACT"
		State.REACT: return "REACT"
		State.HEROIC_STANCE: return "HEROIC_STANCE"
	return "IDLE"

# Helper for external triggers (e.g. from cinematic track)
func play_animation(anim_name: String, blend_time: float = 0.3) -> void:
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name, blend_time)
	else:
		push_warning("Requested animation not found: " + anim_name)

# Procedural head tracking (secondary motion) toward a target position
func look_at_target(target_pos: Vector3, weight: float = 0.8) -> void:
	if not skeleton:
		return
	
	var neck_bone = skeleton.find_bone("mixamorig7_Neck")
	var head_bone = skeleton.find_bone("mixamorig7_Head")
	
	if neck_bone == -1 or head_bone == -1:
		return
		
	# Local look_at calculation
	var neck_global_pos = skeleton.to_global(skeleton.get_bone_global_pose(neck_bone).origin)
	var dir = (target_pos - neck_global_pos).normalized()
	
	# Project directional vector into skeleton local coordinates
	var local_dir = skeleton.global_transform.basis.inverse() * dir
	
	# Calculate pitch and yaw
	var yaw = atan2(-local_dir.x, -local_dir.z)
	var pitch = asin(local_dir.y)
	
	# Clamp to human neck limits
	yaw = clampf(yaw, -deg_to_rad(60), deg_to_rad(60))
	pitch = clampf(pitch, -deg_to_rad(30), deg_to_rad(30))
	
	# Apply pose override
	var current_neck_rot = skeleton.get_bone_pose_rotation(neck_bone)
	var target_neck_rot = Quaternion(Vector3.UP, yaw * 0.5) * Quaternion(Vector3.RIGHT, pitch * 0.5)
	skeleton.set_bone_pose_rotation(neck_bone, current_neck_rot.slerp(target_neck_rot, weight))
	
	var current_head_rot = skeleton.get_bone_pose_rotation(head_bone)
	var target_head_rot = Quaternion(Vector3.UP, yaw * 0.5) * Quaternion(Vector3.RIGHT, pitch * 0.5)
	skeleton.set_bone_pose_rotation(head_bone, current_head_rot.slerp(target_head_rot, weight))

# Reset procedural neck/head look overrides
func reset_look_at() -> void:
	if not skeleton:
		return
	var neck_bone = skeleton.find_bone("mixamorig7_Neck")
	var head_bone = skeleton.find_bone("mixamorig7_Head")
	if neck_bone != -1:
		skeleton.set_bone_pose_rotation(neck_bone, Quaternion.IDENTITY)
	if head_bone != -1:
		skeleton.set_bone_pose_rotation(head_bone, Quaternion.IDENTITY)
