extends Control


@export var texture_normal:   Texture2D
@export var texture_pressed:  Texture2D
@export var texture_hover:    Texture2D
@export var texture_disabled: Texture2D

@export var button_size: Vector2 = Vector2(80, 80)
@export var label_font_size: int = 28
@export var label_color: Color = Color.WHITE
@export var font : FontFile
@export_range(0.0, 1.0) var locked_dim: float = 0.4  

@onready var grid: GridContainer = $Center/VBox/Grid


func _ready() -> void:
	_build()
	Levels.progress_changed.connect(_build)
	


func _build() -> void:
	for c in grid.get_children():
		c.queue_free()
	for i in Levels.level_count():
		grid.add_child(_make_button(i))


func _make_button(i: int) -> TextureButton:
	var btn := TextureButton.new()
	btn.texture_normal   = texture_normal
	btn.texture_pressed  = texture_pressed
	btn.texture_hover    = texture_hover
	btn.texture_disabled = texture_disabled


	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.custom_minimum_size = button_size
	btn.disabled = not Levels.is_unlocked(i)

	
	var label := Label.new()
	label.text = str(i + 1)
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", label_font_size)
	label.add_theme_color_override("font_color", label_color)
	label.add_theme_font_override("font", font)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if btn.disabled:
		label.modulate.a = locked_dim
	btn.add_child(label)

	var idx := i
	btn.pressed.connect(func ():
		Levels.start_level(idx)
		get_tree().change_scene_to_file("res://game.tscn"))
	return btn
