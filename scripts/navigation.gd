extends Node
## Handles scene switching with a small fade transition, the Android
## hardware back button, and quitting.

const HOME_SCENE := "res://scenes/home/Home.tscn"

var _history: Array[String] = []
var _transition_layer: CanvasLayer
var _fade_rect: ColorRect
var _quit_dialog: ConfirmationDialog

func _ready() -> void:
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 100
	get_tree().root.call_deferred("add_child", _transition_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_layer.call_deferred("add_child", _fade_rect)

	_quit_dialog = ConfirmationDialog.new()
	_quit_dialog.title = "Leave Tiny Learners?"
	_quit_dialog.dialog_text = "Do you want to close the app?"
	_quit_dialog.confirmed.connect(func(): get_tree().quit())
	_transition_layer.call_deferred("add_child", _quit_dialog)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		var current_scene := get_tree().current_scene
		var path := current_scene.scene_file_path if current_scene else ""
		if path == HOME_SCENE:
			request_quit()
		else:
			go_home()

func request_quit() -> void:
	AudioManager.play_sfx("button_tap")
	_quit_dialog.popup_centered()

func go_to(scene_path: String, remember: bool = true) -> void:
	if remember:
		var current_scene := get_tree().current_scene
		if current_scene:
			_history.append(current_scene.scene_file_path)
	AudioManager.play_sfx("button_tap")
	_fade_to(scene_path)

func go_home() -> void:
	_history.clear()
	AudioManager.play_sfx("button_back")
	_fade_to(HOME_SCENE)

func go_back() -> void:
	AudioManager.play_sfx("button_back")
	if _history.is_empty():
		_fade_to(HOME_SCENE)
	else:
		_fade_to(_history.pop_back())

func _fade_to(scene_path: String) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, 0.15)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(scene_path)
	)
	tween.tween_property(_fade_rect, "color:a", 0.0, 0.15)
