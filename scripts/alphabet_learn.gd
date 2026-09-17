extends Control

const ALPHABET_MENU := "res://scenes/alphabet/AlphabetMenu.tscn"

@onready var _letter_label: Label = $Content/LetterLabel
@onready var _emoji_label: Label = $Content/EmojiLabel
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
	_show_letter()

func _current_entry() -> Dictionary:
	return GameData.alphabet_data[_index]

func _show_letter() -> void:
	var entry := _current_entry()
	_letter_label.text = entry.get("letter", "?")
	_emoji_label.text = entry.get("emoji", "")
	_word_label.text = "%s is for %s" % [entry.get("letter", "?"), entry.get("word", "")]

	_prev_button.disabled = _index == 0
	_next_button.text = "Finish ✓" if _index == GameData.alphabet_data.size() - 1 else "Next →"

	AudioManager.play_sfx("letter_reveal")
	_animate_reveal()
	GameData.mark_alphabet_complete(entry.get("letter", ""))
	_replay_audio()

func _animate_reveal() -> void:
	_letter_label.scale = Vector2(0.4, 0.4)
	_letter_label.modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_letter_label, "scale", Vector2(1.0, 1.0), 0.45)
	tween.parallel().tween_property(_letter_label, "modulate:a", 1.0, 0.3)

	_emoji_label.scale = Vector2(0.4, 0.4)
	var tween2 := create_tween()
	tween2.tween_interval(0.15)
	tween2.set_trans(Tween.TRANS_BACK)
	tween2.set_ease(Tween.EASE_OUT)
	tween2.tween_property(_emoji_label, "scale", Vector2(1.0, 1.0), 0.4)

func _replay_audio() -> void:
	AudioManager.play_sfx("button_listen")
	var entry := _current_entry()
	AudioManager.play_voice("alphabet/" + entry.get("voice_letter", ""))
	var timer := get_tree().create_timer(0.7)
	timer.timeout.connect(func():
		AudioManager.play_voice("alphabet/" + entry.get("voice_word", ""))
	)

func _go_previous() -> void:
	if _index == 0:
		return
	AudioManager.play_sfx("button_back")
	_index -= 1
	_show_letter()

func _go_next() -> void:
	if _index == GameData.alphabet_data.size() - 1:
		AudioManager.play_sfx("celebration")
		AudioManager.play_voice("common/wonderful")
		Navigation.go_to(ALPHABET_MENU, false)
		return
	AudioManager.play_sfx("button_next")
	_index += 1
	_show_letter()
