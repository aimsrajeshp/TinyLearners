extends Node
## Global color palette, fonts, and shared constants for Tiny Learners.

const SKY_BLUE := Color("#65C7F7")
const SUNNY_YELLOW := Color("#FFD95A")
const SOFT_ORANGE := Color("#FF9F68")
const FRIENDLY_GREEN := Color("#75D681")
const PLAYFUL_PURPLE := Color("#A78BFA")
const PINK := Color("#FF8FAB")
const CREAM_BACKGROUND := Color("#FFF8E8")
const DARK_NAVY_TEXT := Color("#26324A")

const MENU_COLORS := [SKY_BLUE, SUNNY_YELLOW, SOFT_ORANGE, FRIENDLY_GREEN]

const SAVE_PATH := "user://tiny_learners_progress.save"
const ALPHABET_DATA_PATH := "res://data/alphabet.json"
const NUMBER_DATA_PATH := "res://data/numbers.json"
const TRACE_DATA_PATH := "res://data/trace_paths.json"

var alphabet_progress: Dictionary = {}
var number_progress: Dictionary = {}
var alphabet_trace_progress: Dictionary = {}
var number_trace_progress: Dictionary = {}

## Set by a menu screen just before navigating to a detail screen, since
## change_scene_to_file cannot pass arguments directly.
var selected_index: int = 0

var alphabet_data: Array = []
var number_data: Array = []
var trace_paths: Dictionary = {}

func _ready() -> void:
	load_progress()
	alphabet_data = _load_json_array(ALPHABET_DATA_PATH)
	number_data = _load_json_array(NUMBER_DATA_PATH)
	trace_paths = _load_json_dict(TRACE_DATA_PATH)

func _load_json_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	var result = JSON.parse_string(text)
	return result if typeof(result) == TYPE_ARRAY else []

func _load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	var result = JSON.parse_string(text)
	return result if typeof(result) == TYPE_DICTIONARY else {}

func mark_alphabet_complete(letter: String) -> void:
	alphabet_progress[letter] = true
	save_progress()

func mark_number_complete(number) -> void:
	number_progress[str(number)] = true
	save_progress()

func mark_alphabet_traced(letter: String) -> void:
	alphabet_trace_progress[letter] = true
	save_progress()

func mark_number_traced(number) -> void:
	number_trace_progress[str(number)] = true
	save_progress()

func save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_var({
		"alphabet": alphabet_progress,
		"numbers": number_progress,
		"alphabet_trace": alphabet_trace_progress,
		"number_trace": number_trace_progress,
	})

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data = file.get_var()
	if typeof(data) == TYPE_DICTIONARY:
		alphabet_progress = data.get("alphabet", {})
		number_progress = data.get("numbers", {})
		alphabet_trace_progress = data.get("alphabet_trace", {})
		number_trace_progress = data.get("number_trace", {})

func reset_progress() -> void:
	alphabet_progress.clear()
	number_progress.clear()
	alphabet_trace_progress.clear()
	number_trace_progress.clear()
	save_progress()
