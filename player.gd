extends CharacterBody2D
## Stationary frog for the level/obstacle mode. Hold left mouse to fire and steer the
## tongue toward the cursor; release to reel it back in. The tongue auto-retracts when
## it grabs the fly or hits an obstacle.

@export var mouth_offset: Vector2 = Vector2(0, -4)

@onready var tongue: Tongue = $Tongue


func _ready() -> void:
	tongue.position = mouth_offset
	tongue.caught.connect(_on_caught)
	tongue.blocked.connect(_on_blocked)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			tongue.fire(get_global_mouse_position())
		else:
			tongue.retract()


func _on_caught(node: Node) -> void:
	print("got the fly! ", node.name)  

func _on_blocked(node: Node) -> void:
	print("hit an obstacle: ", node.name)   
