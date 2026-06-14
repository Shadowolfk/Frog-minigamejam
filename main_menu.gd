extends MenuScreen


func _ready() -> void:
	super._ready()
	$Center/VBox/Play.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://game.tscn"))
	$Center/VBox/Levels.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://level_select.tscn"))
	$Center/VBox/Settings.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://settings.tscn"))
	$Center/VBox/Quit.pressed.connect(func() -> void:
		get_tree().quit())
