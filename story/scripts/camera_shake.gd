extends Camera3D
class_name CinematicCameraShake

@export var trauma_reduction_rate: float = 1.0
@export var max_x: float = 10.0
@export var max_y: float = 10.0
@export var max_z: float = 5.0
@export var max_roll: float = 0.1

var trauma: float = 0.0
var noise: FastNoiseLite = FastNoiseLite.new()
var noise_y: float = 0.0

@onready var initial_rotation: Vector3 = rotation

func _ready():
	noise.seed = randi()
	noise.frequency = 0.5
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4

func add_trauma(amount: float):
	trauma = min(trauma + amount, 1.0)

func _process(delta: float):
	if trauma > 0:
		trauma = max(trauma - trauma_reduction_rate * delta, 0.0)
		_apply_shake()
	elif rotation != initial_rotation:
		rotation = lerp(rotation, initial_rotation, delta * 5.0)

func _apply_shake():
	var amount = pow(trauma, 2)
	noise_y += 1.0
	
	var offset_x = max_x * amount * noise.get_noise_2d(noise.seed, noise_y)
	var offset_y = max_y * amount * noise.get_noise_2d(noise.seed + 1, noise_y)
	var offset_roll = max_roll * amount * noise.get_noise_2d(noise.seed + 2, noise_y)
	
	# Only modifying rotation since position shake often breaks cinematic framing too harshly
	rotation.x = initial_rotation.x + deg_to_rad(offset_x)
	rotation.y = initial_rotation.y + deg_to_rad(offset_y)
	rotation.z = initial_rotation.z + offset_roll

## Convenient trigger methods for cinematic events
func trigger_explosion():
	add_trauma(0.8)

func trigger_impact():
	add_trauma(0.5)

func trigger_mechanical_movement():
	add_trauma(0.3)

func trigger_building_collapse():
	add_trauma(1.0)

func trigger_system_failure():
	add_trauma(0.4)
