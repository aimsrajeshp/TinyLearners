extends Control
## App entry point: shows a simple loading screen with a progress bar,
## then opens Home. Kept deliberately simple (no fancy positioning) since
## this is the very first thing a player sees.

const HOME_SCENE := "res://scenes/home/Home.tscn"
const LOAD_TIME := 1.3

@onready var _progress_bar: ProgressBar = $Content/ProgressBar

func _ready() -> void:
	AudioManager.play_voice("common/welcome")
	_progress_bar.value = 0
	var tween := create_tween()
	tween.tween_property(_progress_bar, "value", 100.0, LOAD_TIME)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(HOME_SCENE)
	)
