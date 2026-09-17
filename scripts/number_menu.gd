extends Control

const NUMBER_LEARN := "res://scenes/numbers/NumberLearn.tscn"
const BUTTON_VARIATIONS := ["MenuButtonBlue", "MenuButtonYellow", "MenuButtonOrange", "MenuButtonGreen", "MenuButtonPurple", "MenuButtonPink"]

@onready var _grid: GridContainer = $VBox/Scroll/Grid
@onready var _back_button: Button = $BackButton

func _ready() -> void:
	AudioManager.play_voice("common/lets_learn_numbers")
	_back_button.pressed.connect(func(): Navigation.go_home())
	_populate_grid()

func _populate_grid() -> void:
	for i in GameData.number_data.size():
		var entry: Dictionary = GameData.number_data[i]
		var button := Button.new()
		button.text = str(entry.get("number", "?"))
		button.custom_minimum_size = Vector2(150, 150)
		button.theme_type_variation = BUTTON_VARIATIONS[i % BUTTON_VARIATIONS.size()]
		if GameData.number_progress.get(str(entry.get("number", "")), false):
			button.text += "\n✓"
		button.pressed.connect(_on_number_pressed.bind(i))
		_grid.add_child(button)

func _on_number_pressed(index: int) -> void:
	GameData.selected_index = index
	Navigation.go_to(NUMBER_LEARN)
