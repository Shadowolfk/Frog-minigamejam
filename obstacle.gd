extends Node2D


@export var obstacle_radius: float = 48.0



func _ready() -> void:
	add_to_group("obstacle")
