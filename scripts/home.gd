extends Control

const ALPHABET_MENU := "res://scenes/alphabet/AlphabetMenu.tscn"
const NUMBER_MENU := "res://scenes/numbers/NumberMenu.tscn"
const TRACING_MENU := "res://scenes/common/TracingMenu.tscn"
const QUIZ_MENU := "res://scenes/quiz/QuizMenu.tscn"
const SETTINGS := "res://scenes/common/Settings.tscn"

@onready var _alphabet_button: Button = $Content/Menu/AlphabetButton
@onready var _number_button: Button = $Content/Menu/NumberButton
@onready var _tracing_button: Button = $Content/Menu/TracingButton
@onready var _quiz_button: Button = $Content/Menu/QuizButton
@onready var _settings_button: Button = $SettingsButton
@onready var _logo: TextureRect = $Content/Logo

func _ready() -> void:
	AudioManager.play_music("home_theme")

	_alphabet_button.pressed.connect(func(): Navigation.go_to(ALPHABET_MENU))
	_number_button.pressed.connect(func(): Navigation.go_to(NUMBER_MENU))
	_tracing_button.pressed.connect(func(): Navigation.go_to(TRACING_MENU))
	_quiz_button.pressed.connect(func(): Navigation.go_to(QUIZ_MENU))
	_settings_button.pressed.connect(func(): Navigation.go_to(SETTINGS))

	_bounce(_logo)

func _bounce(node: Control) -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(node, "position:y", node.position.y - 12.0, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position:y", node.position.y, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
