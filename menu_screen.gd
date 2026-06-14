extends Control
class_name MenuScreen

## Base class for menu screens. Drives the decorative tongue so it "selects"
## the currently focused button or slider, lets the mouse focus controls on
## hover, and plays UI feedback sounds.

@export var tongue_path: NodePath
## Chase speed used while the tip is tracking the mouse (higher = less laggy).
@export var mouse_follow_speed: float = 42.0
## How strongly the tip is nudged toward a nearby button as the cursor nears it
## (0 = pure cursor follow, 1 = snaps onto the button).
@export_range(0.0, 1.0) var attract_strength: float = 0.4
## Distance from a button at which that magnetic pull begins.
@export var attract_range: float = 90.0

@export_category("Flies")
## Spawn buzzing, clickable flies that drift across the screen.
@export var fly_enabled: bool = true
@export var fly_first_delay: float = 5.0
@export var fly_interval: float = 6.0
@export var fly_max: int = 4

const FLY_PATH := "res://menu_fly.tscn"

var tongue: MenuTongue
var _fly_scene: PackedScene
var _focused: Control = null
var _armed: bool = false
var _mouse_active: bool = true
var _fly_timer: float = 0.0


func _ready() -> void:
	if tongue_path != NodePath():
		tongue = get_node_or_null(tongue_path) as MenuTongue
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	refresh_focusables()
	_focus_first.call_deferred()
	_arm.call_deferred()
	_fly_timer = fly_first_delay
	if ResourceLoader.exists(FLY_PATH):
		_fly_scene = load(FLY_PATH)


func _arm() -> void:
	_armed = true


## (Re)connect hover / press hooks. Call again after adding controls at runtime.
func refresh_focusables() -> void:
	for c in _collect(self, []):
		if c.has_meta("_mt_hooked"):
			continue
		c.set_meta("_mt_hooked", true)
		c.mouse_entered.connect(_grab.bind(c))
		if c is BaseButton:
			(c as BaseButton).pressed.connect(_play_click)


func _collect(n: Node, acc: Array) -> Array:
	for child in n.get_children():
		if child is Control:
			var ctrl := child as Control
			if (ctrl is BaseButton or ctrl is Slider) and ctrl.focus_mode != Control.FOCUS_NONE:
				acc.append(ctrl)
		_collect(child, acc)
	return acc


func _grab(c: Control) -> void:
	if is_instance_valid(c) and c.is_inside_tree() and not c.is_queued_for_deletion():
		c.grab_focus()


func _focus_first() -> void:
	if _focused != null:
		return
	var all := _collect(self, [])
	if all.size() > 0:
		(all[0] as Control).grab_focus()


func _on_focus_changed(ctrl: Control) -> void:
	if ctrl != null and is_ancestor_of(ctrl):
		_focused = ctrl
		if _armed:
			_play_move()


func _process(delta: float) -> void:
	if tongue != null:
		if _mouse_active:
			# Follow the cursor anywhere on screen, with a gentle magnetic pull
			# toward a button when the cursor gets close to one.
			tongue.set_target_global(_mouse_target(), mouse_follow_speed)
		elif _focused != null and is_instance_valid(_focused):
			# Keyboard navigation: rest on the focused control.
			tongue.set_target_global(_anchor_of(_focused), tongue.follow_speed)
		else:
			tongue.clear_target()

	if fly_enabled:
		_fly_timer -= delta
		if _fly_timer <= 0.0:
			_fly_timer = fly_interval
			_spawn_fly()


func _spawn_fly() -> void:
	if _fly_scene == null:
		return
	if get_tree().get_nodes_in_group("menu_fly").size() >= fly_max:
		return
	var fly := _fly_scene.instantiate() as Node2D
	add_child(fly)
	# enter from just off a random screen edge
	var vp := get_viewport().get_visible_rect().size
	match randi() % 4:
		0: fly.global_position = Vector2(-24.0, randf_range(0.0, vp.y))
		1: fly.global_position = Vector2(vp.x + 24.0, randf_range(0.0, vp.y))
		2: fly.global_position = Vector2(randf_range(0.0, vp.x), -24.0)
		_: fly.global_position = Vector2(randf_range(0.0, vp.x), vp.y + 24.0)


func _try_eat_fly() -> void:
	var pos := get_global_mouse_position()
	var best: Node2D = null
	var best_d := INF
	for f in get_tree().get_nodes_in_group("menu_fly"):
		var fly := f as Node2D
		if fly == null or not is_instance_valid(fly):
			continue
		var d := pos.distance_to(fly.global_position)
		if d <= float(fly.get("hit_radius")) and d < best_d:
			best = fly
			best_d = d
	if best == null:
		return
	get_viewport().set_input_as_handled()

	# Lash the tongue out to grab it; it pops when the tip arrives.
	var fly_ref := best
	if tongue != null:
		tongue.grab(fly_ref, func() -> void:
			if is_instance_valid(fly_ref):
				fly_ref.call("eat"))
	else:
		fly_ref.call("eat")


## The point the tip rests on for a control: its centre, or the grabber for a
## slider.
func _anchor_of(c: Control) -> Vector2:
	var r := c.get_global_rect()
	if c is HSlider:
		var s := c as HSlider
		var ratio := 0.0
		if s.max_value > s.min_value:
			ratio = (s.value - s.min_value) / (s.max_value - s.min_value)
		return Vector2(r.position.x + r.size.x * ratio, r.position.y + r.size.y * 0.5)
	return r.get_center()


## The tip target while using the mouse: the cursor itself, eased toward the
## nearest button the closer the cursor gets to it (a slight magnetic pull).
func _mouse_target() -> Vector2:
	var mouse := get_global_mouse_position()
	var nearest_anchor := mouse
	var nearest_d := INF
	for c in _collect(self, []):
		var ctrl := c as Control
		if ctrl == null:
			continue
		if ctrl is BaseButton and (ctrl as BaseButton).disabled:
			continue
		var r := ctrl.get_global_rect()
		var clamped := Vector2(
			clampf(mouse.x, r.position.x, r.position.x + r.size.x),
			clampf(mouse.y, r.position.y, r.position.y + r.size.y))
		var d := mouse.distance_to(clamped)
		if d < nearest_d:
			nearest_d = d
			nearest_anchor = _anchor_of(ctrl)
	var pull := attract_strength * clampf(1.0 - nearest_d / attract_range, 0.0, 1.0)
	return mouse.lerp(nearest_anchor, pull)


func _input(event: InputEvent) -> void:
	# Hide the OS cursor while navigating with the keyboard; show it again the
	# moment the mouse moves.
	if event is InputEventMouseMotion:
		if not _mouse_active:
			_mouse_active = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventKey and event.pressed and not event.echo:
		if _mouse_active:
			_mouse_active = false
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Eat a fly if one is under the cursor (handled before buttons/sliders).
		_try_eat_fly()


func _exit_tree() -> void:
	# Never leave the cursor hidden when we head into gameplay / another scene.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_cancel()


## Override in subclasses (e.g. go back a screen). Default does nothing.
func _on_cancel() -> void:
	pass


func _play_move() -> void:
	var s := get_node_or_null("/root/UiSound")
	if s:
		s.move()


func _play_click() -> void:
	var s := get_node_or_null("/root/UiSound")
	if s:
		s.click()
