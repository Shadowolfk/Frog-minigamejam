extends Node2D
class_name Tongue



@export var segments: int = 20
@export var max_length: float = 1200.0
@export var head_speed: float = 1100.0         
@export_range(0.0, 1.0) var body_follow: float = 0.85  
@export var retract_speed: float = 1800.0
@export var stiffness: int = 8
@export var wiggle: float = 6.0                 
@export var wiggle_speed: float = 9.0           
@export var gravity: Vector2 = Vector2.ZERO

@export_group("Detection")
@export var grab_radius: float = 22.0            
@export var obstacle_radius: float = 18.0    

@export_group("Look")
@export var width_base: float = 14.0
@export var width_tip: float = 5.0
@export var color: Color = Color("d74a89ff")
@export var color_core: Color = Color("c7075bff")

enum State { IDLE, OUT, IN }

var state: int = State.IDLE
var _pts: PackedVector2Array
var _prev: PackedVector2Array
var _dir: Vector2 = Vector2.UP
var _len: float = 0.0
var _age: float = 0.0          
var _agitation: float = 0.0   
var _caught: Array = []

signal caught(node)     
signal blocked(node)    
signal returned        


func _ready() -> void:
	_pts.resize(segments + 1)
	_prev.resize(segments + 1)
	_reset_to_anchor()


func is_idle() -> bool:
	return state == State.IDLE


func tip() -> Vector2:
	return _pts[segments]


func fire(target: Vector2) -> void:
	if state != State.IDLE:
		return
	var a := global_position
	_dir = target - a
	_dir = Vector2.UP if _dir.length() < 0.001 else _dir.normalized()
	state = State.OUT
	_len = 0.0
	_age = 0.0
	_agitation = 0.0
	_caught.clear()
	_reset_to_anchor()  


func retract() -> void:
	if state == State.OUT:
		state = State.IN


func _physics_process(delta: float) -> void:
	_age += delta
	var anchor := global_position

	if state == State.IDLE:
		_reset_to_anchor()
		queue_redraw()
		return

	if state == State.OUT:
		
		var head := _pts[segments]
		var to_aim := get_global_mouse_position() - head
		var step := to_aim.limit_length(head_speed * delta)
		var budget := max_length - _len
		if step.length() > budget:
			step = step.normalized() * budget
		head += step
		_len += step.length()
		_pts[segments] = head

		var drive := step.length() / maxf(head_speed * delta, 0.0001)
		_agitation = lerpf(_agitation, clampf(drive, 0.0, 1.0), 0.2)
		_check_tip()   
	elif state == State.IN:
		_len -= retract_speed * delta
		_agitation = lerpf(_agitation, 0.0, 0.1)
		if _len <= 4.0:
			_finish()
			return

	if _len < 0.001:
		queue_redraw()
		return
	var seg_len := _len / float(segments)

	for i in range(1, segments):
		var cur := _pts[i]
		var vel := (cur - _prev[i]) * 0.9
		_prev[i] = cur
		_pts[i] = cur + vel + gravity * delta * delta
	_prev[0] = anchor
	_prev[segments] = _pts[segments]

	for _pass in stiffness:
		# drag
		for i in range(segments - 1, 0, -1):
			var ahead := _pts[i + 1]
			var d := _pts[i] - ahead
			if d.length() < 0.0001:
				d = anchor - ahead
			var target := ahead + d.normalized() * seg_len
			_pts[i] = _pts[i].lerp(target, body_follow)
		# anchor
		_pts[0] = anchor
		for i in range(1, segments + 1):
			var behind := _pts[i - 1]
			var d := _pts[i] - behind
			if d.length() < 0.0001:
				d = _dir
			var target := behind + d.normalized() * seg_len
			_pts[i] = _pts[i].lerp(target, body_follow if i < segments else 1.0)

	
	if wiggle > 0.0 and _agitation > 0.001:
		for i in range(1, segments):
			var ahead := _pts[i + 1]
			var behind := _pts[i - 1]
			var along := ahead - behind
			if along.length() > 0.001:
				var perp := along.normalized().orthogonal()
				var env := float(i) / float(segments)   
				var amt := sin(_age * wiggle_speed + float(i) * 0.7) * wiggle * env * _agitation
				_pts[i] += perp * amt

	queue_redraw()


func _check_tip() -> void:
	pass

	



func _finish() -> void:
	_caught.clear()
	state = State.IDLE
	_len = 0.0
	_reset_to_anchor()
	returned.emit()
	queue_redraw()


func _reset_to_anchor() -> void:
	var a := global_position
	for i in segments + 1:
		_pts[i] = a
		_prev[i] = a


func _draw() -> void:
	if state == State.IDLE or _len < 0.001:
		return
	var pl: PackedVector2Array = PackedVector2Array()
	for p in _pts:
		pl.append(to_local(p))

	for i in segments:
		var w := lerpf(width_base, width_tip, float(i) / float(segments))
		draw_line(pl[i], pl[i + 1], color, w)
		draw_circle(pl[i + 1], w * 0.5, color)
	for i in segments:
		var w := lerpf(width_base * 0.45, width_tip * 0.45, float(i) / float(segments))
		draw_line(pl[i], pl[i + 1], color_core, w)
	draw_circle(pl[segments], width_tip + 4.0, color)
	draw_circle(pl[segments] + Vector2(-2, -2), 2.5, Color(1, 1, 1, 0.5))
