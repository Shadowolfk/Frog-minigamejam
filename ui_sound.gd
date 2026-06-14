extends Node

## Autoload. Plays short UI feedback blips on the SFX bus. The stream is loaded
## dynamically so a not-yet-imported wav simply stays silent instead of breaking.

const STREAM_PATH := "res://ui_select.wav"
const EAT_PATH := "res://fly_eat.wav"

var _player: AudioStreamPlayer
var _eat_player: AudioStreamPlayer
var _stream: AudioStream
var _eat_stream: AudioStream


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "SFX"
	add_child(_player)
	_eat_player = AudioStreamPlayer.new()
	_eat_player.bus = "SFX"
	add_child(_eat_player)
	if ResourceLoader.exists(STREAM_PATH):
		_stream = load(STREAM_PATH)
	if ResourceLoader.exists(EAT_PATH):
		_eat_stream = load(EAT_PATH)


## Soft, higher-pitched tick when the selection moves between controls.
func move() -> void:
	_play(1.15, -8.0)


## Firmer tick when a button is activated.
func click() -> void:
	_play(0.85, -2.0)


## Satisfying pop when a fly is eaten, with a little pitch variation.
func eat() -> void:
	if _eat_stream == null:
		return
	_eat_player.stream = _eat_stream
	_eat_player.pitch_scale = randf_range(0.9, 1.14)
	_eat_player.play()


func _play(pitch: float, volume_db: float) -> void:
	if _stream == null:
		return
	_player.stream = _stream
	_player.pitch_scale = pitch
	_player.volume_db = volume_db
	_player.play()
