extends Node3D

enum State { OFF, BOOTING, IDLE, WALK, TURN, INTERACT, MALFUNCTION, HOSTILE }

@export var current_state: State = State.OFF
@export var look_at_target: Vector3 = Vector3.ZERO
@export var look_at_active: bool = false
@export var tracking_speed: float = 4.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var skeleton: Skeleton3D = $Skeleton3D
@onready var mesh_inst: MeshInstance3D = $RobotMesh

var _eye_material: StandardMaterial3D = null

func _ready() -> void:
	# Duplicate eye material to prevent writing back to disk resource
	if mesh_inst != null:
		var raw_mat = mesh_inst.get_surface_override_material(2)
		if raw_mat is StandardMaterial3D:
			_eye_material = raw_mat.duplicate()
			mesh_inst.set_surface_override_material(2, _eye_material)
			
	# Start in the OFF state by default
	play_state(current_state)

func play_state(new_state: State) -> void:
	current_state = new_state
	
	if anim_player == null:
		return
		
	# Manage material values based on states
	if _eye_material != null:
		if current_state == State.OFF:
			_eye_material.emission_energy_multiplier = 0.0
		elif current_state == State.HOSTILE or current_state == State.MALFUNCTION:
			# Threat mode: Red eyes
			_eye_material.emission = Color(1.0, 0.05, 0.05)
			_eye_material.emission_energy_multiplier = 4.0
		else:
			# Normal mode: Cyan eyes
			_eye_material.emission = Color(0, 0.9, 1.0)
			_eye_material.emission_energy_multiplier = 3.0
			
	# Trigger corresponding skeletal animations
	match current_state:
		State.OFF:
			anim_player.stop()
		State.BOOTING:
			anim_player.play("ACTIVATION", 0.2)
		State.IDLE:
			anim_player.play("IDLE", 0.5)
		State.WALK:
			anim_player.play("WALK", 0.5)
		State.TURN:
			anim_player.play("TURN", 0.3)
		State.INTERACT:
			anim_player.play("INTERACT", 0.3)
		State.MALFUNCTION:
			anim_player.play("MALFUNCTION", 0.2)
		State.HOSTILE:
			anim_player.play("HOSTILE_MOVEMENT", 0.4)

func _process(delta: float) -> void:
	# Handle procedural secondary neck tracking
	if skeleton == null or current_state == State.OFF:
		return
		
	var head_bone_idx = skeleton.find_bone("Head")
	if head_bone_idx == -1:
		return
		
	if look_at_active:
		# Calculate look target in skeleton space
		var global_head_pos = skeleton.global_transform * skeleton.get_bone_global_pose(head_bone_idx).origin
		var target_dir_world = (look_at_target - global_head_pos).normalized()
		
		# Transform direction to local bone space (relative to Torso parent rest basis)
		var parent_global_transform = skeleton.global_transform
		var local_target_dir = parent_global_transform.basis.inverse() * target_dir_world
		
		# Compute look target rotation around Y and X relative to default Z-forward
		var target_yaw = atan2(-local_target_dir.x, -local_target_dir.z)
		var target_pitch = asin(local_target_dir.y)
		
		# Limit angles for safety
		target_yaw = clamp(target_yaw, deg_to_rad(-60), deg_to_rad(60))
		target_pitch = clamp(target_pitch, deg_to_rad(-30), deg_to_rad(30))
		
		var target_rot = Quaternion(Vector3.UP, target_yaw) * Quaternion(Vector3.RIGHT, target_pitch)
		
		# Soft slerp interpolation
		var current_pose_rot = skeleton.get_bone_pose_rotation(head_bone_idx)
		var next_rot = current_pose_rot.slerp(target_rot, tracking_speed * delta)
		skeleton.set_bone_pose_rotation(head_bone_idx, next_rot)
	else:
		# Slerp back to rest orientation
		var current_pose_rot = skeleton.get_bone_pose_rotation(head_bone_idx)
		var rest_rot = skeleton.get_bone_rest(head_bone_idx).basis.get_rotation_quaternion()
		var next_rot = current_pose_rot.slerp(rest_rot, tracking_speed * delta)
		skeleton.set_bone_pose_rotation(head_bone_idx, next_rot)
