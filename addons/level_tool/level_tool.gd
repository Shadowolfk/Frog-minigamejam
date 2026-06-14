@tool
extends EditorPlugin

## Adds a "Levels" dock where you paste a scene UID (or res:// path) to register
## it as a level. Reads/writes res://levels.cfg, which level_manager.gd loads at
## runtime. Keeps DEFAULT_LEVELS in sync as a fallback for a fresh file.

const LEVELS_FILE := "res://levels.cfg"
const DEFAULT_LEVELS := [
	"res://levels/level_01.tscn",
	"res://levels/level_02.tscn",
	"res://levels/level_03.tscn",
]

var _dock: VBoxContainer
var _uid_edit: LineEdit
var _list: ItemList
var _status: Label


func _enter_tree() -> void:
	_build_dock()
	_refresh()
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, _dock)


func _exit_tree() -> void:
	remove_control_from_docks(_dock)
	_dock.queue_free()


func _build_dock() -> void:
	_dock = VBoxContainer.new()
	_dock.name = "Levels"
	_dock.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "Add Level"
	_dock.add_child(title)

	_uid_edit = LineEdit.new()
	_uid_edit.placeholder_text = "uid://…  or  res://…tscn"
	_uid_edit.text_submitted.connect(func(_t: String) -> void: _on_add())
	_dock.add_child(_uid_edit)

	var add_btn := Button.new()
	add_btn.text = "Add Level"
	add_btn.pressed.connect(_on_add)
	_dock.add_child(add_btn)

	var hint := Label.new()
	hint.text = "Tip: right-click a scene in FileSystem → Copy UID"
	hint.add_theme_font_size_override("font_size", 11)
	hint.modulate = Color(1, 1, 1, 0.55)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(hint)

	_dock.add_child(HSeparator.new())

	var list_label := Label.new()
	list_label.text = "Current levels"
	_dock.add_child(list_label)

	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(0, 150)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dock.add_child(_list)

	var buttons := HBoxContainer.new()
	_dock.add_child(buttons)
	var up := Button.new()
	up.text = "▲ Up"
	up.pressed.connect(_on_move.bind(-1))
	buttons.add_child(up)
	var down := Button.new()
	down.text = "▼ Down"
	down.pressed.connect(_on_move.bind(1))
	buttons.add_child(down)
	var remove := Button.new()
	remove.text = "Remove"
	remove.pressed.connect(_on_remove)
	buttons.add_child(remove)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(_status)


func _on_add() -> void:
	var path := _resolve(_uid_edit.text)
	if path.is_empty():
		_set_status("Couldn't resolve that UID / path.", true)
		return
	if not path.ends_with(".tscn"):
		_set_status("Not a scene (.tscn): " + path, true)
		return
	if not ResourceLoader.exists(path):
		_set_status("Scene not found: " + path, true)
		return
	var levels := _load_levels()
	if path in levels:
		_set_status("Already a level: " + path.get_file(), true)
		return
	levels.append(path)
	_save_levels(levels)
	_uid_edit.text = ""
	_refresh()
	_set_status("Added " + path.get_file(), false)


func _on_remove() -> void:
	var sel := _list.get_selected_items()
	if sel.is_empty():
		_set_status("Select a level to remove.", true)
		return
	var levels := _load_levels()
	var idx := sel[0]
	if idx >= 0 and idx < levels.size():
		var removed: String = levels[idx]
		levels.remove_at(idx)
		_save_levels(levels)
		_refresh()
		_set_status("Removed " + removed.get_file(), false)


func _on_move(dir: int) -> void:
	var sel := _list.get_selected_items()
	if sel.is_empty():
		return
	var levels := _load_levels()
	var idx := sel[0]
	var other := idx + dir
	if other < 0 or other >= levels.size():
		return
	var tmp: String = levels[idx]
	levels[idx] = levels[other]
	levels[other] = tmp
	_save_levels(levels)
	_refresh()
	_list.select(other)


## Accepts a uid://… string or a res://…tscn path; returns the resolved path or "".
func _resolve(text: String) -> String:
	text = text.strip_edges()
	if text.is_empty():
		return ""
	if text.begins_with("uid://"):
		var id := ResourceUID.text_to_id(text)
		if id != ResourceUID.INVALID_ID and ResourceUID.has_id(id):
			return ResourceUID.get_id_path(id)
		return ""
	if text.begins_with("res://"):
		return text
	return ""


func _load_levels() -> Array:
	var c := ConfigFile.new()
	if c.load(LEVELS_FILE) == OK:
		var arr: Array = c.get_value("levels", "paths", [])
		var out: Array = []
		for p in arr:
			out.append(String(p))
		if not out.is_empty():
			return out
	return DEFAULT_LEVELS.duplicate()


func _save_levels(levels: Array) -> void:
	var c := ConfigFile.new()
	c.set_value("levels", "paths", levels)
	if c.save(LEVELS_FILE) == OK:
		EditorInterface.get_resource_filesystem().update_file(LEVELS_FILE)


func _refresh() -> void:
	_list.clear()
	var levels := _load_levels()
	for i in levels.size():
		_list.add_item("%d.   %s" % [i + 1, String(levels[i]).get_file()])


func _set_status(msg: String, is_error: bool) -> void:
	_status.text = msg
	_status.modulate = Color(1, 0.55, 0.55) if is_error else Color(0.6, 1, 0.6)
