extends CanvasLayer

@onready var objective_label: Label = $HUD/TopLeft/ObjectiveContainer/HBox/ObjectiveLabel
@onready var status_badge: PanelContainer = $HUD/TopLeft/ObjectiveContainer
@onready var status_indicator: ColorRect = $HUD/TopLeft/ObjectiveContainer/HBox/StatusDot
@onready var prompt_panel: PanelContainer = $HUD/CenterPrompt

var _prev_activated: bool = false

func _ready() -> void:
	_update_ui_state(false)

func _process(_delta: float) -> void:
	if GameState.terminal_activated != _prev_activated:
		_prev_activated = GameState.terminal_activated
		_update_ui_state(_prev_activated)

func _update_ui_state(activated: bool) -> void:
	if not objective_label or not status_indicator:
		return
	if activated:
		objective_label.text = "PROTOCOL ENGAGED: AIRLOCK OPEN"
		status_indicator.color = Color(0.1, 0.95, 0.4, 1.0)
	else:
		objective_label.text = "PRIMARY OBJECTIVE: ENGAGE PROTOCOL TERMINAL"
		status_indicator.color = Color(0.0, 0.85, 1.0, 1.0)
