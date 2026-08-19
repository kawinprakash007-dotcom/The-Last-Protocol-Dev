extends Node
class_name VFXManager

static func spawn_sparks(parent: Node3D, position: Vector3):
	var particles = GPUParticles3D.new()
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.8, 0.2)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.8, 0.2)
	material.emission_energy_multiplier = 4.0
	
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.05, 0.05)
	mesh.material = material
	
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0, 1, 0)
	p_mat.spread = 45.0
	p_mat.initial_velocity_min = 2.0
	p_mat.initial_velocity_max = 5.0
	p_mat.gravity = Vector3(0, -9.8, 0)
	
	particles.process_material = p_mat
	particles.draw_pass_1 = mesh
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.lifetime = 1.0
	
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	
	var timer = Timer.new()
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.timeout.connect(particles.queue_free)
	particles.add_child(timer)
	timer.start()

static func spawn_smoke(parent: Node3D, position: Vector3):
	var particles = GPUParticles3D.new()
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.3, 0.3, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.material = material
	
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0, 1, 0)
	p_mat.spread = 20.0
	p_mat.initial_velocity_min = 1.0
	p_mat.initial_velocity_max = 2.0
	p_mat.gravity = Vector3(0, 0.5, 0)
	
	particles.process_material = p_mat
	particles.draw_pass_1 = mesh
	particles.amount = 16
	particles.lifetime = 3.0
	
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true

static func spawn_rain(parent: Node3D, position: Vector3):
	var particles = GPUParticles3D.new()
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.8, 1.0, 0.4)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.02, 0.5)
	mesh.material = material
	
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0, -1, 0)
	p_mat.spread = 5.0
	p_mat.initial_velocity_min = 15.0
	p_mat.initial_velocity_max = 20.0
	p_mat.gravity = Vector3(0, -9.8, 0)
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p_mat.emission_box_extents = Vector3(10.0, 1.0, 10.0)
	
	particles.process_material = p_mat
	particles.draw_pass_1 = mesh
	particles.amount = 1000
	particles.lifetime = 2.0
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true

static func spawn_fog(parent: Node3D, position: Vector3):
	var particles = GPUParticles3D.new()
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.5, 0.5, 0.1)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	
	var mesh = QuadMesh.new()
	mesh.size = Vector2(4.0, 4.0)
	mesh.material = material
	
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(1, 0, 0)
	p_mat.spread = 180.0
	p_mat.initial_velocity_min = 0.5
	p_mat.initial_velocity_max = 1.0
	p_mat.gravity = Vector3(0, 0.05, 0)
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	p_mat.emission_sphere_radius = 5.0
	
	particles.process_material = p_mat
	particles.draw_pass_1 = mesh
	particles.amount = 50
	particles.lifetime = 10.0
	
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true

static func spawn_electricity(parent: Node3D, position: Vector3):
	var particles = GPUParticles3D.new()
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.6, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.2, 0.6, 1.0)
	material.emission_energy_multiplier = 6.0
	
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.1, 0.8)
	mesh.material = material
	
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0, 1, 0)
	p_mat.spread = 180.0
	p_mat.initial_velocity_min = 3.0
	p_mat.initial_velocity_max = 6.0
	p_mat.gravity = Vector3(0, 0, 0)
	
	particles.process_material = p_mat
	particles.draw_pass_1 = mesh
	particles.amount = 8
	particles.lifetime = 0.2
	particles.explosiveness = 0.9
	
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(particles.queue_free)
	particles.add_child(timer)
	timer.start()
