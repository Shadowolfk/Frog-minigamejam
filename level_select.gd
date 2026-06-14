extends MenuScreen


@export var button_size: Vector2 = Vector2(96, 96)

@onready var grid: GridContainer = $Center/VBox/Grid


func _ready() -> void:
	super._ready()
	_build()
	Levels.progress_changed.connect(_build)
	$Center/VBox/Back.pressed.connect(_on_cancel)


func _build() -> void:
	for c in grid.get_children():
		c.queue_free()
	for i in Levels.level_count():
		grid.add_child(_make_button(i))
	refresh_focusables.call_deferred()
	_refocus.call_deferred()


func _make_button(i: int) -> Button:
	var btn := Button.new()
	btn.text = str(i + 1)
	btn.custom_minimum_size = button_size
	btn.focus_mode = Control.FOCUS_ALL
	btn.disabled = not Levels.is_unlocked(i)

	var idx := i
	btn.pressed.connect(func() -> void:
		Levels.start_level(idx)
		get_tree().change_scene_to_file("res://game.tscn"))
	return btn


func _refocus() -> void:
	for c in grid.get_children():
		var b := c as Button
		if b != null and not b.is_queued_for_deletion() and not b.disabled:
			_focused = null
			b.grab_focus()
			return


func _on_cancel() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
