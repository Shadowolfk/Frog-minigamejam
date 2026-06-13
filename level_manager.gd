extends Node

const LEVEL_PATHS: Array[String] = [
	"res://levels/level_01.tscn",
	"res://levels/level_02.tscn",
	"res://levels/level_03.tscn",
]

const SAVE_PATH := "user://progress.cfg"

var current_index: int = 0
var max_unlocked: int = 0

signal progress_changed


func _ready() -> void:
	_load_progress()


func level_count() -> int:
	return LEVEL_PATHS.size()


func is_unlocked(i: int) -> bool:
	return i >= 0 and i < level_count() and i <= max_unlocked


func start_level(i: int) -> void:
	if is_unlocked(i):
		current_index = i


func current_scene() -> PackedScene:
	if current_index < 0 or current_index >= level_count():
		return null
	return load(LEVEL_PATHS[current_index]) as PackedScene


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
