extends Control

const ALPHABET_LEARN := "res://scenes/alphabet/AlphabetLearn.tscn"
const BUTTON_VARIATIONS := ["MenuButtonBlue", "MenuButtonYellow", "MenuButtonOrange", "MenuButtonGreen"]

@onready var _grid: GridContainer = $VBox/Scroll/Grid
@onready var _back_button: Button = $BackButton

func _ready() -> void:
	AudioManager.play_voice("common/lets_learn_letters")
	_back_button.pressed.connect(func(): Navigation.go_home())
	_populate_grid()

func _populate_grid() -> void:
	for i in GameData.alphabet_data.size():
		var entry: Dictionary = GameData.alphabet_data[i]
		var button := Button.new()
		button.text = entry.get("letter", "?")
		button.custom_minimum_size = Vector2(150, 150)
		button.theme_type_variation = BUTTON_VARIATIONS[i % BUTTON_VARIATIONS.size()]
		if GameData.alphabet_progress.get(entry.get("letter", ""), false):
			button.text += "\n✓"
		button.pressed.connect(_on_letter_pressed.bind(i))
		_grid.add_child(button)

func _on_letter_pressed(index: int) -> void:
	GameData.selected_index = index
	Navigation.go_to(ALPHABET_LEARN)
