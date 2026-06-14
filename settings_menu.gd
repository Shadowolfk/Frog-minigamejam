extends MenuScreen


func _ready() -> void:
	super._ready()
	_setup_row("Master", $Center/VBox/Master/Slider, $Center/VBox/Master/Value)
	_setup_row("Music", $Center/VBox/Music/Slider, $Center/VBox/Music/Value)
	_setup_row("SFX", $Center/VBox/SFX/Slider, $Center/VBox/SFX/Value)
	$Center/VBox/Back.pressed.connect(_on_cancel)


func _setup_row(bus: String, slider: HSlider, value_label: Label) -> void:
	var settings := get_node("/root/Settings")
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = settings.get_volume(bus)
	value_label.text = "%d%%" % roundi(slider.value * 100.0)
	slider.value_changed.connect(func(v: float) -> void:
		settings.set_volume(bus, v)
		value_label.text = "%d%%" % roundi(v * 100.0))


func _on_cancel() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
