extends CanvasLayer


signal continue_pressed  
signal select_pressed    

@onready var level_label: Label = $TopBar/LevelLabel
@onready var attempts_label: Label = $TopBar/AttemptsLabel
@onready var back_button: Button = $TopBar/BackButton

@onready var completion_panel: Control = $CompletionPanel
@onready var completion_title: Label = $CompletionPanel/Center/Panel/Margin/VBox/Title
@onready var completion_stats: Label = $CompletionPanel/Center/Panel/Margin/VBox/Stats
@onready var continue_button: Button = $CompletionPanel/Center/Panel/Margin/VBox/Buttons/ContinueButton
@onready var select_button:   Button = $CompletionPanel/Center/Panel/Margin/VBox/Buttons/SelectButton


func _ready() -> void:
	completion_panel.hide()
	back_button.pressed.connect(func(): select_pressed.emit())
	select_button.pressed.connect(func(): select_pressed.emit())
	continue_button.pressed.connect(func(): continue_pressed.emit())


func set_level(n: int) -> void:
	level_label.text = "Level %d" % n


func set_attempts(n: int) -> void:
	attempts_label.text = "Attempts: %d" % n


func show_completion(attempts: int, has_next: bool) -> void:
	completion_stats.text = "Attempts: %d" % attempts
	continue_button.visible = has_next
	if has_next:
		completion_title.text = "Caught!"
		continue_button.text = "Next Level"
	else:
		completion_title.text = "All levels cleared!"
	completion_panel.show()


func hide_completion() -> void:
	completion_panel.hide()
