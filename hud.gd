extends CanvasLayer


signal continue_pressed  
signal select_pressed    

@export var win_jingle: AudioStream                 
@export_range(-40.0, 12.0) var jingle_volume_db: float = 0.0
@export var lock_buttons_during_jingle: bool = true

@onready var level_label: Label = $TopBar/LevelLabel
@onready var attempts_label: Label = $TopBar/AttemptsLabel
@onready var back_button: TextureButton = $TopBar/BackButton

@onready var completion_panel: Control = $CompletionPanel
@onready var completion_title: Label = $CompletionPanel/Center/Margin/VBox/Title
@onready var completion_stats: Label = $CompletionPanel/Center/Margin/VBox/Stats
@onready var continue_button: Button = $CompletionPanel/Center/Margin/VBox/Buttons/ContinueButton
@onready var select_button:   Button = $CompletionPanel/Center/Margin/VBox/Buttons/SelectButton
var _audio: AudioStreamPlayer

func _ready() -> void:
	completion_panel.hide()
	back_button.pressed.connect(func(): select_pressed.emit())
	select_button.pressed.connect(func(): select_pressed.emit())
	continue_button.pressed.connect(func(): continue_pressed.emit())
	_audio = AudioStreamPlayer.new()
	_audio.bus = "Master"
	add_child(_audio)
	_audio.finished.connect(_on_jingle_finished)


func set_level(n: int) -> void:
	level_label.text = "%d                                          Level" % n


func set_attempts(n: int) -> void:
	attempts_label.text = "%d                                                                     Attempts: " % n


func show_completion(attempts: int, has_next: bool) -> void:
	completion_stats.text = "Attempts: %d" % attempts
	continue_button.visible = has_next
	if has_next:
		completion_title.text = "Caught!"
		continue_button.text = "Next Level"
	else:
		completion_title.text = "All levels cleared!"

	
	if win_jingle and lock_buttons_during_jingle:
		_set_panel_buttons_disabled(true)
	else:
		_set_panel_buttons_disabled(false)

	completion_panel.show()

	if win_jingle:
		_audio.stream = win_jingle
		_audio.volume_db = jingle_volume_db
		_audio.play()


func hide_completion() -> void:
	completion_panel.hide()
	
	
func _on_jingle_finished() -> void:
	_set_panel_buttons_disabled(false)


func _set_panel_buttons_disabled(d: bool) -> void:
	continue_button.disabled = d
	select_button.disabled = d
