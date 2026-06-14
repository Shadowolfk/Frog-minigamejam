extends Node2D
class_name Tongue



@export_category("Movement")

@export var extend_speed: float = 430.0      
@export var max_length_factor: float = 2.5    
@export var fixed_max_length: float = 0.0   
@export var retract_speed: float = 2600.0    

@export_category("Steering")

@export var steer_accel: float = 2000.0      
@export_range(0.0, 1.0) var steer_damp: float = 0.97 
@export var max_steer: float = 340.0          
@export var drift_accel: float = 420.0    
@export var drift_freq: float = 2.3          

@export_category("Catch")
@export var grab_radius: float = 26.0
@export var collide_radius: float = 7.0
@export var default_obstacle_radius: float = 32.0   

@export_category("Ripple")
@export var ripple_gain: float = 22.0
@export var ripple_max: float = 46.0
@export_range(0.0, 0.5) var wave_c: float = 0.32    
@export_range(0.0, 1.0) var wave_damp: float = 0.93
@export var turn_deadzone: float = 0.02

@export_category("Looks")
@export var sample_distance: float = 7.0     
@export var width_base: float = 14.0
@export var width_tip: float = 5.0
@export var color: Color = Color.WHITE
@export var color_core: Color = Color(0.78, 0.20, 0.31)

enum State { IDLE, OUT, IN }

signal caught(node)
signal failed(at_position)
signal launched
signal reeled_in
signal delivered(nodes) 

var state: int = State.IDLE
var _path: PackedVector2Array        
var _off: PackedFloat32Array     
var _ovel: PackedFloat32Array        
var _head: Vector2 = Vector2.ZERO    
var _last_dir: Vector2 = Vector2.RIGHT
var _vy: float = 0.0
var _len: float = 0.0
var _max_len: float = 900.0
var _age: float = 0.0
var _caught_nodes: Array = []  


func _ready() -> void:
	_recompute_max_length()


func is_idle() -> bool: return state == State.IDLE
func tip() -> Vector2:  return _head
func length_used() -> float: return _len
func length_max() -> float: return _max_len


func fire() -> void:
	_caught_nodes.clear()
	if state != State.IDLE: return
	var a := global_position
	_path = PackedVector2Array([a])
	_off = PackedFloat32Array([0.0])
	_ovel = PackedFloat32Array([0.0])
	_head = a
	_last_dir = Vector2.RIGHT
	_vy = 0.0
	_len = 0.0
	_age = 0.0
	state = State.OUT
	_recompute_max_length()
	launched.emit()


func retract() -> void:
	if state == State.OUT:
		if _path.size() > 0 and _head.distance_to(_path[_path.size() - 1]) > 0.5:
			_push_trail_point(_head)
		state = State.IN


func _physics_process(delta: float) -> void:
	_age += delta
	match state:
		State.OUT: _step_out(delta)
		State.IN:  _step_in(delta)
	if state != State.IDLE:
		_step_wave()
	queue_redraw()


func _step_out(delta: float) -> void:

	var acc := 0.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):    acc -= steer_accel
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):  acc += steer_accel
	acc += sin(_age * drift_freq) * drift_accel
	_vy = clampf((_vy + acc * delta) * steer_damp, -max_steer, max_steer)

	var vel := Vector2(extend_speed, _vy)
	var prev_dir := _last_dir
	_last_dir = vel.normalized()

	var cross := prev_dir.x * _last_dir.y - prev_dir.y * _last_dir.x
	var dotp := clampf(prev_dir.dot(_last_dir), -1.0, 1.0)
	var turn := atan2(cross, dotp)
	if absf(turn) > turn_deadzone and _ovel.size() >= 2:
		var j := _ovel.size() - 2
		_ovel[j] = clampf(_ovel[j] + turn * ripple_gain, -ripple_max, ripple_max)

	var n := _head + vel * delta


	for o in get_tree().get_nodes_in_group("obstacle"):
		if not is_instance_valid(o): continue
		var pad_r := _obstacle_radius(o) + collide_radius
		var pad_r_sq := pad_r * pad_r
		var pad_pos: Vector2 = o.global_position
	
		if n.distance_squared_to(pad_pos) < pad_r_sq:
			if o.has_method("on_hit"): o.on_hit()
			failed.emit(n)
			retract()
			return
		# body
		for i in range(1, _path.size()):
			if _path[i].distance_squared_to(pad_pos) < pad_r_sq:
				if o.has_method("on_hit"): o.on_hit()
				failed.emit(_path[i])
				retract()
				return

	
	_head = n
	_len += vel.length() * delta
	if _path.size() == 0 or _head.distance_to(_path[_path.size() - 1]) >= sample_distance:
		_push_trail_point(_head)


	
	for c in get_tree().get_nodes_in_group("catchable"):
		if not is_instance_valid(c): continue
		if _head.distance_to(c.global_position) < grab_radius:
			_caught_nodes.append(c)
			if c.has_method("on_caught"):
				c.on_caught()
			caught.emit(c)
			retract()
			return

	if _len >= _max_len:
		retract()


