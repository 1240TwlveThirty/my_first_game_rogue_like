extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var game_over_ui: CanvasLayer = $GameOverUI
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	player.player_died.connect(_on_player_died)
	hud.setup(player.get_current_health(), player.get_max_health())
	player.health_changed.connect(hud._on_health_changed)


func _on_player_died() -> void:
	get_tree().paused = true
	game_over_ui.show_game_over()
