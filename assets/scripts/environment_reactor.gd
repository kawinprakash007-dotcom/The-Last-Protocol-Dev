extends Node
class_name EnvironmentReactor

enum EventTrigger {
	POWER_ON,
	POWER_OFF,
	ALARM_TRIGGERED,
	ALARM_CLEARED,
	TERMINAL_ACTIVATED,
	TERMINAL_DEACTIVATED,
	SECURITY_BREACH,
	SECURITY_SECURE
}

@export var listen_for_event: EventTrigger = EventTrigger.POWER_OFF
@export var target_node: Node

@export_group("Light Reaction")
@export var react_light: bool = false
@export var active_energy: float = 2.0
@export var inactive_energy: float = 0.1
@export var active_color: Color = Color.WHITE
@export var inactive_color: Color = Color.RED

@export_group("Shader Reaction")
@export var react_shader: bool = false
@export var active_shader_param: String = "is_active"
@export var active_value: float = 1.0
@export var inactive_value: float = 0.0

@export_group("VFX Reaction")
@export var react_vfx: bool = false
@export var vfx_type: String = "sparks" # sparks, smoke, electricity

func _ready():
	# In a real game, you would connect to a global event bus here
	# Example: GlobalEvents.connect("environment_event", Callable(self, "_on_environment_event"))
	if not target_node:
		target_node = get_parent()

func trigger_reaction(is_active_state: bool):
	if react_light and target_node is Light3D:
		target_node.light_energy = active_energy if is_active_state else inactive_energy
		target_node.light_color = active_color if is_active_state else inactive_color
		
	if react_shader:
		var mat = null
		if target_node is MeshInstance3D:
			mat = target_node.get_active_material(0)
		elif target_node is Control:
			mat = target_node.material
			
		if mat and mat is ShaderMaterial:
			mat.set_shader_parameter(active_shader_param, active_value if is_active_state else inactive_value)

	if react_vfx and not is_active_state: # Often VFX trigger when something fails
		if target_node is Node3D:
			if vfx_type == "sparks":
				VFXManager.spawn_sparks(target_node, target_node.global_position)
			elif vfx_type == "smoke":
				VFXManager.spawn_smoke(target_node, target_node.global_position)
			elif vfx_type == "electricity":
				VFXManager.spawn_electricity(target_node, target_node.global_position)

# Example global event callback
func _on_environment_event(event_type: EventTrigger):
	if event_type == listen_for_event:
		# Determine if the event puts the object into an "active/good" state or "inactive/bad" state
		var state = false
		if event_type in [EventTrigger.POWER_ON, EventTrigger.ALARM_CLEARED, EventTrigger.TERMINAL_ACTIVATED, EventTrigger.SECURITY_SECURE]:
			state = true
			
		trigger_reaction(state)
