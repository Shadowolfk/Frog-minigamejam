extends Node2D


@export var win_delay: float = 1.2          

@onready var level_holder: Node2D = $LevelHolder

var _current_level: Node = null
var _won_this_run: bool = false


func _ready() -> void:
	_spawn_current_level()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://level_select.tscn")


func _spawn_current_level() -> void:

	if _current_level and is_instance_valid(_current_level):
		_current_level.queue_free()
		_current_level = null
	_won_this_run = false

	var ps := Levels.current_scene()
	if ps == null:
		get_tree().change_scene_to_file("res://level_select.tscn")
		return

	_current_level = ps.instantiate()
	level_holder.add_child(_current_level)


	var player := _current_level.find_child("Player", true, false)
	if player:
		var tongue := player.get_node_or_null("Tongue")
		if tongue and tongue.has_signal("caught"):
			tongue.caught.connect(_on_caught)
		if tongue and tongue.has_signal("reeled_in"):
			tongue.reeled_in.connect(_on_reeled_in)


func _on_caught(_node: Node) -> void:
	_won_this_run = true
	Levels.complete_current()


func _on_reeled_in() -> void:

	if not _won_this_run: return
	await get_tree().create_timer(win_delay).timeout
	if Levels.advance_to_next():
		_spawn_current_level()
		
	else:
		
		get_tree().change_scene_to_file("res://level_select.tscn")
