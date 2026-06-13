extends Control


@onready var grid: GridContainer = $Center/VBox/Grid


func _ready() -> void:
	_build()
	Levels.progress_changed.connect(_build)


func _build() -> void:
	for c in grid.get_children():
		c.queue_free()
	for i in Levels.level_count():
		var btn := Button.new()
		btn.text = str(i + 1)
		btn.custom_minimum_size = Vector2(80, 80)
		btn.add_theme_font_size_override("font_size", 28)
		btn.disabled = not Levels.is_unlocked(i)
		var idx = i  
		btn.pressed.connect(func ():
			Levels.start_level(idx)
			get_tree().change_scene_to_file("res://game.tscn"))
		grid.add_child(btn)
