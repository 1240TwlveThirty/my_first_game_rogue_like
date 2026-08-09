extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var game_over_ui: CanvasLayer = $GameOverUI


func _ready() -> void:
	player.player_died.connect(_on_player_died)


func _on_player_died() -> void:
	get_tree().paused = true
	game_over_ui.show_game_over()
