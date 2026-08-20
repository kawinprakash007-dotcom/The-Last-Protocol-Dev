## CinematicSubtitle — Premium Cinematic Narration & Log UI Overlay.
##
## Upgraded in Phase 16A to implement a narrative-focused presentation:
##   - Supports CREATOR LOG, SYSTEM NARRATION, MEMORY FRAGMENT, and CRITICAL LINE presentation types.
##   - Reveals text smoothly using a word/phrase-friendly fade reveal.
##   - Displays top-left/right metadata (Year, Location) synchronized with active shot data.
##   - Animates a technical scanning sweep and an active audio waveform indicator.
##
## Team Ownership: Story Team
##
extends CanvasLayer

# --- NODES ---
@onready var _anchor: Control = $SubtitleAnchor
@onready var _tl_meta: VBoxContainer = $SubtitleAnchor/TopLeftMeta
@onready var _tr_meta: VBoxContainer = $SubtitleAnchor/TopRightMeta
@onready var _tr_year_val: Label = $SubtitleAnchor/TopRightMeta/Value

@onready var _narration_panel: PanelContainer = $SubtitleAnchor/NarrationPanel
@onready var _speaker_label: Label = $SubtitleAnchor/NarrationPanel/VBox/Header/SpeakerLabel
@onready var _context_label: Label = $SubtitleAnchor/NarrationPanel/VBox/Header/ContextLabel
@onready var _waveform: HBoxContainer = $SubtitleAnchor/NarrationPanel/VBox/Header/AudioWaveform
@onready var _narration_text: RichTextLabel = $SubtitleAnchor/NarrationPanel/VBox/NarrationText
@onready var _scan_line: ColorRect = $SubtitleAnchor/NarrationPanel/ScanLine

@onready var _critical_container: CenterContainer = $SubtitleAnchor/CriticalContainer
@onready var _critical_text: Label = $SubtitleAnchor/CriticalContainer/CriticalText

# --- TWEEN & ANIMATION CONSTANTS ---
const FADE_DURATION: float = 0.4
const REVEAL_DURATION: float = 1.2
const CRITICAL_FADE_DURATION: float = 0.8

var _active_tween: Tween = null
var _waveform_active: bool = false
var _waveform_timer: float = 0.0

# Cached shot metadata
var _current_metadata: Dictionary = {}


func _ready() -> void:
	# Hide all components initially
	_anchor.modulate.a = 0.0
	_narration_panel.visible = false
	_critical_container.visible = false
	_scan_line.visible = false

	# Wire EventBus signals
	EventBus.narration_line_shown.connect(_on_narration_line_shown)
	EventBus.narration_finished.connect(_on_narration_finished)
	EventBus.hud_metadata_shown.connect(_on_hud_metadata_shown)


func _process(delta: float) -> void:
	if _waveform_active:
		_waveform_timer += delta
		if _waveform_timer >= 0.1:
			_waveform_timer = 0.0
			_randomize_waveform()


# --- SIGNAL HANDLERS ---

func _on_hud_metadata_shown(metadata: Dictionary) -> void:
	_current_metadata = metadata
	if metadata.has("YEAR"):
		_tr_year_val.text = str(metadata["YEAR"])
	else:
		_tr_year_val.text = "2047"  # Default fallback year


func _on_narration_line_shown(shot_id: String, speaker: String, text: String, duration: float) -> void:
	# Kill active tweens
	if _active_tween:
		_active_tween.kill()

	# Detect presentation type
	var is_crit := _is_critical_line(text)
	var is_sys := (speaker == "SYSTEM")
	var is_mem := (shot_id.contains("awakening") or shot_id.contains("recognition") or shot_id.contains("vs_creations"))

	if is_crit:
		_show_critical_line(text, duration)
	else:
		_show_standard_narration(speaker, text, is_sys, is_mem)


func _on_narration_finished(_shot_id: String) -> void:
	_waveform_active = false
	if _active_tween:
		_active_tween.kill()
	_active_tween = create_tween()
	_active_tween.tween_property(_anchor, "modulate:a", 0.0, FADE_DURATION)
	_active_tween.tween_callback(func():
		_narration_panel.visible = false
		_critical_container.visible = false
	)


# --- PRESENTATION DRAWING ---

func _show_standard_narration(speaker: String, text: String, is_sys: bool, is_mem: bool) -> void:
	_critical_container.visible = false
	_narration_panel.visible = true

	# Format text with quotation marks if RYAN log, or plain if SYSTEM classification
	if is_sys:
		_narration_text.text = text.to_upper()
		_speaker_label.text = "SYSTEM"
		_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.1, 1.0)) # Warning orange-red
		_context_label.text = "ARCHIVE // CLASSIFIED"
	elif is_mem:
		_narration_text.text = "[i]\"" + text + "\"[/i]"
		_speaker_label.text = speaker
		_speaker_label.add_theme_color_override("font_color", Color(0.55, 0.82, 1.0, 1.0))
		_context_label.text = "MEMORY FRAGMENT // UNKNOWN"
	else:
		_narration_text.text = "\"" + text + "\""
		_speaker_label.text = speaker
		_speaker_label.add_theme_color_override("font_color", Color(0.0, 0.67, 1.0, 1.0)) # Standard cyan
		var year_str := str(_current_metadata.get("YEAR", "2047"))
		_context_label.text = "CREATOR LOG // " + year_str

	# Set up reveal text reveal animation
	_narration_text.visible_ratio = 0.0

	# Fade in the anchor layer
	_active_tween = create_tween().set_parallel(true)
	_active_tween.tween_property(_anchor, "modulate:a", 1.0, FADE_DURATION)
	
	# Animate the text reveal ratio
	var text_reveal_tween := create_tween()
	text_reveal_tween.tween_property(_narration_text, "visible_ratio", 1.0, REVEAL_DURATION)
	
	# Sweep scan line across panel
	_run_scan_line_sweep()

	# Start waveform animation
	_waveform_active = true


func _show_critical_line(text: String, duration: float) -> void:
	_narration_panel.visible = false
	_critical_container.visible = true
	_critical_text.text = text.to_upper()
	_waveform_active = false

	# Slow immersive reveal
	_active_tween = create_tween()
	_active_tween.tween_property(_anchor, "modulate:a", 1.0, CRITICAL_FADE_DURATION)


func _run_scan_line_sweep() -> void:
	_scan_line.visible = true
	_scan_line.anchor_right = 0.0
	var t := create_tween()
	t.tween_property(_scan_line, "anchor_right", 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_callback(func(): _scan_line.visible = false)


func _randomize_waveform() -> void:
	for child in _waveform.get_children():
		if child is ProgressBar:
			child.value = randf_range(10.0, 95.0)


func _is_critical_line(text: String) -> bool:
	var clean := text.to_upper().strip_edges()
	return (
		clean.contains("I WAS WRONG") or
		clean.contains("I GAVE THEM THE KEYS") or
		clean.contains("THERE WAS ONLY ONE PROTOCOL LEFT") or
		clean.contains("MINE.") or
		clean.contains("MINE") and clean.length() <= 5
	)
