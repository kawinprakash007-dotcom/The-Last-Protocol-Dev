extends Node
class_name CinematicVFXMaster

## Manages the spawning and lifecycle of procedural VFX scenes.
const VFX_DIR = "res://story/cinematics/vfx/"

## Spawns a VFX scene by name and attaches it to the parent node at the specified global position.
## For particles, it automatically calls restart() to ensure it fires.
static func spawn_vfx(vfx_name: String, global_pos: Vector3, parent: Node, scale: float = 1.0) -> Node3D:
	var path = VFX_DIR + vfx_name + ".tscn"
	if not ResourceLoader.exists(path):
		printerr("VFX not found: ", path)
		return null
		
	var vfx_scene = load(path)
	var inst = vfx_scene.instantiate() as Node3D
	
	if not inst:
		return null
		
	parent.add_child(inst)
	inst.global_position = global_pos
	inst.scale = Vector3(scale, scale, scale)
	
	# If the root is a particle system, emit it
	if inst is GPUParticles3D:
		inst.restart()
		_auto_free_particles(inst)
	else:
		# Search for child particle systems and emit them
		var found_particles = false
		for child in inst.get_children():
			if child is GPUParticles3D:
				child.restart()
				_auto_free_particles(child, inst)
				found_particles = true
				
		# If no particles, maybe it's driven by AnimationPlayer
		if not found_particles:
			var anim = inst.get_node_or_null("AnimationPlayer")
			if anim:
				anim.play("default")
				anim.animation_finished.connect(func(anim_name): inst.queue_free())
	
	return inst

static func _auto_free_particles(particles: GPUParticles3D, root_to_free: Node = null):
	var target = root_to_free if root_to_free else particles
	particles.finished.connect(func(): target.queue_free())

## Sequence for robot activation VFX
static func trigger_robot_activation(robot_node: Node3D):
	spawn_vfx("RobotActivationVFX", robot_node.global_position, robot_node)
