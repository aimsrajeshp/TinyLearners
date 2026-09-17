extends Node
## Autoloaded audio manager: music, SFX and voice playback with ducking.
## Sound files are optional during early development - missing files are
## skipped silently so the rest of the game keeps working.

const SFX_DIR := "res://audio/sfx/"
const VOICE_DIR := "res://audio/voice/en/"
const MUSIC_DIR := "res://audio/music/"

const DUCK_VOLUME_DB := -12.0
const DUCK_TIME := 0.2

var music_on: bool = true
var sfx_on: bool = true
var voice_on: bool = true

@onready var _music_player: AudioStreamPlayer = _make_player("Music")
@onready var _voice_player: AudioStreamPlayer = _make_player("Voice")
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 6

func _ready() -> void:
	for i in SFX_POOL_SIZE:
		_sfx_players.append(_make_player("SFX"))
	_voice_player.finished.connect(_on_voice_finished)

func _make_player(bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	return player

func _find_resource(base_path: String) -> String:
	var extensions: PackedStringArray = [".ogg", ".wav"]
	for ext in extensions:
		var path: String = base_path + ext
		if ResourceLoader.exists(path):
			return path
	return ""

func play_music(track_name: String, loop: bool = true) -> void:
	if not music_on:
		return
	var path := _find_resource(MUSIC_DIR + track_name)
	if path.is_empty():
		return
	_music_player.stream = load(path)
	_music_player.volume_db = 0.0
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func play_sfx(sfx_name: String) -> void:
	if not sfx_on:
		return
	var path := _find_resource(SFX_DIR + sfx_name)
	if path.is_empty():
		return
	var player := _get_free_sfx_player()
	player.stream = load(path)
	player.play()

func play_voice(voice_name: String) -> void:
	if not voice_on:
		return
	var path := _find_resource(VOICE_DIR + voice_name)
	if path.is_empty():
		return
	_duck_music(true)
	_voice_player.stream = load(path)
	_voice_player.play()

func _on_voice_finished() -> void:
	_duck_music(false)

func _duck_music(duck: bool) -> void:
	var target_db := DUCK_VOLUME_DB if duck else 0.0
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", target_db, DUCK_TIME)

func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	return _sfx_players[0]

func set_music_enabled(enabled: bool) -> void:
	music_on = enabled
	if not enabled:
		stop_music()

func set_sfx_enabled(enabled: bool) -> void:
	sfx_on = enabled

func set_voice_enabled(enabled: bool) -> void:
	voice_on = enabled
	if not enabled:
		_voice_player.stop()
