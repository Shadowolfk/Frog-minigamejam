extends Node2D


enum Type { STATIC, LINEAR, ORBITAL }

@export var type: Type = Type.STATIC
@export var obstacle_radius: float = 48.0

@export_group("Linear")

@export var travel_direction: Vector2 = Vector2(1, 0)

@export var travel_distance: float = 120.0

@export var travel_speed: float = 0.5

@export_group("Orbital")
@export var orbit_radius: float = 120.0

@export var orbit_speed: float = 0.25

@export var orbit_angle_start: float = 0.0

var _origin: Vector2
var _time: float = 0.0


func _ready() -> void:
	add_to_group("obstacle")
	_origin = position
	
	set_physics_process(type != Type.STATIC)
	
	if type == Type.ORBITAL:
		position = _origin + Vector2.from_angle(orbit_angle_start) * orbit_radius


func _physics_process(delta: float) -> void:
	_time += delta
	match type:
		Type.LINEAR:
			var dir := travel_direction.normalized()
			if dir.length_squared() == 0.0: return
			position = _origin + dir * travel_distance * sin(_time * travel_speed * TAU)
		Type.ORBITAL:
			var angle := orbit_angle_start + _time * orbit_speed * TAU
			position = _origin + Vector2.from_angle(angle) * orbit_radius
