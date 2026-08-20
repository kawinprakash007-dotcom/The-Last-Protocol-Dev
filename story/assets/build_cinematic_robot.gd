@tool
extends SceneTree

func _init() -> void:
	print("Starting Cinematic Robot Builder...")
	call_deferred("run_build")

func run_build() -> void:
	# 1. Load FBX Scene
	var fbx_path = "res://story/assets/characters/robot/Cyborg.fbx"
	var fbx_scene = load(fbx_path)
	if not fbx_scene:
		print("ERROR: Failed to load Cyborg FBX!")
		quit()
		return
		
	var fbx_inst = fbx_scene.instantiate()
	var raw_mesh_inst: MeshInstance3D = fbx_inst.find_child("Cyborg_Mesh", true, false)
	if not raw_mesh_inst:
		print("ERROR: Cyborg_Mesh not found!")
		quit()
		return
		
	var raw_mesh: ArrayMesh = raw_mesh_inst.mesh
	if not raw_mesh:
		print("ERROR: ArrayMesh is null!")
		quit()
		return
		
	# 2. Rig the mesh to a skinned mesh
	var new_mesh = ArrayMesh.new()
	var scale_factor = 0.16 # Scale down to ~1.8m height
	
	for surface_idx in range(raw_mesh.get_surface_count()):
		var arrays = raw_mesh.surface_get_arrays(surface_idx)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		
		var rotated_vertices = PackedVector3Array()
		var rotated_normals = PackedVector3Array()
		var bones_arr = PackedInt32Array()
		var weights_arr = PackedFloat32Array()
		
		for idx in range(vertices.size()):
			var v = vertices[idx]
			var n = normals[idx]
			
			# Rotate Z-up local to Y-up world and scale down
			var rv = Vector3(v.x, v.z, -v.y) * scale_factor
			var rn = Vector3(n.x, n.z, -n.y).normalized()
			
			rotated_vertices.append(rv)
			rotated_normals.append(rn)
			
			# Determine bone index based on coordinate heights
			# Height Y goes from 0.0 to 1.81m
			var bone_idx = 0
			if surface_idx == 1 or surface_idx == 2:
				bone_idx = 1 # Head visor and eyes
			else:
				# Surface 0 (body)
				if rv.y >= 1.568:
					bone_idx = 1 # Head
				elif rv.y >= 0.8:
					if rv.x < -0.08:
						bone_idx = 2 # LeftArm
					elif rv.x > 0.08:
						bone_idx = 3 # RightArm
					else:
						bone_idx = 0 # Torso
				else:
					if rv.x < 0.0:
						bone_idx = 4 # LeftLeg
					else:
						bone_idx = 5 # RightLeg
			
			bones_arr.append(bone_idx)
			bones_arr.append(0)
			bones_arr.append(0)
			bones_arr.append(0)
			
			weights_arr.append(1.0)
			weights_arr.append(0.0)
			weights_arr.append(0.0)
			weights_arr.append(0.0)
			
		arrays[Mesh.ARRAY_VERTEX] = rotated_vertices
		arrays[Mesh.ARRAY_NORMAL] = rotated_normals
		arrays[Mesh.ARRAY_BONES] = bones_arr
		arrays[Mesh.ARRAY_WEIGHTS] = weights_arr
		
		new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		print("Rigged surface ", surface_idx, " (vertices: ", vertices.size(), ")")
		
	# 3. Create Scene Root Node3D and set script
	var root = Node3D.new()
	root.name = "CinematicRobot"
	var script = load("res://story/cinematics/characters/cinematic_robot.gd")
	root.set_script(script)
	
	# 4. Create Skeleton3D and add bones
	var skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	root.add_child(skeleton)
	skeleton.owner = root
	
	# Add bones and set rest poses
	skeleton.add_bone("Torso")
	skeleton.set_bone_rest(0, Transform3D.IDENTITY)
	
	skeleton.add_bone("Head")
	skeleton.set_bone_parent(1, 0)
	skeleton.set_bone_rest(1, Transform3D(Basis(), Vector3(0.0, 1.568, 0.0)))
	
	skeleton.add_bone("LeftArm")
	skeleton.set_bone_parent(2, 0)
	skeleton.set_bone_rest(2, Transform3D(Basis(), Vector3(-0.096, 1.408, 0.0)))
	
	skeleton.add_bone("RightArm")
	skeleton.set_bone_parent(3, 0)
	skeleton.set_bone_rest(3, Transform3D(Basis(), Vector3(0.096, 1.408, 0.0)))
	
	skeleton.add_bone("LeftLeg")
	skeleton.set_bone_parent(4, 0)
	skeleton.set_bone_rest(4, Transform3D(Basis(), Vector3(-0.048, 0.72, 0.0)))
	
	skeleton.add_bone("RightLeg")
	skeleton.set_bone_parent(5, 0)
	skeleton.set_bone_rest(5, Transform3D(Basis(), Vector3(0.048, 0.72, 0.0)))
	
	# Set bone poses matching rest
	for i in range(skeleton.get_bone_count()):
		skeleton.set_bone_pose_position(i, skeleton.get_bone_rest(i).origin)
		skeleton.set_bone_pose_rotation(i, skeleton.get_bone_rest(i).basis.get_rotation_quaternion())
		
	# 5. Create Skin resource
	var skin = Skin.new()
	skin.set_bind_count(6)
	
	skin.set_bind_name(0, "Torso")
	skin.set_bind_pose(0, Transform3D.IDENTITY)
	
	skin.set_bind_name(1, "Head")
	skin.set_bind_pose(1, Transform3D(Basis(), Vector3(0.0, 1.568, 0.0)).inverse())
	
	skin.set_bind_name(2, "LeftArm")
	skin.set_bind_pose(2, Transform3D(Basis(), Vector3(-0.096, 1.408, 0.0)).inverse())
	
	skin.set_bind_name(3, "RightArm")
	skin.set_bind_pose(3, Transform3D(Basis(), Vector3(0.096, 1.408, 0.0)).inverse())
	
	skin.set_bind_name(4, "LeftLeg")
	skin.set_bind_pose(4, Transform3D(Basis(), Vector3(-0.048, 0.72, 0.0)).inverse())
	
	skin.set_bind_name(5, "RightLeg")
	skin.set_bind_pose(5, Transform3D(Basis(), Vector3(0.048, 0.72, 0.0)).inverse())
	
	# 6. Create MeshInstance3D skinned to skeleton
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "RobotMesh"
	mesh_inst.mesh = new_mesh
	mesh_inst.skeleton = NodePath("../Skeleton3D")
	mesh_inst.skin = skin
	
	# Set material overrides
	mesh_inst.set_surface_override_material(0, load("res://story/assets/materials/robot_body.tres"))
	mesh_inst.set_surface_override_material(1, load("res://story/assets/materials/robot_visor.tres"))
	mesh_inst.set_surface_override_material(2, load("res://story/assets/materials/robot_eyes.tres"))
	
	root.add_child(mesh_inst)
	mesh_inst.owner = root
	
	# 7. Create AnimationPlayer and library
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	root.add_child(anim_player)
	anim_player.owner = root
	
	var lib = AnimationLibrary.new()
	
	# Generate Animations
	create_idle_anim(lib)
	create_walk_anim(lib)
	create_turn_anim(lib)
	create_interact_anim(lib)
	create_activation_anim(lib)
	create_malfunction_anim(lib)
	create_hostile_anim(lib)
	
	anim_player.add_animation_library("", lib)
	
	# 8. Save PackedScene
	var packed = PackedScene.new()
	var err = packed.pack(root)
	if err == OK:
		ResourceSaver.save(packed, "res://story/cinematics/characters/cinematic_robot.tscn")
		print("SUCCESS: Saved res://story/cinematics/characters/cinematic_robot.tscn")
	else:
		print("ERROR: Failed to pack scene: ", err)
		
	quit()

