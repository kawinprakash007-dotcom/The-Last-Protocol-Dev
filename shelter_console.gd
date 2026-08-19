extends Interactable

@onready var status_light: OmniLight3D = $StatusLight
@onready var screen_mesh: MeshInstance3D = $ShelterConsoleVisual/Shelter_Screen

var _is_unlocked: bool = false
var _interact_count: int = 0

var _locked_mat: StandardMaterial3D
var _unlocked_mat: StandardMaterial3D


func _ready() -> void:
	print("SHELTER CONSOLE SCRIPT LOADED - DEBUG VERSION")

	_locked_mat = StandardMaterial3D.new()
	_locked_mat.albedo_color = Color(1.0, 0.1, 0.1, 1)
	_locked_mat.emission_enabled = true
	_locked_mat.emission = Color(1.0, 0.1, 0.1, 1)
	_locked_mat.emission_energy_multiplier = 2.0

	_unlocked_mat = StandardMaterial3D.new()
	_unlocked_mat.albedo_color = Color(0.1, 0.9, 0.2, 1)
	_unlocked_mat.emission_enabled = true
	_unlocked_mat.emission = Color(0.1, 0.9, 0.2, 1)
	_unlocked_mat.emission_energy_multiplier = 2.0

	screen_mesh.material_override = _locked_mat
	status_light.light_color = Color(1.0, 0.1, 0.1, 1)


func interact() -> void:
	print("SHELTER CONSOLE: E INTERACTION")

	if _is_unlocked:
		_log_player("CONSOLE: SHELTER 04 SECURITY ALREADY DISABLED")
		return

	_interact_count += 1

	if _interact_count == 1:
		_log_player("CONSOLE: SHELTER 04 — LOCK STATUS: ACTIVE")
		_log_player("CONSOLE: AUTONOMOUS SECURITY: ONLINE")
		_log_player("CONSOLE: NODE ID SN-4712 — LOCAL OVERRIDE ACCESSIBLE")
		_log_player("[INTERACT AGAIN TO DISABLE LOCAL SECURITY]")
		return

	await _unlock_shelter()


func _unlock_shelter() -> void:
	print("SHELTER: STARTING UNLOCK")

	_is_unlocked = true

	screen_mesh.material_override = _unlocked_mat
	status_light.light_color = Color(0.1, 0.9, 0.2)

	var scene_root := get_tree().current_scene

	if scene_root == null:
		print("SHELTER ERROR: current_scene is null")
		return

	# -------------------------------------------------------
	# 1. FIND THE PHYSICAL DOOR BLOCKER
	# -------------------------------------------------------

	var blocker := scene_root.find_child("ShelterDoorBlocker", true, false)

	if blocker != null:
		print("SHELTER: FOUND BLOCKER -> ", blocker.get_path())

		# Disable every collision inside the blocker.
		var blocker_collisions := blocker.find_children(
			"*",
			"CollisionShape3D",
			true,
			false
		)

		for collision in blocker_collisions:
			if collision is CollisionShape3D:
				collision.set_deferred("disabled", true)
				print("SHELTER: BLOCKER COLLISION DISABLED")

		# Hide every visual mesh inside the blocker.
		var blocker_meshes := blocker.find_children(
			"*",
			"MeshInstance3D",
			true,
			false
		)

		for mesh in blocker_meshes:
			if mesh is MeshInstance3D:
				mesh.visible = false

		# Move the blocker far below the entrance.
		if blocker is Node3D:
			var blocker_node := blocker as Node3D
			blocker_node.position.y -= 5.0
			print("SHELTER: BLOCKER MOVED DOWN")

	else:
		print("SHELTER ERROR: ShelterDoorBlocker NOT FOUND")


	# -------------------------------------------------------
	# 2. HIDE THE VISIBLE GREEN DOOR
	# -------------------------------------------------------

	var visual_door := scene_root.find_child("ShelterDoor", true, false)

	if visual_door != null:
		print("SHELTER: FOUND VISUAL DOOR -> ", visual_door.get_path())

		if visual_door is MeshInstance3D:
			visual_door.visible = false
			print("SHELTER: VISUAL DOOR HIDDEN")
	else:
		print("SHELTER WARNING: ShelterDoor NOT FOUND")


	# -------------------------------------------------------
	# 3. DISABLE SHELTER COLLISIONS
	# -------------------------------------------------------
	# This is the important safety measure.
	# If any old/full-box Shelter collision remains,
	# it cannot block the entrance anymore.

	var shelter := scene_root.find_child("Shelter", true, false)

	if shelter != null:
		print("SHELTER: FOUND SHELTER -> ", shelter.get_path())

		if shelter is CollisionObject3D:
			var shelter_object := shelter as CollisionObject3D
			shelter_object.collision_layer = 0
			shelter_object.collision_mask = 0
			print("SHELTER: ROOT COLLISION DISABLED")

		var shelter_collisions := shelter.find_children(
			"*",
			"CollisionShape3D",
			true,
			false
		)

		for collision in shelter_collisions:
			if collision is CollisionShape3D:
				collision.set_deferred("disabled", true)
				print("SHELTER: CHILD COLLISION DISABLED")


	# -------------------------------------------------------
	# 4. GAME STATE
	# -------------------------------------------------------

	if GameState.has_method("unlock_shelter"):
		GameState.unlock_shelter()

	_log_player("CONSOLE: SECURITY NODE SN-4712 — DISABLED")
	_log_player("CONSOLE: SHELTER 04 LOCK — RELEASED")
	_log_player("CONSOLE: SHELTER 04 ACCESS GRANTED")

	print("SHELTER: UNLOCK COMPLETE")


func _log_player(msg: String) -> void:
	print(msg)

	if Mission01.has_method("shelter_console_log"):
		Mission01.shelter_console_log(msg)