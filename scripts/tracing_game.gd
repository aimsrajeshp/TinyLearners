extends Control
## Generic tracing screen driven by `mode`: "alphabet" or "number".
## Leaving the path resets the current item (doc rule: boundary violation
## -> retry, same letter/number, unlimited attempts, no penalty).

@export var mode: String = "alphabet"

const TRACING_MENU := "res://scenes/common/TracingMenu.tscn"

@onready var _trace_pad: Control = $TracePad
@onready var _instruction_label: Label = $InstructionLabel
@onready var _back_button: Button = $BackButton
@onready var _complete_panel: PanelContainer = $CompletePanel
@onready var _complete_button: Button = $CompletePanel/VBox/DoneButton

var _data: Array = []
var _index: int = 0

func _ready() -> void:
	_data = GameData.alphabet_data if mode == "alphabet" else GameData.number_data
	_back_button.pressed.connect(func(): Navigation.go_home())
	_complete_button.pressed.connect(func(): Navigation.go_to(TRACING_MENU, false))
	_complete_panel.visible = false
	_trace_pad.stroke_completed.connect(_on_stroke_completed)
	_trace_pad.trace_completed.connect(_on_trace_completed)
	_trace_pad.trace_failed.connect(_on_trace_failed)
	_show_item()

func _char_for(entry: Dictionary) -> String:
	return entry.get("letter", "") if mode == "alphabet" else str(entry.get("number", ""))

func _voice_for(entry: Dictionary) -> String:
	if mode == "alphabet":
		return "alphabet/" + entry.get("voice_letter", "")
	return "numbers/" + entry.get("voice_number", "")

func _trace_phrase() -> String:
	return "common/trace_the_letter" if mode == "alphabet" else "common/trace_the_number"

func _show_item() -> void:
	var entry: Dictionary = _data[_index]
	var ch := _char_for(entry)
	_instruction_label.text = "Trace %s" % ch
	var glyph: Dictionary = GameData.trace_paths.get(ch, {})
	_trace_pad.set_glyph(glyph)

	AudioManager.play_sfx("tracing_start")
	AudioManager.play_voice(_trace_phrase())
	var timer := get_tree().create_timer(0.8)
	timer.timeout.connect(func():
		AudioManager.play_voice(_voice_for(entry)))

func _on_stroke_completed(_stroke_index: int) -> void:
	AudioManager.play_sfx("picture_pop")

func _on_trace_failed() -> void:
	AudioManager.play_sfx("tracing_error")
	AudioManager.play_voice("common/try_again")

func _on_trace_completed() -> void:
	AudioManager.play_sfx("tracing_complete")
	AudioManager.play_voice("common/great_job")
	var entry: Dictionary = _data[_index]
	if mode == "alphabet":
		GameData.mark_alphabet_traced(entry.get("letter", ""))
	else:
		GameData.mark_number_traced(entry.get("number", 0))

	var timer := get_tree().create_timer(1.1)
	timer.timeout.connect(_advance)

func _advance() -> void:
	_index += 1
	if _index >= _data.size():
		AudioManager.play_sfx("celebration")
		AudioManager.play_voice("common/wonderful")
		_complete_panel.visible = true
		return
	_show_item()