# ── ANIMATION HELPERS ────────────────────────────────────────────────────────

func add_rot_track(anim: Animation, bone_name: String, times: PackedFloat32Array, rotations: Array) -> void:
	var track = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(track, NodePath("Skeleton3D:" + bone_name))
	for i in range(times.size()):
		anim.rotation_track_insert_key(track, times[i], rotations[i])

func add_pos_track(anim: Animation, bone_name: String, times: PackedFloat32Array, positions: Array) -> void:
	var track = anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(track, NodePath("Skeleton3D:" + bone_name))
	for i in range(times.size()):
		anim.position_track_insert_key(track, times[i], positions[i])

func create_idle_anim(lib: AnimationLibrary) -> void:
	var anim = Animation.new()
	anim.length = 2.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	var times = PackedFloat32Array([0.0, 1.0, 2.0])
	
	# Torso breathing
	var torso_pos = [
		Vector3(0.0, 0.0, 0.0),
		Vector3(0.0, 0.01, 0.0),
		Vector3(0.0, 0.0, 0.0)
	]
	add_pos_track(anim, "Torso", times, torso_pos)
	
	# Head tilt
	var head_rot = [
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-2)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(2)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-2))
	]
	add_rot_track(anim, "Head", times, head_rot)
	
	# Arms resting
	var l_arm_rot = [
		Quaternion.IDENTITY,
		Quaternion(Vector3(0, 0, 1), deg_to_rad(2)),
		Quaternion.IDENTITY
	]
	var r_arm_rot = [
		Quaternion.IDENTITY,
		Quaternion(Vector3(0, 0, 1), deg_to_rad(-2)),
		Quaternion.IDENTITY
	]
	add_rot_track(anim, "LeftArm", times, l_arm_rot)
	add_rot_track(anim, "RightArm", times, r_arm_rot)
	
	lib.add_animation("IDLE", anim)

