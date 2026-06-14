extends Node2D
class_name MenuTongue

## A decorative, living frog tongue for menus. It reaches from this node's
## position (the frog's mouth) to a target point — used to "select" buttons
## and sliders by touching them.

@export_category("Looks")
@export var width_base: float = 13.0
@export var width_tip: float = 5.0
@export var color: Color = Color(0.85098039, 0.34117648, 0.38823529)
@export var color_core: Color = Color(0.64239782, 0.21280804, 0.26131088)
@export var segments: int = 30

@export_category("Motion")
@export var follow_speed: float = 15.0   ## how fast the tip chases the target
@export var bow: float = 38.0            ## sideways arc of the path
@export var wave_amp: float = 8.0        ## travelling ripple amplitude
@export var wave_freq: float = 2.4       ## ripples along the length
@export var wave_speed: float = 4.5      ## ripple travel speed
@export var extend_speed: float = 5.0    ## extend / retract rate

var _tip: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _has_target: bool = false
var _extend: float = 0.0
var _t: float = 0.0
var _active_speed: float = follow_speed


func _ready() -> void:
	_tip = global_position
	_target = global_position
	_active_speed = follow_speed


## Aim the tongue at a global point. Pass a custom chase speed (e.g. a faster one
## while tracking the mouse) or leave it for the default sweep speed.
func set_target_global(p: Vector2, speed: float = -1.0) -> void:
	_target = p
	_has_target = true
	_active_speed = speed if speed > 0.0 else follow_speed


func clear_target() -> void:
	_has_target = false
	_active_speed = follow_speed


func _process(delta: float) -> void:
	_t += delta
	var goal := _target if _has_target else global_position
	_tip = _tip.lerp(goal, clampf(_active_speed * delta, 0.0, 1.0))
	_extend = move_toward(_extend, 1.0 if _has_target else 0.0, extend_speed * delta)
	queue_redraw()


func _draw() -> void:
	var a := Vector2.ZERO
	var b := to_local(_tip)
	var dist := a.distance_to(b)
	if dist < 4.0 or _extend < 0.02:
		draw_circle(a, width_base * 0.5, color)
		return

	var dir := (b - a) / dist
	var perp := Vector2(-dir.y, dir.x)

	var pts := PackedVector2Array()
	for i in segments + 1:
		var t := float(i) / float(segments)
		var base := a.lerp(b, t)
		var env := sin(t * PI)                       # 0 at both ends, 1 in the middle
		var bow_off := env * bow
		var wave := sin(t * wave_freq * TAU - _t * wave_speed) * wave_amp * env
		pts.append(base + perp * (bow_off + wave) * _extend)

	# soft outer body
	for i in segments:
		var tt := float(i) / float(segments)
		var w := lerpf(width_base, width_tip, tt)
		draw_line(pts[i], pts[i + 1], color, w)
		draw_circle(pts[i + 1], w * 0.5, color)
	# darker core
	for i in segments:
		var tt := float(i) / float(segments)
		var w := lerpf(width_base * 0.45, width_tip * 0.45, tt)
		draw_line(pts[i], pts[i + 1], color_core, w)

	# rounded tip with a little highlight
	draw_circle(pts[segments], width_tip + 3.0, color)
	draw_circle(pts[segments] + Vector2(-2, -2), 2.5, Color(1, 1, 1, 0.5))
