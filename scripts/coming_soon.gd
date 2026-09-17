extends Control
## Temporary placeholder screen used until a section's real content is built.

@export var section_title: String = "Coming Soon"
@export var section_emoji: String = "✨"

@onready var _title_label: Label = $Content/TitleLabel
@onready var _back_button: Button = $BackButton

func _ready() -> void:
	_title_label.text = "%s %s" % [section_emoji, section_title]
	_back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	Navigation.go_home()