func create_walk_anim(lib: AnimationLibrary) -> void:
	var anim = Animation.new()
	anim.length = 1.6
	anim.loop_mode = Animation.LOOP_LINEAR
	
	var walk_times = PackedFloat32Array([0.0, 0.4, 0.8, 1.2, 1.6])
	
	# Left Leg swings
	var l_leg_rot = [
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-15)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(0)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(15)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(0)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-15))
	]
	add_rot_track(anim, "LeftLeg", walk_times, l_leg_rot)
	
	# Right Leg swings
	var r_leg_rot = [
		Quaternion(Vector3(1, 0, 0), deg_to_rad(15)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(0)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-15)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(0)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(15))
	]
	add_rot_track(anim, "RightLeg", walk_times, r_leg_rot)
	
	# Left Arm swings
	var l_arm_walk = [
		Quaternion(Vector3(1, 0, 0), deg_to_rad(15)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(0)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-15)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(0)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(15))
	]
	add_rot_track(anim, "LeftArm", walk_times, l_arm_walk)
	
	# Right Arm swings
	var r_arm_walk = [
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-15)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(0)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(15)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(0)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-15))
	]
	add_rot_track(anim, "RightArm", walk_times, r_arm_walk)
	
	# Torso bounce
	var torso_walk = [
		Vector3(0, 0, 0),
		Vector3(0, -0.02, 0),
		Vector3(0, 0, 0),
		Vector3(0, -0.02, 0),
		Vector3(0, 0, 0)
	]
	add_pos_track(anim, "Torso", walk_times, torso_walk)
	
	lib.add_animation("WALK", anim)

