@tool
extends RefCounted

const VFX_PATH = "res://story/cinematics/vfx/"

func _run():
	print("Starting Procedural VFX Generator...")
	
	_create_spark_burst("SmallSparkBurst", 10, 0.5)
	_create_spark_burst("MediumSparkBurst", 30, 0.8)
	_create_spark_burst("HeavySparkBurst", 100, 1.2)
	
	_create_smoke("SmallSmoke", 0.5, 0.5)
	_create_smoke("MediumSmoke", 1.5, 1.5)
	_create_smoke("HeavySmoke", 3.0, 3.0)
	
	_create_steam("SteamVFX")
	_create_dust("DustVFX")
	_create_holographic("HolographicParticleVFX")
	_create_vehicle_trail("VehicleTrailVFX")
	_create_debris("DebrisVFX")
	
	_create_explosion("SmallExplosion", 0.5)
	_create_explosion("MediumExplosion", 1.0)
	_create_explosion("LargeExplosion", 2.0)
	
	_create_fire("FireVFX")
	_create_emergency_pulse("EmergencyPulseVFX")
	_create_energy_pulse("EnergyPulseVFX")
	
	_create_robot_activation("RobotActivationVFX")
	_create_electrical_arc("ElectricalArcVFX")
	
	print("VFX Generation Complete!")

func _save_scene(node: Node, filename: String):
	var packed = PackedScene.new()
	packed.pack(node)
	ResourceSaver.save(packed, VFX_PATH + filename + ".tscn")
	node.free()

func _create_spark_burst(name: String, amount: int, scale_factor: float):
	var root = GPUParticles3D.new()
	root.name = name
	root.amount = amount
	root.lifetime = 0.5 * scale_factor
	root.explosiveness = 0.95
	root.one_shot = true
	
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 90.0
	mat.initial_velocity_min = 3.0 * scale_factor
	mat.initial_velocity_max = 8.0 * scale_factor
	mat.gravity = Vector3(0, -9.8, 0)
	mat.damping_min = 2.0
	mat.damping_max = 5.0
	mat.scale_min = 0.05
	mat.scale_max = 0.1
	root.process_material = mat
	
	var pass1 = QuadMesh.new()
	var dmat = StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.albedo_color = Color(1.0, 0.8, 0.4)
	dmat.emission_enabled = true
	dmat.emission = Color(1.0, 0.8, 0.2)
	dmat.emission_energy_multiplier = 5.0
	pass1.material = dmat
	root.draw_pass_1 = pass1
	
	_save_scene(root, name)

func _create_smoke(name: String, scale_factor: float, lifetime: float):
	var root = GPUParticles3D.new()
	root.name = name
	root.amount = int(20 * scale_factor)
	root.lifetime = lifetime
	
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 20.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 2.0
	mat.gravity = Vector3(0, 0.5, 0) # Rising smoke
	
	var grad = Gradient.new()
	grad.add_point(0.0, Color(1, 1, 1, 0))
	grad.add_point(0.2, Color(0.3, 0.3, 0.3, 0.5))
	grad.add_point(0.8, Color(0.1, 0.1, 0.1, 0.3))
	grad.add_point(1.0, Color(0, 0, 0, 0))
	var gtex = GradientTexture1D.new()
	gtex.gradient = grad
	mat.color_ramp = gtex
	
	mat.scale_min = 0.5 * scale_factor
	mat.scale_max = 2.0 * scale_factor
	root.process_material = mat
	
	var pass1 = QuadMesh.new()
	var dmat = StandardMaterial3D.new()
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	dmat.albedo_color = Color(0.2, 0.2, 0.2)
	dmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	pass1.material = dmat
	root.draw_pass_1 = pass1
	
	_save_scene(root, name)

func _create_steam(name: String):
	var root = GPUParticles3D.new()
	root.name = name
	root.amount = 30
	root.lifetime = 2.0
	
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 15.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 4.0
	mat.gravity = Vector3(0, 0, 0)
	
	var grad = Gradient.new()
	grad.add_point(0.0, Color(1, 1, 1, 0))
	grad.add_point(0.2, Color(1, 1, 1, 0.3))
	grad.add_point(1.0, Color(1, 1, 1, 0))
	var gtex = GradientTexture1D.new()
	gtex.gradient = grad
	mat.color_ramp = gtex
	root.process_material = mat
	
	var pass1 = QuadMesh.new()
	var dmat = StandardMaterial3D.new()
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	pass1.material = dmat
	root.draw_pass_1 = pass1
	
	_save_scene(root, name)

