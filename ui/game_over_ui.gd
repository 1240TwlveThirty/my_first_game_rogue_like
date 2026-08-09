extends CanvasLayer

@onready var restart_button: Button = $Control/VBoxContainer/RestartButton


func _ready() -> void:
	visible = false
	restart_button.pressed.connect(_on_restart_pressed)


func show_game_over() -> void:
	visible = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
