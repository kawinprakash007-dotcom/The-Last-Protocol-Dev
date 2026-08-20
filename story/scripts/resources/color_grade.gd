extends Resource
class_name ColorGrade

@export_category("Exposure & Tone")
@export var tonemap_mode: Environment.ToneMapper = Environment.TONE_MAPPER_ACES
@export var exposure: float = 1.0
@export var contrast: float = 1.0
@export var saturation: float = 1.0

@export_category("Color Adjustments")
@export var brightness: float = 1.0
@export var adjustment_color_correction: Texture2D

@export_category("Glow & Bloom")
@export var glow_enabled: bool = true
@export var glow_intensity: float = 0.8
@export var glow_strength: float = 1.0
@export var glow_bloom: float = 0.05
@export var glow_blend_mode: Environment.GlowBlendMode = Environment.GLOW_BLEND_MODE_ADDITIVE

@export_category("Depth of Field")
@export var dof_blur_far_enabled: bool = true
@export var dof_blur_far_distance: float = 50.0
@export var dof_blur_far_transition: float = 10.0
@export var dof_blur_near_enabled: bool = false
@export var dof_blur_near_distance: float = 2.0
@export var dof_blur_near_transition: float = 1.0

func apply_to_environment(env: Environment, camera_attributes_owner: Object = null) -> void:
	if not env: return
	
	env.tonemap_mode = tonemap_mode
	env.tonemap_exposure = exposure
	
	# Fallback if properties missing in standard environment, mostly done via adjustment_enabled
	env.adjustment_enabled = true
	env.adjustment_contrast = contrast
	env.adjustment_saturation = saturation
	env.adjustment_brightness = brightness
	if adjustment_color_correction:
		env.adjustment_color_correction = adjustment_color_correction
		
	env.glow_enabled = glow_enabled
	env.glow_intensity = glow_intensity
	env.glow_strength = glow_strength
	env.glow_bloom = glow_bloom
	env.glow_blend_mode = glow_blend_mode
	
	var attributes: CameraAttributesPractical = null
	if camera_attributes_owner:
		if camera_attributes_owner is WorldEnvironment:
			if not camera_attributes_owner.camera_attributes or not (camera_attributes_owner.camera_attributes is CameraAttributesPractical):
				camera_attributes_owner.camera_attributes = CameraAttributesPractical.new()
			attributes = camera_attributes_owner.camera_attributes as CameraAttributesPractical
		elif camera_attributes_owner is Camera3D:
			if not camera_attributes_owner.attributes or not (camera_attributes_owner.attributes is CameraAttributesPractical):
				camera_attributes_owner.attributes = CameraAttributesPractical.new()
			attributes = camera_attributes_owner.attributes as CameraAttributesPractical
			
	if attributes:
		attributes.exposure_multiplier = exposure
		attributes.dof_blur_far_enabled = dof_blur_far_enabled
		attributes.dof_blur_far_distance = dof_blur_far_distance
		attributes.dof_blur_far_transition = dof_blur_far_transition
		
		attributes.dof_blur_near_enabled = dof_blur_near_enabled
		attributes.dof_blur_near_distance = dof_blur_near_distance
		attributes.dof_blur_near_transition = dof_blur_near_transition
