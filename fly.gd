extends Node2D




func _ready() -> void:
	add_to_group("catchable")


func _process(_delta: float) -> void:
	pass


func on_caught() -> void:
	set_physics_process(false)
