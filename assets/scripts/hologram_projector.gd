extends MeshInstance3D
class_name HologramProjector

@export var ui_scene: PackedScene
@export var resolution: Vector2i = Vector2i(1920, 1080)
@export var hologram_material: Material

var viewport: SubViewport
var ui_instance: Control

func _ready():
	# Create the SubViewport
	viewport = SubViewport.new()
	viewport.size = resolution
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = true
	add_child(viewport)
	
	# Instance the UI scene
	if ui_scene:
		ui_instance = ui_scene.instantiate()
		viewport.add_child(ui_instance)
	else:
		push_warning("HologramProjector: No UI scene assigned!")
		
	# Setup the material with the viewport texture
	if not material_override:
		material_override = hologram_material.duplicate() if hologram_material else StandardMaterial3D.new()
		
	# This part assumes a specific property name for the texture in the shader/material
	if material_override is ShaderMaterial:
		material_override.set_shader_parameter("albedo_tex", viewport.get_texture())
	elif material_override is StandardMaterial3D:
		material_override.albedo_texture = viewport.get_texture()
		material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material_override.emission_enabled = true
		material_override.emission_texture = viewport.get_texture()
