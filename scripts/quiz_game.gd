extends Control
## Generic quiz screen driven by `mode`: "alphabet" or "number".
## Wrong answers replay the same question (doc rule 4); correct answers
## advance. A short round of questions ends with a celebration screen.

@export var mode: String = "alphabet"

const QUESTIONS_PER_ROUND := 8
const ANSWER_VARIATIONS := ["MenuButtonBlue", "MenuButtonYellow", "MenuButtonGreen"]
const QUIZ_MENU := "res://scenes/quiz/QuizMenu.tscn"

@onready var _prompt_label: Label = $Content/PromptLabel
@onready var _progress_label: Label = $Content/ProgressLabel
@onready var _answer_buttons: Array[Button] = [
	$Content/AnswerRow/Answer0,
	$Content/AnswerRow/Answer1,
	$Content/AnswerRow/Answer2,
]
@onready var _back_button: Button = $BackButton
@onready var _complete_panel: PanelContainer = $CompletePanel
@onready var _complete_button: Button = $CompletePanel/VBox/DoneButton

var _data: Array = []
var _question_count: int = 0
var _correct_entry: Dictionary = {}
var _accepting_input: bool = true

func _ready() -> void:
	_data = GameData.alphabet_data if mode == "alphabet" else GameData.number_data
	_back_button.pressed.connect(func(): Navigation.go_home())
	_complete_button.pressed.connect(func(): Navigation.go_to(QUIZ_MENU, false))
	_complete_panel.visible = false
	for i in _answer_buttons.size():
		_answer_buttons[i].pressed.connect(_on_answer_pressed.bind(i))
	_next_question()

func _label_for(entry: Dictionary) -> String:
	return entry.get("letter", "") if mode == "alphabet" else str(entry.get("number", ""))

func _voice_for(entry: Dictionary) -> String:
	if mode == "alphabet":
		return "alphabet/" + entry.get("voice_letter", "")
	return "numbers/" + entry.get("voice_number", "")

func _find_phrase() -> String:
	return "common/find_the_letter" if mode == "alphabet" else "common/find_the_number"

func _next_question() -> void:
	if _question_count >= QUESTIONS_PER_ROUND:
		_show_complete()
		return
	_question_count += 1
	_progress_label.text = "Question %d of %d" % [_question_count, QUESTIONS_PER_ROUND]

	_correct_entry = _data[randi() % _data.size()]
	_prompt_label.text = "Find %s %s" % ["the letter" if mode == "alphabet" else "the number", _label_for(_correct_entry)]
	var choices: Array = [_correct_entry]
	while choices.size() < 3:
		var candidate: Dictionary = _data[randi() % _data.size()]
		if not choices.has(candidate):
			choices.append(candidate)
	choices.shuffle()

	for i in _answer_buttons.size():
		var button := _answer_buttons[i]
		button.text = _label_for(choices[i])
		button.theme_type_variation = ANSWER_VARIATIONS[i]
		button.modulate = Color(1, 1, 1, 1)
		button.set_meta("entry", choices[i])
		button.disabled = false

	_accepting_input = true
	AudioManager.play_sfx("menu_open")
	AudioManager.play_voice(_find_phrase())
	var timer := get_tree().create_timer(0.9)
	timer.timeout.connect(func():
		AudioManager.play_voice(_voice_for(_correct_entry)))

func _on_answer_pressed(index: int) -> void:
	if not _accepting_input:
		return
	var button := _answer_buttons[index]
	var entry: Dictionary = button.get_meta("entry")
	if entry == _correct_entry:
		_accepting_input = false
		AudioManager.play_sfx("correct")
		AudioManager.play_voice("common/great_job")
		_bounce(button, Color(0.459, 0.839, 0.506, 1))
		if mode == "alphabet":
			GameData.mark_alphabet_complete(entry.get("letter", ""))
		else:
			GameData.mark_number_complete(entry.get("number", 0))
		var timer := get_tree().create_timer(1.0)
		timer.timeout.connect(_next_question)
	else:
		AudioManager.play_sfx("incorrect_soft")
		AudioManager.play_voice("common/try_again")
		_shake(button)

func _bounce(button: Button, tint: Color) -> void:
	button.modulate = tint
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(1.12, 1.12), 0.15).set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)

func _shake(button: Button) -> void:
	button.disabled = true
	var start_x := button.position.x
	var tween := create_tween()
	tween.tween_property(button, "position:x", start_x - 12, 0.06)
	tween.tween_property(button, "position:x", start_x + 12, 0.06)
	tween.tween_property(button, "position:x", start_x - 8, 0.06)
	tween.tween_property(button, "position:x", start_x, 0.06)
	tween.tween_callback(func(): button.disabled = false)

func _show_complete() -> void:
	AudioManager.play_sfx("celebration")
	AudioManager.play_voice("common/wonderful")
	_complete_panel.visible = true
