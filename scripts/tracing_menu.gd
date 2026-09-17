extends Control

const ALPHABET_TRACE := "res://scenes/alphabet/AlphabetTrace.tscn"
const NUMBER_TRACE := "res://scenes/numbers/NumberTrace.tscn"

@onready var _alphabet_button: Button = $Content/AlphabetButton
@onready var _number_button: Button = $Content/NumberButton
@onready var _back_button: Button = $BackButton

func _ready() -> void:
	_alphabet_button.pressed.connect(func(): Navigation.go_to(ALPHABET_TRACE))
	_number_button.pressed.connect(func(): Navigation.go_to(NUMBER_TRACE))
	_back_button.pressed.connect(func(): Navigation.go_home())
