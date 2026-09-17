extends Control

@onready var _music_toggle: CheckButton = $Panel/VBox/MusicRow/MusicToggle
@onready var _sfx_toggle: CheckButton = $Panel/VBox/SfxRow/SfxToggle
@onready var _voice_toggle: CheckButton = $Panel/VBox/VoiceRow/VoiceToggle
@onready var _reset_button: Button = $Panel/VBox/ResetButton
@onready var _back_button: Button = $Panel/VBox/BackButton
@onready var _confirm_dialog: ConfirmationDialog = $ConfirmResetDialog

func _ready() -> void:
	_music_toggle.button_pressed = AudioManager.music_on
	_sfx_toggle.button_pressed = AudioManager.sfx_on
	_voice_toggle.button_pressed = AudioManager.voice_on

	_music_toggle.toggled.connect(AudioManager.set_music_enabled)
	_sfx_toggle.toggled.connect(AudioManager.set_sfx_enabled)
	_voice_toggle.toggled.connect(AudioManager.set_voice_enabled)

	_reset_button.pressed.connect(func(): _confirm_dialog.popup_centered())
	_confirm_dialog.confirmed.connect(func(): GameData.reset_progress())
	_back_button.pressed.connect(func(): Navigation.go_home())