func _step_in(delta: float) -> void:

	var remain := retract_speed * delta
	while remain > 0.0 and _path.size() > 1:
		var a := _path[_path.size() - 1]
		var b := _path[_path.size() - 2]
		var d := a.distance_to(b)
		if d <= remain:
			remain -= d
			_len = maxf(0.0, _len - d)
			_path.remove_at(_path.size() - 1)
			_off.remove_at(_off.size() - 1)
			_ovel.remove_at(_ovel.size() - 1)
		else:
			var t := remain / d
			_path[_path.size() - 1] = a.lerp(b, t)
			_len = maxf(0.0, _len - remain)
			remain = 0.0
	if _path.size() > 0:
		_head = _path[_path.size() - 1]
		
		for c in _caught_nodes:
			if is_instance_valid(c):
				c.global_position = _head
	if _path.size() <= 1:
		state = State.IDLE
		_len = 0.0
		if _caught_nodes.size() > 0:
			delivered.emit(_caught_nodes.duplicate())
			_caught_nodes.clear()
		reeled_in.emit()


func _step_wave() -> void:
	var n := _off.size()
	if n < 3: return
	for i in range(1, n - 1):
		var a := (_off[i - 1] + _off[i + 1]) * 0.5 - _off[i]
		_ovel[i] = (_ovel[i] + a * wave_c) * wave_damp
	for i in range(1, n - 1):
		_off[i] = clampf(_off[i] + _ovel[i], -ripple_max, ripple_max)
	if n > 0:
		_off[0] = 0.0; _ovel[0] = 0.0
		_off[n - 1] = 0.0; _ovel[n - 1] = 0.0


func _push_trail_point(p: Vector2) -> void:
	_path.append(p)
	_off.append(0.0)
	_ovel.append(0.0)


func _obstacle_radius(o: Node) -> float:
	if "obstacle_radius" in o: return float(o.get("obstacle_radius"))
	if "radius" in o:          return float(o.get("radius"))
	return default_obstacle_radius


func _recompute_max_length() -> void:
	if fixed_max_length > 0.0:
		_max_len = fixed_max_length
		return
	
	for c in get_tree().get_nodes_in_group("catchable"):
		if is_instance_valid(c):
			_max_len = global_position.distance_to(c.global_position) * max_length_factor
			return
	_max_len = 900.0


func _draw() -> void:
	if state == State.IDLE or _path.size() < 2: return

	
	var pts: PackedVector2Array = PackedVector2Array()
	var offs: PackedFloat32Array = PackedFloat32Array()
	for i in _path.size():
		pts.append(to_local(_path[i]))
		offs.append(_off[i])
	if state == State.OUT and _head.distance_to(_path[_path.size() - 1]) > 0.5:
		pts.append(to_local(_head))
		offs.append(0.0) 

	var n := pts.size()
	if n < 2: return

	var disp: PackedVector2Array = PackedVector2Array()
	disp.resize(n)
	for i in n:
		var p := pts[i]
		if i > 0 and i < n - 1:
			var along := pts[i + 1] - pts[i - 1]
			if along.length() > 0.001:
				var perp := Vector2(-along.y, along.x).normalized()
				p += perp * offs[i]
		disp[i] = p

	for i in n - 1:
		var t := float(i) / float(n - 1)
		var w := lerpf(width_base, width_tip, t)
		draw_line(disp[i], disp[i + 1], color, w)
		draw_circle(disp[i + 1], w * 0.5, color)
	for i in n - 1:
		var t2 := float(i) / float(n - 1)
		var w2 := lerpf(width_base * 0.45, width_tip * 0.45, t2)
		draw_line(disp[i], disp[i + 1], color_core, w2)

	draw_circle(disp[n - 1], width_tip + 3.0, color)
	draw_circle(disp[n - 1] + Vector2(-2, -2), 2.5, Color(1, 1, 1, 0.5))
