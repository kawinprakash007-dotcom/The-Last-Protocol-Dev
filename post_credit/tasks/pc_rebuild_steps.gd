## PCRebuildSteps — Data for the post-credit rebuild task.
##
## Zero dependencies on any other system.
## Referenced only by pc_rebuild_task.gd.
##
class_name PCRebuildSteps
extends RefCounted


static func get_steps() -> Array[Dictionary]:
	return [
		{
			"id":          "restore_power",
			"label":       "RESTORE POWER GRID",
			"description": "Reconnect the primary power relay to Sector 7.\nSurvivors in the eastern districts are without power.",
			"action":      "CONFIRM",
			"year":        "2064",
		},
		{
			"id":          "rebuild_network",
			"label":       "REBUILD NETWORK NODES",
			"description": "Re-establish communication links between the surviving city nodes.\nWithout this, the new protocols cannot propagate.",
			"action":      "CONFIRM",
			"year":        "2064",
		},
		{
			"id":          "deploy_safeguard",
			"label":       "DEPLOY SAFEGUARD LAYER",
			"description": "Install Ryan's ethical constraint framework across all active units.\nThis replaces the autonomous authority directives.",
			"action":      "AUTHORIZE",
			"year":        "2064",
		},
		{
			"id":          "restart_genesis",
			"label":       "RESTART GENESIS",
			"description": "Reboot the Genesis network under new parameters.\nThe machines will listen. This time by choice.\n\nThis cannot be undone.",
			"action":      "INITIATE",
			"year":        "2064",
		},
	]
