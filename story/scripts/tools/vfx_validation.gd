extends SceneTree

const VFX_DIR = "res://story/cinematics/vfx/"
var vfx_list = [
	"SmallSparkBurst", "MediumSparkBurst", "HeavySparkBurst",
	"SmallSmoke", "MediumSmoke", "HeavySmoke",
	"SteamVFX", "DustVFX", "HolographicParticleVFX", "VehicleTrailVFX",
	"DebrisVFX", "SmallExplosion", "MediumExplosion", "LargeExplosion",
	"FireVFX", "EmergencyPulseVFX", "EnergyPulseVFX",
	"RobotActivationVFX", "ElectricalArcVFX"
]

func _init():
	print("--- Starting VFX Validation ---")
	
	for vfx_name in vfx_list:
		var path = VFX_DIR + vfx_name + ".tscn"
		if not ResourceLoader.exists(path):
			printerr("MISSING VFX SCENE: " + path)
			quit(1)
			return
			
		var scene = load(path)
		var inst = scene.instantiate()
		if inst:
			print("Validated load and instantiate for: " + vfx_name)
			inst.free()
		else:
			printerr("FAILED to instantiate: " + vfx_name)
			quit(1)
			return
			
	print("--- All VFX Scenes validated successfully ---")
	quit(0)
