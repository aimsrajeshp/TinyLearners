extends Control

const ALPHABET_QUIZ := "res://scenes/quiz/AlphabetQuiz.tscn"
const NUMBER_QUIZ := "res://scenes/quiz/NumberQuiz.tscn"

@onready var _alphabet_button: Button = $Content/AlphabetButton
@onready var _number_button: Button = $Content/NumberButton
@onready var _back_button: Button = $BackButton

func _ready() -> void:
	_alphabet_button.pressed.connect(func(): Navigation.go_to(ALPHABET_QUIZ))
	_number_button.pressed.connect(func(): Navigation.go_to(NUMBER_QUIZ))
	_back_button.pressed.connect(func(): Navigation.go_home())
