extends Node
## Autoloaded audio manager: music, SFX and voice playback with ducking,
## per-channel volume (backed by the Music/SFX/Voice audio buses) and
## settings persistence. Sound files are optional during development -
## missing files are skipped silently so the rest of the game keeps working.

const SFX_DIR := "res://audio/sfx/"
const VOICE_DIR := "res://audio/voice/en/"
const MUSIC_DIR := "res://audio/music/"
const SETTINGS_PATH := "user://tiny_learners_audio.save"

const DUCK_OFFSET_DB := -14.0
const DUCK_TIME := 0.2
const MIN_DB := -40.0

var music_on: bool = true
var sfx_on: bool = true
var voice_on: bool = true

var music_volume: float = 0.8
var sfx_volume: float = 1.0
var voice_volume: float = 1.0

var _music_bus_idx: int
var _sfx_bus_idx: int
var _voice_bus_idx: int
var _duck_tween: Tween

@onready var _music_player: AudioStreamPlayer = _make_player("Music")
@onready var _voice_player: AudioStreamPlayer = _make_player("Voice")
@onready var _loop_player: AudioStreamPlayer = _make_player("SFX")
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 6

func _ready() -> void:
	_music_bus_idx = AudioServer.get_bus_index("Music")
	_sfx_bus_idx = AudioServer.get_bus_index("SFX")
	_voice_bus_idx = AudioServer.get_bus_index("Voice")
	for i in SFX_POOL_SIZE:
		_sfx_players.append(_make_player("SFX"))
	_voice_player.finished.connect(_on_voice_finished)
	_load_settings()
	_apply_all_volumes()

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

func _volume_to_db(v: float) -> float:
	if v <= 0.0:
		return MIN_DB
	return lerp(MIN_DB, 0.0, v)

func play_music(track_name: String, loop: bool = true) -> void:
	if not music_on:
		return
	var path := _find_resource(MUSIC_DIR + track_name)
	if path.is_empty():
		return
	_music_player.stream = load(path)
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

func start_looping_sfx(sfx_name: String) -> void:
	if not sfx_on:
		return
	if _loop_player.playing:
		return
	var path := _find_resource(SFX_DIR + sfx_name)
	if path.is_empty():
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamOggVorbis:
		stream.loop = true
	_loop_player.stream = stream
	_loop_player.play()

func stop_looping_sfx() -> void:
	_loop_player.stop()

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
	var base_db := _volume_to_db(music_volume)
	var target_db := base_db + DUCK_OFFSET_DB if duck else base_db
	if _duck_tween:
		_duck_tween.kill()
	var from_db := AudioServer.get_bus_volume_db(_music_bus_idx)
	_duck_tween = create_tween()
	_duck_tween.tween_method(func(db): AudioServer.set_bus_volume_db(_music_bus_idx, db), from_db, target_db, DUCK_TIME)

func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	return _sfx_players[0]

func set_music_enabled(enabled: bool) -> void:
	music_on = enabled
	AudioServer.set_bus_mute(_music_bus_idx, not enabled)
	if not enabled:
		stop_music()
	_save_settings()

func set_sfx_enabled(enabled: bool) -> void:
	sfx_on = enabled
	AudioServer.set_bus_mute(_sfx_bus_idx, not enabled)
	_save_settings()

func set_voice_enabled(enabled: bool) -> void:
	voice_on = enabled
	AudioServer.set_bus_mute(_voice_bus_idx, not enabled)
	if not enabled:
		_voice_player.stop()
	_save_settings()

func set_music_volume(v: float) -> void:
	music_volume = clamp(v, 0.0, 1.0)
	AudioServer.set_bus_volume_db(_music_bus_idx, _volume_to_db(music_volume))
	_save_settings()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clamp(v, 0.0, 1.0)
	AudioServer.set_bus_volume_db(_sfx_bus_idx, _volume_to_db(sfx_volume))
	_save_settings()

func set_voice_volume(v: float) -> void:
	voice_volume = clamp(v, 0.0, 1.0)
	AudioServer.set_bus_volume_db(_voice_bus_idx, _volume_to_db(voice_volume))
	_save_settings()

func _apply_all_volumes() -> void:
	AudioServer.set_bus_volume_db(_music_bus_idx, _volume_to_db(music_volume))
	AudioServer.set_bus_volume_db(_sfx_bus_idx, _volume_to_db(sfx_volume))
	AudioServer.set_bus_volume_db(_voice_bus_idx, _volume_to_db(voice_volume))
	AudioServer.set_bus_mute(_music_bus_idx, not music_on)
	AudioServer.set_bus_mute(_sfx_bus_idx, not sfx_on)
	AudioServer.set_bus_mute(_voice_bus_idx, not voice_on)

func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_var({
		"music_on": music_on, "sfx_on": sfx_on, "voice_on": voice_on,
		"music_volume": music_volume, "sfx_volume": sfx_volume, "voice_volume": voice_volume,
	})

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var data = file.get_var()
	if typeof(data) != TYPE_DICTIONARY:
		return
	music_on = data.get("music_on", true)
	sfx_on = data.get("sfx_on", true)
	voice_on = data.get("voice_on", true)
	music_volume = data.get("music_volume", 0.8)
	sfx_volume = data.get("sfx_volume", 1.0)
	voice_volume = data.get("voice_volume", 1.0)
