extends CharacterBody2D


@export var mouth_offset: Vector2 = Vector2(0, -4)
@export var relaunch_delay: float = 0.5

@onready var tongue: Tongue = $Tongue

var _relaunch_t: float = 0.6
var attempts: int = 0
var wins: int = 0


func _ready() -> void:
	tongue.position = mouth_offset
	tongue.caught.connect(_on_caught)
	tongue.failed.connect(_on_failed)
	tongue.reeled_in.connect(_on_reeled_in)
	tongue.launched.connect(_on_launched)


func _process(delta: float) -> void:
	if tongue.is_idle():
		_relaunch_t -= delta
		if _relaunch_t <= 0.0:
			tongue.fire()


func _on_launched() -> void:
	attempts += 1


func _on_caught(_node: Node) -> void:
	print("hit")
	wins += 1


func _on_failed(_at: Vector2) -> void:
	print("yikes")
	pass


func _on_reeled_in() -> void:
	_relaunch_t = relaunch_delay
