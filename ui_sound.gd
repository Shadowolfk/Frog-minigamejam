extends Node

## Autoload. Plays short UI feedback blips on the SFX bus. The stream is loaded
## dynamically so a not-yet-imported wav simply stays silent instead of breaking.

const STREAM_PATH := "res://ui_select.wav"

var _player: AudioStreamPlayer
var _stream: AudioStream


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "SFX"
	add_child(_player)
	if ResourceLoader.exists(STREAM_PATH):
		_stream = load(STREAM_PATH)


## Soft, higher-pitched tick when the selection moves between controls.
func move() -> void:
	_play(1.15, -8.0)


## Firmer tick when a button is activated.
func click() -> void:
	_play(0.85, -2.0)


func _play(pitch: float, volume_db: float) -> void:
	if _stream == null:
		return
	_player.stream = _stream
	_player.pitch_scale = pitch
	_player.volume_db = volume_db
	_player.play()
