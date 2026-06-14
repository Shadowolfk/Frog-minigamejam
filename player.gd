extends CharacterBody2D


@export var mouth_offset: Vector2 = Vector2(0, -4)

@onready var tongue: Tongue = $Tongue

var _won_this_run: bool = false   
var attempts: int = 0
var wins: int = 0


func _ready() -> void:
	$AnimatedSprite2D.play("default")

	tongue.position = mouth_offset
	tongue.caught.connect(_on_caught)
	tongue.failed.connect(_on_failed)
	tongue.reeled_in.connect(_on_reeled_in)
	tongue.launched.connect(_on_launched)


func _process(_delta: float) -> void:
	if tongue.is_idle() and not _won_this_run:
		
		if Input.is_action_just_pressed("ui_accept"):
			tongue.fire()


func _on_launched() -> void:
	$AnimatedSprite2D.play("tongue")
	attempts += 1


func _on_caught(_node: Node) -> void:
	print("hit")
	wins += 1

	_won_this_run = true


func _on_failed(_at: Vector2) -> void:

	print("yikes")


func _on_reeled_in() -> void:
	$AnimatedSprite2D.play("default")
