extends MenuScreen


@export var menu_music: AudioStream   # drag your music file into this slot in the inspector

func _ready() -> void:
	super._ready()
	Music.play(menu_music)
	$Center/VBox/Play.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://game.tscn")
		Music.stop()
		)
		
	$Center/VBox/Levels.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://level_select.tscn"))
	$Center/VBox/Settings.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://settings.tscn"))
	$Center/VBox/Quit.pressed.connect(func() -> void:
		get_tree().quit())