func create_turn_anim(lib: AnimationLibrary) -> void:
	var anim = Animation.new()
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	var turn_times = PackedFloat32Array([0.0, 0.5, 1.0])
	var torso_turn = [
		Quaternion.IDENTITY,
		Quaternion(Vector3(0, 1, 0), deg_to_rad(10)),
		Quaternion.IDENTITY
	]
	add_rot_track(anim, "Torso", turn_times, torso_turn)
	
	var l_leg_turn = [
		Quaternion.IDENTITY,
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-5)),
		Quaternion.IDENTITY
	]
	var r_leg_turn = [
		Quaternion.IDENTITY,
		Quaternion(Vector3(1, 0, 0), deg_to_rad(5)),
		Quaternion.IDENTITY
	]
	add_rot_track(anim, "LeftLeg", turn_times, l_leg_turn)
	add_rot_track(anim, "RightLeg", turn_times, r_leg_turn)
	
	lib.add_animation("TURN", anim)

func create_interact_anim(lib: AnimationLibrary) -> void:
	var anim = Animation.new()
	anim.length = 2.0
	
	var int_times = PackedFloat32Array([0.0, 0.6, 1.4, 2.0])
	var r_arm_int = [
		Quaternion.IDENTITY,
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-70)) * Quaternion(Vector3(0, 0, 1), deg_to_rad(15)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-70)) * Quaternion(Vector3(0, 0, 1), deg_to_rad(15)),
		Quaternion.IDENTITY
	]
	add_rot_track(anim, "RightArm", int_times, r_arm_int)
	
	var head_int = [
		Quaternion.IDENTITY,
		Quaternion(Vector3(1, 0, 0), deg_to_rad(10)) * Quaternion(Vector3(0, 1, 0), deg_to_rad(-10)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(10)) * Quaternion(Vector3(0, 1, 0), deg_to_rad(-10)),
		Quaternion.IDENTITY
	]
	add_rot_track(anim, "Head", int_times, head_int)
	
	lib.add_animation("INTERACT", anim)

func create_activation_anim(lib: AnimationLibrary) -> void:
	var anim = Animation.new()
	anim.length = 6.0
	
	# Torso stand up
	var act_torso_times = PackedFloat32Array([0.0, 3.5, 5.0, 6.0])
	var act_torso_pos = [
		Vector3(0, -0.15, 0),
		Vector3(0, -0.15, 0),
		Vector3(0, 0, 0),
		Vector3(0, 0, 0)
	]
	add_pos_track(anim, "Torso", act_torso_times, act_torso_pos)
	
	# Head lift
	var act_head_times = PackedFloat32Array([0.0, 2.0, 3.5, 6.0])
	var act_head_rot = [
		Quaternion(Vector3(1, 0, 0), deg_to_rad(35)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(35)),
		Quaternion.IDENTITY,
		Quaternion.IDENTITY
	]
	add_rot_track(anim, "Head", act_head_times, act_head_rot)
	
	# Eye emission flicker
	var em_track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(em_track, NodePath("RobotMesh:surface_material_override/2:emission_energy_multiplier"))
	
	var em_keys = {
		0.0: 0.0,
		2.0: 0.0,
		2.1: 1.5,
		2.2: 0.2,
		2.3: 2.0,
		2.4: 0.5,
		2.5: 3.0,
		6.0: 3.0
	}
	for t in em_keys:
		anim.track_insert_key(em_track, t, em_keys[t])
		
	# Limp arms stabilizing
	var act_arm_times = PackedFloat32Array([0.0, 4.0, 5.5, 6.0])
	var l_arm_act = [
		Quaternion(Vector3(1, 0, 0), deg_to_rad(15)) * Quaternion(Vector3(0, 0, 1), deg_to_rad(-10)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(15)) * Quaternion(Vector3(0, 0, 1), deg_to_rad(-10)),
		Quaternion.IDENTITY,
		Quaternion.IDENTITY
	]
	var r_arm_act = [
		Quaternion(Vector3(1, 0, 0), deg_to_rad(15)) * Quaternion(Vector3(0, 0, 1), deg_to_rad(10)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(15)) * Quaternion(Vector3(0, 0, 1), deg_to_rad(10)),
		Quaternion.IDENTITY,
		Quaternion.IDENTITY
	]
	add_rot_track(anim, "LeftArm", act_arm_times, l_arm_act)
	add_rot_track(anim, "RightArm", act_arm_times, r_arm_act)
	
	lib.add_animation("ACTIVATION", anim)

