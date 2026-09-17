extends Control

@onready var _music_toggle: Button = $Scroll/Center/Panel/VBox/MusicRow/MusicToggle
@onready var _sfx_toggle: Button = $Scroll/Center/Panel/VBox/SfxRow/SfxToggle
@onready var _voice_toggle: Button = $Scroll/Center/Panel/VBox/VoiceRow/VoiceToggle

@onready var _music_slider: HSlider = $Scroll/Center/Panel/VBox/MusicSliderRow/MusicSlider
@onready var _sfx_slider: HSlider = $Scroll/Center/Panel/VBox/SfxSliderRow/SfxSlider
@onready var _voice_slider: HSlider = $Scroll/Center/Panel/VBox/VoiceSliderRow/VoiceSlider

@onready var _reset_button: Button = $Scroll/Center/Panel/VBox/ResetButton
@onready var _back_button: Button = $BackButton
@onready var _confirm_dialog: ConfirmationDialog = $ConfirmResetDialog

func _ready() -> void:
	_music_toggle.button_pressed = AudioManager.music_on
	_sfx_toggle.button_pressed = AudioManager.sfx_on
	_voice_toggle.button_pressed = AudioManager.voice_on
	_music_slider.value = AudioManager.music_volume
	_sfx_slider.value = AudioManager.sfx_volume
	_voice_slider.value = AudioManager.voice_volume
	_refresh_toggle_look(_music_toggle, "🎵 Music")
	_refresh_toggle_look(_sfx_toggle, "🔊 Effects")
	_refresh_toggle_look(_voice_toggle, "🎙️ Voice")
	_refresh_slider_state()

	_music_toggle.toggled.connect(func(on):
		AudioManager.set_music_enabled(on)
		_refresh_toggle_look(_music_toggle, "🎵 Music")
		_refresh_slider_state()
		AudioManager.play_sfx("button_tap"))
	_sfx_toggle.toggled.connect(func(on):
		AudioManager.set_sfx_enabled(on)
		_refresh_toggle_look(_sfx_toggle, "🔊 Effects")
		_refresh_slider_state()
		AudioManager.play_sfx("button_tap"))
	_voice_toggle.toggled.connect(func(on):
		AudioManager.set_voice_enabled(on)
		_refresh_toggle_look(_voice_toggle, "🎙️ Voice")
		_refresh_slider_state())

	_music_slider.value_changed.connect(AudioManager.set_music_volume)
	_sfx_slider.value_changed.connect(func(v):
		AudioManager.set_sfx_volume(v))
	_voice_slider.value_changed.connect(AudioManager.set_voice_volume)
	_sfx_slider.drag_ended.connect(func(_moved): AudioManager.play_sfx("button_tap"))

	_reset_button.pressed.connect(func():
		AudioManager.play_sfx("button_tap")
		_confirm_dialog.popup_centered())
	_confirm_dialog.confirmed.connect(func():
		GameData.reset_progress()
		AudioManager.play_sfx("celebration"))
	_back_button.pressed.connect(func(): Navigation.go_home())

func _refresh_toggle_look(button: Button, label: String) -> void:
	if button.button_pressed:
		button.text = "%s: ON" % label
		button.theme_type_variation = &"MenuButtonGreen"
	else:
		button.text = "%s: OFF" % label
		button.theme_type_variation = &"MenuButtonGray"

func _refresh_slider_state() -> void:
	_music_slider.editable = AudioManager.music_on
	_sfx_slider.editable = AudioManager.sfx_on
	_voice_slider.editable = AudioManager.voice_on
	_music_slider.modulate.a = 1.0 if AudioManager.music_on else 0.4
	_sfx_slider.modulate.a = 1.0 if AudioManager.sfx_on else 0.4
	_voice_slider.modulate.a = 1.0 if AudioManager.voice_on else 0.4