func _create_dust(name: String):
	var root = GPUParticles3D.new()
	root.name = name
	root.amount = 100
	root.lifetime = 5.0
	
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(10, 5, 10)
	mat.gravity = Vector3(0, -0.1, 0)
	
	var grad = Gradient.new()
	grad.add_point(0.0, Color(1,1,1,0))
	grad.add_point(0.5, Color(1,1,1,0.1))
	grad.add_point(1.0, Color(1,1,1,0))
	var gtex = GradientTexture1D.new()
	gtex.gradient = grad
	mat.color_ramp = gtex
	root.process_material = mat
	
	var pass1 = QuadMesh.new()
	pass1.size = Vector2(0.05, 0.05)
	var dmat = StandardMaterial3D.new()
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	pass1.material = dmat
	root.draw_pass_1 = pass1
	
	_save_scene(root, name)

func _create_holographic(name: String):
	var root = GPUParticles3D.new()
	root.name = name
	root.amount = 50
	root.lifetime = 1.0
	
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(0.5, 1.0, 0.5)
	mat.gravity = Vector3(0, 1.0, 0)
	
	var grad = Gradient.new()
	grad.add_point(0.0, Color(0, 0.8, 1, 0))
	grad.add_point(0.5, Color(0, 0.8, 1, 0.8))
	grad.add_point(1.0, Color(0, 0.8, 1, 0))
	var gtex = GradientTexture1D.new()
	gtex.gradient = grad
	mat.color_ramp = gtex
	root.process_material = mat
	
	var pass1 = QuadMesh.new()
	pass1.size = Vector2(0.02, 0.1)
	var dmat = StandardMaterial3D.new()
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.emission_enabled = true
	dmat.emission = Color(0.0, 0.8, 1.0)
	dmat.emission_energy_multiplier = 2.0
	dmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	pass1.material = dmat
	root.draw_pass_1 = pass1
	
	_save_scene(root, name)

func _create_vehicle_trail(name: String):
	var root = GPUParticles3D.new()
	root.name = name
	root.amount = 30
	root.lifetime = 0.5
	
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 1)
	mat.spread = 5.0
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 10.0
	mat.gravity = Vector3(0, 0, 0)
	
	var grad = Gradient.new()
	grad.add_point(0.0, Color(0, 0.5, 1, 1))
	grad.add_point(1.0, Color(0, 0.1, 0.3, 0))
	var gtex = GradientTexture1D.new()
	gtex.gradient = grad
	mat.color_ramp = gtex
	
	var scale_curve = CurveTexture.new()
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	scale_curve.curve = curve
	mat.scale_curve = scale_curve
	root.process_material = mat
	
	var pass1 = QuadMesh.new()
	var dmat = StandardMaterial3D.new()
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.emission_enabled = true
	dmat.emission = Color(0, 0.5, 1)
	dmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	pass1.material = dmat
	root.draw_pass_1 = pass1
	
	_save_scene(root, name)

func _create_debris(name: String):
	var root = GPUParticles3D.new()
	root.name = name
	root.amount = 20
	root.lifetime = 2.0
	root.explosiveness = 0.9
	root.one_shot = true
	
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 10.0
	mat.gravity = Vector3(0, -9.8, 0)
	mat.scale_min = 0.1
	mat.scale_max = 0.5
	mat.angle_min = 0.0
	mat.angle_max = 360.0
	mat.angular_velocity_min = 50.0
	mat.angular_velocity_max = 150.0
	root.process_material = mat
	
	var pass1 = BoxMesh.new()
	var dmat = StandardMaterial3D.new()
	dmat.albedo_color = Color(0.3, 0.3, 0.3)
	pass1.material = dmat
	root.draw_pass_1 = pass1
	
	_save_scene(root, name)

func _create_explosion(name: String, scale: float):
	var root = Node3D.new()
	root.name = name
	
	var spark = GPUParticles3D.new()
	spark.name = "Sparks"
	var smat = ParticleProcessMaterial.new()
	smat.direction = Vector3(0, 1, 0)
	smat.spread = 180.0
	smat.initial_velocity_min = 10.0 * scale
	smat.initial_velocity_max = 20.0 * scale
	smat.gravity = Vector3(0, -9.8, 0)
	spark.process_material = smat
	spark.amount = 50
	spark.explosiveness = 1.0
	spark.one_shot = true
	spark.lifetime = 0.5
	var sq = QuadMesh.new()
	sq.size = Vector2(0.1, 0.1)
	var sdmat = StandardMaterial3D.new()
	sdmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sdmat.albedo_color = Color(1, 1, 0.5)
	sq.material = sdmat
	spark.draw_pass_1 = sq
	root.add_child(spark)
	spark.owner = root
	
	var smoke = GPUParticles3D.new()
	smoke.name = "Smoke"
	var smkmat = ParticleProcessMaterial.new()
	smkmat.direction = Vector3(0, 1, 0)
	smkmat.spread = 90.0
	smkmat.initial_velocity_min = 2.0 * scale
	smkmat.initial_velocity_max = 5.0 * scale
	smoke.process_material = smkmat
	smoke.amount = 30
	smoke.explosiveness = 0.8
	smoke.one_shot = true
	smoke.lifetime = 2.0
	var smq = QuadMesh.new()
	var smqdmat = StandardMaterial3D.new()
	smqdmat.albedo_color = Color(0.1, 0.1, 0.1, 0.5)
	smqdmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smqdmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	smq.material = smqdmat
	smoke.draw_pass_1 = smq
	root.add_child(smoke)
	smoke.owner = root
	
	_save_scene(root, name)

