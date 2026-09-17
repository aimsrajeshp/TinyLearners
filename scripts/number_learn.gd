extends Control

const NUMBER_MENU := "res://scenes/numbers/NumberMenu.tscn"

@onready var _number_label: Label = $Content/NumberLabel
@onready var _stars_row: HFlowContainer = $Content/StarsRow
@onready var _word_label: Label = $Content/WordLabel
@onready var _listen_button: Button = $ListenButton
@onready var _back_button: Button = $BackButton
@onready var _prev_button: Button = $Content/NavRow/PrevButton
@onready var _next_button: Button = $Content/NavRow/NextButton

var _index: int = 0

func _ready() -> void:
	_index = GameData.selected_index
	_back_button.pressed.connect(func(): Navigation.go_home())
	_listen_button.pressed.connect(_replay_audio)
	_prev_button.pressed.connect(_go_previous)
	_next_button.pressed.connect(_go_next)
	_show_number()

func _current_entry() -> Dictionary:
	return GameData.number_data[_index]

func _show_number() -> void:
	var entry := _current_entry()
	var n: int = entry.get("number", 0)
	_number_label.text = str(n)
	_word_label.text = entry.get("word", "")

	for child in _stars_row.get_children():
		child.queue_free()
	for i in n:
		var star := Label.new()
		star.theme_type_variation = &"EmojiDisplay"
		star.add_theme_font_size_override("font_size", 56)
		star.text = "⭐"
		_stars_row.add_child(star)

	_prev_button.disabled = _index == 0
	_next_button.text = "Finish ✓" if _index == GameData.number_data.size() - 1 else "Next →"

	AudioManager.play_sfx("number_reveal")
	_animate_reveal()
	GameData.mark_number_complete(n)
	_replay_audio()

func _animate_reveal() -> void:
	_number_label.scale = Vector2(0.4, 0.4)
	_number_label.modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_number_label, "scale", Vector2(1.0, 1.0), 0.45)
	tween.parallel().tween_property(_number_label, "modulate:a", 1.0, 0.3)

	var i := 0
	for star in _stars_row.get_children():
		star.scale = Vector2(0.0, 0.0)
		var t := create_tween()
		t.tween_interval(0.12 + i * 0.06)
		t.set_trans(Tween.TRANS_BACK)
		t.set_ease(Tween.EASE_OUT)
		t.tween_property(star, "scale", Vector2(1.0, 1.0), 0.3)
		i += 1

func _replay_audio() -> void:
	AudioManager.play_sfx("button_listen")
	var entry := _current_entry()
	AudioManager.play_voice("numbers/" + str(entry.get("voice_number", "")))

func _go_previous() -> void:
	if _index == 0:
		return
	AudioManager.play_sfx("button_back")
	_index -= 1
	_show_number()

func _go_next() -> void:
	if _index == GameData.number_data.size() - 1:
		AudioManager.play_sfx("celebration")
		AudioManager.play_voice("common/wonderful")
		Navigation.go_to(NUMBER_MENU, false)
		return
	AudioManager.play_sfx("button_next")
	_index += 1
	_show_number()
