extends Node


@export var volume_db: float = -6.0

var _player: AudioStreamPlayer
var _current: AudioStream


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Music"
	_player.volume_db = volume_db
	add_child(_player)


func play(stream: AudioStream) -> void:
	if stream == null: return
	if stream == _current and _player.playing: return
	_current = stream
	_player.stream = stream
	_player.play()


func stop() -> void:
	_player.stop()
	_current = null


func set_volume_db(db: float) -> void:
	volume_db = db
	_player.volume_db = db