func create_malfunction_anim(lib: AnimationLibrary) -> void:
	var anim = Animation.new()
	anim.length = 1.5
	anim.loop_mode = Animation.LOOP_LINEAR
	
	var mal_times = PackedFloat32Array([0.0, 0.15, 0.3, 0.45, 0.6, 0.75, 0.9, 1.05, 1.2, 1.35, 1.5])
	
	# Head twitching
	var head_mal = []
	for i in range(11):
		head_mal.append(Quaternion(Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)).normalized(), deg_to_rad(randf_range(5, 20))))
	add_rot_track(anim, "Head", mal_times, head_mal)
	
	# Torso twitching
	var torso_mal = []
	for i in range(11):
		torso_mal.append(Vector3(randf_range(-0.02, 0.02), randf_range(-0.02, 0.02), randf_range(-0.02, 0.02)))
	add_pos_track(anim, "Torso", mal_times, torso_mal)
	
	# Eye flickering
	var em_track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(em_track, NodePath("RobotMesh:surface_material_override/2:emission_energy_multiplier"))
	for i in range(11):
		anim.track_insert_key(em_track, mal_times[i], randf_range(0.2, 3.5))
		
	# Limp arms twitching
	var l_arm_mal = []
	var r_arm_mal = []
	for i in range(11):
		l_arm_mal.append(Quaternion(Vector3(0, 0, 1), deg_to_rad(randf_range(-20, -5))))
		r_arm_mal.append(Quaternion(Vector3(0, 0, 1), deg_to_rad(randf_range(5, 20))))
	add_rot_track(anim, "LeftArm", mal_times, l_arm_mal)
	add_rot_track(anim, "RightArm", mal_times, r_arm_mal)
	
	lib.add_animation("MALFUNCTION", anim)

func create_hostile_anim(lib: AnimationLibrary) -> void:
	var anim = Animation.new()
	anim.length = 2.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	var host_times = PackedFloat32Array([0.0, 1.0, 2.0])
	
	# Torso crouched
	var host_torso_pos = [
		Vector3(0, -0.05, 0.02),
		Vector3(0, -0.07, 0.02),
		Vector3(0, -0.05, 0.02)
	]
	var host_torso_rot = [
		Quaternion(Vector3(1, 0, 0), deg_to_rad(12)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(14)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(12))
	]
	add_pos_track(anim, "Torso", host_times, host_torso_pos)
	add_rot_track(anim, "Torso", host_times, host_torso_rot)
	
	# Head tilt
	var host_head_rot = [
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-8)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-6)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-8))
	]
	add_rot_track(anim, "Head", host_times, host_head_rot)
	
	# Arms raised aggressively
	var l_arm_host = [
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-45)) * Quaternion(Vector3(0, 1, 0), deg_to_rad(-20)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-40)) * Quaternion(Vector3(0, 1, 0), deg_to_rad(-20)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-45)) * Quaternion(Vector3(0, 1, 0), deg_to_rad(-20))
	]
	var r_arm_host = [
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-45)) * Quaternion(Vector3(0, 1, 0), deg_to_rad(20)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-40)) * Quaternion(Vector3(0, 1, 0), deg_to_rad(20)),
		Quaternion(Vector3(1, 0, 0), deg_to_rad(-45)) * Quaternion(Vector3(0, 1, 0), deg_to_rad(20))
	]
	add_rot_track(anim, "LeftArm", host_times, l_arm_host)
	add_rot_track(anim, "RightArm", host_times, r_arm_host)
	
	# Keep eyes glowing
	var em_track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(em_track, NodePath("RobotMesh:surface_material_override/2:emission_energy_multiplier"))
	anim.track_insert_key(em_track, 0.0, 3.5)
	anim.track_insert_key(em_track, 2.0, 3.5)
	
	lib.add_animation("HOSTILE_MOVEMENT", anim)
