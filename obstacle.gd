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

@export_group("Facing")
@export var face_movement: bool = true

@export var art_offset_angle: float = 0.0

@export_range(0.05, 1.0) var face_smoothing: float = 1.0

var _origin: Vector2
var _time: float = 0.0
var _last_pos: Vector2         


func _ready() -> void:
	add_to_group("obstacle")
	_origin = position
	set_physics_process(type != Type.STATIC)
	if type == Type.ORBITAL:
		position = _origin + Vector2.from_angle(orbit_angle_start) * orbit_radius
	_last_pos = position
	$AnimatedSprite2D.play("default")


func _physics_process(delta: float) -> void:
	_time += delta
	# 1) move
	match type:
		Type.LINEAR:
			var dir := travel_direction.normalized()
			if dir.length_squared() == 0.0: return
			position = _origin + dir * travel_distance * sin(_time * travel_speed * TAU)
		Type.ORBITAL:
			var angle := orbit_angle_start + _time * orbit_speed * TAU
			position = _origin + Vector2.from_angle(angle) * orbit_radius

	if face_movement:
		var v := position - _last_pos
		if v.length_squared() > 0.0001:
			var target := v.angle() + art_offset_angle
			if face_smoothing >= 0.999:
				rotation = target
			else:
				rotation = lerp_angle(rotation, target, face_smoothing)
	_last_pos = position
