extends CanvasLayer

@onready var objective_panel: Panel = $Control/ObjectivePanel
@onready var objective_text: Label = $Control/ObjectivePanel/ObjectiveText


# Safely show the objective panel with the specified text
func show_objective(text: String) -> void:
	objective_text.text = text
	objective_panel.show()


# Safely hide the objective panel
func hide_objective() -> void:
	objective_panel.hide()


# Safely update the objective text
func update_objective(text: String) -> void:
	objective_text.text = text
