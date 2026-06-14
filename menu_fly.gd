extends Node2D

## A decorative fly that buzzes around a menu. Click it (hit-tested by the owning
## MenuScreen) to eat it — the tongue lashes out and it pops with particles and a
## sound. Identified by the "menu_fly" group; no class_name so nothing depends on
## this script at compile time.

@export var speed: float = 95.0
@export var turn_rate: float = 3.0
@export var hit_radius: float = 28.0
@export var bounds_margin: float = 48.0

var _vel: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _eaten: bool = false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("menu_fly")
	_t = randf() * TAU
	_vel = Vector2.from_angle(randf() * TAU) * speed
	_pick_target()


func _pick_target() -> void:
	var vp := get_viewport().get_visible_rect().size
	_target = Vector2(
		randf_range(bounds_margin, vp.x - bounds_margin),
		randf_range(bounds_margin, vp.y - bounds_margin))


func _process(delta: float) -> void:
	if _eaten:
		return
	_t += delta

	var desired := _target - global_position
	if desired.length() < 36.0:
		_pick_target()
	var dir := desired.normalized()
	# buzzy perpendicular weave so it doesn't fly in straight lines
	var perp := Vector2(-dir.y, dir.x)
	var want := (dir + perp * sin(_t * 11.0) * 0.7).normalized() * speed
	_vel = _vel.lerp(want, clampf(turn_rate * delta, 0.0, 1.0))
	global_position += _vel * delta

	if _vel.length() > 1.0:
		_sprite.rotation = _vel.angle()
	# wing flap via a quick vertical squash
	_sprite.scale = Vector2(2.0, 2.0 * (0.78 + 0.22 * sin(_t * 42.0)))


func eat() -> void:
	if _eaten:
		return
	_eaten = true
	_spawn_particles()
	var u := get_node_or_null("/root/UiSound")
	if u:
		u.eat()
	queue_free()


func _spawn_particles() -> void:
	var at := global_position
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = 16
	p.lifetime = 0.55
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 70.0
	p.initial_velocity_max = 210.0
	p.gravity = Vector2(0, 340)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = Color(0.86, 0.95, 0.22)
	get_parent().add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.3).timeout.connect(p.queue_free)