func _create_fire(name: String):
	var root = Node3D.new()
	root.name = name
	
	var flame = GPUParticles3D.new()
	flame.name = "Flames"
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 10.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 3.0
	mat.gravity = Vector3(0, 0, 0)
	var grad = Gradient.new()
	grad.add_point(0.0, Color(1, 1, 0, 1))
	grad.add_point(0.5, Color(1, 0.3, 0, 0.8))
	grad.add_point(1.0, Color(0, 0, 0, 0))
	var gtex = GradientTexture1D.new()
	gtex.gradient = grad
	mat.color_ramp = gtex
	flame.process_material = mat
	flame.amount = 20
	flame.lifetime = 1.0
	var fq = QuadMesh.new()
	var fdmat = StandardMaterial3D.new()
	fdmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fdmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fdmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fq.material = fdmat
	flame.draw_pass_1 = fq
	root.add_child(flame)
	flame.owner = root
	
	var light = OmniLight3D.new()
	light.name = "FireLight"
	light.light_color = Color(1, 0.5, 0)
	light.light_energy = 2.0
	light.shadow_enabled = true
	root.add_child(light)
	light.owner = root
	
	_save_scene(root, name)

func _create_emergency_pulse(name: String):
	var root = Node3D.new()
	root.name = name
	
	var light = OmniLight3D.new()
	light.name = "WarningLight"
	light.light_color = Color(1, 0, 0)
	light.light_energy = 0.0
	root.add_child(light)
	light.owner = root
	
	var anim = AnimationPlayer.new()
	anim.name = "AnimationPlayer"
	var library = AnimationLibrary.new()
	var a = Animation.new()
	var track = a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(track, "WarningLight:light_energy")
	a.track_insert_key(track, 0.0, 0.0)
	a.track_insert_key(track, 0.5, 3.0)
	a.track_insert_key(track, 1.0, 0.0)
	a.loop_mode = Animation.LOOP_LINEAR
	a.length = 1.0
	library.add_animation("default", a)
	anim.add_animation_library("", library)
	root.add_child(anim)
	anim.owner = root
	
	_save_scene(root, name)
	
func _create_energy_pulse(name: String):
	var root = Node3D.new()
	root.name = name
	
	var light = OmniLight3D.new()
	light.name = "PulseLight"
	light.light_color = Color(0, 0.5, 1)
	light.light_energy = 0.0
	root.add_child(light)
	light.owner = root
	
	var anim = AnimationPlayer.new()
	anim.name = "AnimationPlayer"
	var library = AnimationLibrary.new()
	var a = Animation.new()
	var track = a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(track, "PulseLight:light_energy")
	a.track_insert_key(track, 0.0, 0.0)
	a.track_insert_key(track, 0.1, 5.0)
	a.track_insert_key(track, 0.5, 0.0)
	a.length = 0.6
	library.add_animation("default", a)
	anim.add_animation_library("", library)
	root.add_child(anim)
	anim.owner = root
	
	_save_scene(root, name)

func _create_robot_activation(name: String):
	var root = Node3D.new()
	root.name = name
	
	var light = OmniLight3D.new()
	light.name = "InternalIllumination"
	light.light_color = Color(0.2, 0.8, 1)
	light.light_energy = 0.0
	root.add_child(light)
	light.owner = root
	
	var anim = AnimationPlayer.new()
	anim.name = "AnimationPlayer"
	var library = AnimationLibrary.new()
	var a = Animation.new()
	var track = a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(track, "InternalIllumination:light_energy")
	a.track_insert_key(track, 0.0, 0.0)
	a.track_insert_key(track, 0.5, 1.0) # Tiny pulse
	a.track_insert_key(track, 1.0, 0.2)
	a.track_insert_key(track, 2.0, 2.0) # Fully active
	a.length = 2.0
	library.add_animation("default", a)
	anim.add_animation_library("", library)
	root.add_child(anim)
	anim.owner = root
	
	_save_scene(root, name)

func _create_electrical_arc(name: String):
	var root = GPUParticles3D.new()
	root.name = name
	root.amount = 5
	root.lifetime = 0.2
	root.explosiveness = 0.5
	
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.5
	mat.gravity = Vector3(0, 0, 0)
	root.process_material = mat
	
	var pass1 = QuadMesh.new()
	var dmat = StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.albedo_color = Color(0.5, 0.8, 1.0)
	dmat.emission_enabled = true
	dmat.emission = Color(0.5, 0.8, 1.0)
	dmat.emission_energy_multiplier = 4.0
	dmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	pass1.material = dmat
	root.draw_pass_1 = pass1
	
	_save_scene(root, name)
