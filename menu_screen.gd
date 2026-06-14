extends Control
class_name MenuScreen

## Base class for menu screens. Drives the decorative tongue so it "selects"
## the currently focused button or slider, lets the mouse focus controls on
## hover, and plays UI feedback sounds.

@export var tongue_path: NodePath
## How strongly the tongue tip leans toward the mouse within the focused control
## (0 = always centered, 1 = sits right on the cursor).
@export_range(0.0, 1.0) var mouse_follow: float = 0.65
## How far past the control's edge the tongue will still reach for the cursor.
@export var mouse_follow_margin: float = 30.0
## Chase speed used while the tip is tracking the mouse (higher = less laggy).
@export var mouse_follow_speed: float = 42.0

var tongue: MenuTongue
var _focused: Control = null
var _armed: bool = false
var _mouse_active: bool = true
var _following_mouse: bool = false


func _ready() -> void:
	if tongue_path != NodePath():
		tongue = get_node_or_null(tongue_path) as MenuTongue
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	refresh_focusables()
	_focus_first.call_deferred()
	_arm.call_deferred()


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


func _process(_delta: float) -> void:
	if tongue == null:
		return
	if _focused != null and is_instance_valid(_focused):
		var point := _attach_point(_focused)
		tongue.set_target_global(point, mouse_follow_speed if _following_mouse else tongue.follow_speed)
	else:
		tongue.clear_target()


## Where the tongue tip should land on a control. The tip rests on an anchor
## (control centre, or the grabber for sliders) but leans toward the mouse while
## the cursor is over the control, so it reads as actively selecting it. When the
## mouse is elsewhere (keyboard navigation) it snaps back to the anchor.
func _attach_point(c: Control) -> Vector2:
	var r := c.get_global_rect()
	var anchor := r.get_center()
	if c is HSlider:
		var s := c as HSlider
		var ratio := 0.0
		if s.max_value > s.min_value:
			ratio = (s.value - s.min_value) / (s.max_value - s.min_value)
		anchor = Vector2(r.position.x + r.size.x * ratio, r.position.y + r.size.y * 0.5)

	if _mouse_active:
		var mouse := get_global_mouse_position()
		if r.grow(mouse_follow_margin).has_point(mouse):
			_following_mouse = true
			return anchor.lerp(mouse, mouse_follow)
	_following_mouse = false
	return anchor


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
