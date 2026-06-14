extends Node2D

@export_group("Wander")
@export var wander_radius: float = 18.0           
@export var dart_speed: float = 110.0            
@export_range(0.05, 3.0) var pause_min: float = 0.18
@export_range(0.05, 3.0) var pause_max: float = 0.9
@export_range(0.0, 90.0) var dart_tilt_degrees: float = 25.0   

@export_group("Wings")
@export var wing_frequency: float = 12.0          
@export_range(0.0, 0.5) var wing_squish: float = 0.18  

var _origin: Vector2
var _target: Vector2
var _wait: float = 0.0
var _t: float = 0.0
var _base_scale: Vector2
var _caught: bool = false


func _ready() -> void:
	add_to_group("catchable")
	_origin = position
	_target = position
	_base_scale = scale       
	_pick_new_target()


func _process(delta: float) -> void:
	_t += delta
	_wing_beat()
	_settle_rotation(delta)

	if not _caught:
		_wander(delta)


func _wing_beat() -> void:

	var s := sin(_t * wing_frequency * TAU) * 0.5 + 0.5   # 0..1
	scale.y = _base_scale.y * (1.0 - wing_squish * s)
	scale.x = _base_scale.x * (1.0 + wing_squish * s * 0.6)


func _wander(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		return
	var to_target := _target - position
	var d := to_target.length()
	if d < 1.5:
		_wait = randf_range(pause_min, pause_max)
		_pick_new_target()
		return

	var dart_angle := to_target.angle() + PI / 2.0
	var max_tilt := deg_to_rad(dart_tilt_degrees)
	var target_rotation := clampf(dart_angle, -max_tilt, max_tilt)
	rotation = lerp_angle(rotation, target_rotation, 6.0 * delta)

	position += to_target.normalized() * minf(d, dart_speed * delta)


func _pick_new_target() -> void:
	_target = _origin + Vector2.from_angle(randf() * TAU) * randf_range(0.0, wander_radius)


func on_caught() -> void:
	_caught = true
	
func _settle_rotation(delta: float) -> void:
	if _wait > 0.0:
		rotation = lerp_angle(rotation, 0.0, 4.0 * delta)
