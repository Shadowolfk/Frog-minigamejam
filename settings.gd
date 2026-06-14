extends Node

## Autoload. Persists per-bus volume (0..1 linear) and applies it to the
## AudioServer. Buses are defined in default_bus_layout.tres.

const SAVE_PATH := "user://settings.cfg"
const BUSES: Array[String] = ["Master", "Music", "SFX"]

var _volumes := {"Master": 0.8, "Music": 0.8, "SFX": 0.8}


func _ready() -> void:
	_load()
	for bus in BUSES:
		_apply(bus, _volumes[bus])


func get_volume(bus: String) -> float:
	return float(_volumes.get(bus, 1.0))


func set_volume(bus: String, value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	_volumes[bus] = value
	_apply(bus, value)
	_save()


func _apply(bus: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, value <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.0001)))


func _save() -> void:
	var c := ConfigFile.new()
	for bus in BUSES:
		c.set_value("audio", bus, _volumes[bus])
	c.save(SAVE_PATH)


func _load() -> void:
	var c := ConfigFile.new()
	if c.load(SAVE_PATH) == OK:
		for bus in BUSES:
			_volumes[bus] = clampf(float(c.get_value("audio", bus, _volumes[bus])), 0.0, 1.0)
