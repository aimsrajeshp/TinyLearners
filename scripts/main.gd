extends Node2D
## App entry point: shows the Tiny Learners splash briefly, then opens Home.

const HOME_SCENE := "res://scenes/home/Home.tscn"
const SPLASH_HOLD_TIME := 1.4

@onready var _logo: TextureRect = $CenterContainer/Logo

func _ready() -> void:
	AudioManager.play_voice("common/welcome")
	_logo.scale = Vector2(0.7, 0.7)
	_logo.modulate.a = 0.0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(_logo, "scale", Vector2(1.0, 1.0), 0.5)
	tween.parallel().tween_property(_logo, "modulate:a", 1.0, 0.4)
	tween.tween_interval(SPLASH_HOLD_TIME)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(HOME_SCENE)
	)
