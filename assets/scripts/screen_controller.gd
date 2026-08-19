extends MeshInstance3D

var _active_progress: float = 0.0

func _process(delta: float) -> void:
	var target := 1.0 if GameState.terminal_activated else 0.0
	_active_progress = move_toward(_active_progress, target, delta * 3.0)
	
	var mat := get_surface_override_material(0)
	if mat is ShaderMaterial:
		mat.set_shader_parameter("is_active", _active_progress)
	elif material_override is ShaderMaterial:
		material_override.set_shader_parameter("is_active", _active_progress)
