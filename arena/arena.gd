extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var game_over_ui: CanvasLayer = $GameOverUI
@onready var hud: CanvasLayer = $HUD
@onready var weapon_hud: CanvasLayer = $WeaponHUD


func _ready() -> void:
	player.player_died.connect(_on_player_died)
	hud.setup(player.get_current_health(), player.get_max_health())
	player.health_changed.connect(hud._on_health_changed)
	weapon_hud.setup(player.mace_data, player.sword_data, player.current_melee_weapon)
	player.melee_weapon_changed.connect(weapon_hud._on_melee_weapon_changed)


func _on_player_died() -> void:
	get_tree().paused = true
	game_over_ui.show_game_over()
