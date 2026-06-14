extends Node

## The level list lives in res://levels.cfg so the "Level Tool" editor plugin can
## add/reorder levels without touching code. DEFAULT_LEVELS is the fallback if the
## file is missing or empty.
const LEVELS_FILE := "res://levels.cfg"
const DEFAULT_LEVELS: Array[String] = [
	"res://levels/level_01.tscn",
	"res://levels/level_02.tscn",
	"res://levels/level_03.tscn",
]

const SAVE_PATH := "user://progress.cfg"

var levels: Array[String] = []
var current_index: int = 0
var max_unlocked: int = 0

signal progress_changed


func _ready() -> void:
	_load_levels()
	_load_progress()


func _load_levels() -> void:
	levels = []
	var c := ConfigFile.new()
	if c.load(LEVELS_FILE) == OK:
		var arr: Array = c.get_value("levels", "paths", [])
		for p in arr:
			levels.append(String(p))
	if levels.is_empty():
		levels = DEFAULT_LEVELS.duplicate()


func level_count() -> int:
	return levels.size()


func is_unlocked(i: int) -> bool:
	return i >= 0 and i < level_count() and i <= max_unlocked


func start_level(i: int) -> void:
	if is_unlocked(i):
		current_index = i


func current_scene() -> PackedScene:
	if current_index < 0 or current_index >= level_count():
		return null
	return load(levels[current_index]) as PackedScene


func complete_current() -> void:
	var next := current_index + 1
	if next < level_count() and next > max_unlocked:
		max_unlocked = next
		_save_progress()
	progress_changed.emit()


func advance_to_next() -> bool:
	if current_index + 1 < level_count():
		current_index += 1
		return true
	return false


func reset_progress() -> void:
	max_unlocked = 0
	current_index = 0
	_save_progress()
	progress_changed.emit()



func _save_progress() -> void:
	var c := ConfigFile.new()
	c.set_value("progress", "max_unlocked", max_unlocked)
	c.save(SAVE_PATH)


func _load_progress() -> void:
	var c := ConfigFile.new()
	if c.load(SAVE_PATH) == OK:
		max_unlocked = int(c.get_value("progress", "max_unlocked", 0))
