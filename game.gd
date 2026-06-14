extends Node2D

@export var win_delay: float = 0.5   

@onready var level_holder: Node2D = $LevelHolder
@onready var hud: CanvasLayer = $HUD
@export var color : Color
var _current_level: Node = null
var _won_this_run: bool = false
var _attempts_this_level: int = 0


func _ready() -> void:
	hud.continue_pressed.connect(_on_continue_pressed)
	hud.select_pressed.connect(_back_to_selector)
	_spawn_current_level()


func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("ui_cancel"):
		_back_to_selector()
		
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		$HUD/AnimatedSprite2D2.modulate = color
	else:
		$HUD/AnimatedSprite2D2.modulate = Color.WHITE
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		$HUD/AnimatedSprite2D.modulate = color
	else:
		$HUD/AnimatedSprite2D.modulate = Color.WHITE





func _spawn_current_level() -> void:
	Music.stop()
	if _current_level and is_instance_valid(_current_level):
		_current_level.queue_free()
		_current_level = null
	_won_this_run = false
	_attempts_this_level = 0
	
	var ps := Levels.current_scene()
	if ps == null:
		_back_to_selector()
		return

	_current_level = ps.instantiate()
	level_holder.add_child(_current_level)

	hud.set_level(Levels.current_index + 1)
	hud.set_attempts(0)
	hud.hide_completion()
	get_tree().paused = false

	
	var player := _current_level.find_child("Player", true, false)
	if player:
		var tongue := player.get_node_or_null("Tongue")
		if tongue:
			tongue.caught.connect(_on_caught)
			tongue.reeled_in.connect(_on_reeled_in)
			tongue.launched.connect(_on_launched)



func _on_launched() -> void:

	_attempts_this_level += 1
	hud.set_attempts(_attempts_this_level)


func _on_caught(_node: Node) -> void:
	_won_this_run = true
	Levels.complete_current()


func _on_reeled_in() -> void:
	if not _won_this_run: return
	await get_tree().create_timer(win_delay).timeout
	var has_next := Levels.current_index + 1 < Levels.level_count()
	hud.show_completion(_attempts_this_level, has_next)
	get_tree().paused = true



func _on_continue_pressed() -> void:
	get_tree().paused = false
	if Levels.advance_to_next():
		_spawn_current_level()
	else:
		_back_to_selector()


func _back_to_selector() -> void:
	get_tree().paused = false
	var m : AudioStream = preload("res://Lilyjam (Title Theme).mp3")
	Music.play(m)
	get_tree().change_scene_to_file("res://level_select.tscn")
