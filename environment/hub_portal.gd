extends Area2D

## Портал в хаб - плейсхолдер-прямоугольник, скрыт и выключен по
## умолчанию (visible=false, monitoring=false). Включается извне через
## activate() - вызывается из messenger_death_state.gd после завершения
## сцены смерти Гонца. При входе игрока в зону - смена сцены на
## минимальную hub.tscn (только пол/стены/точка спавна, без торговца -
## это отдельная следующая задача).

@export var hub_scene_path: String = "res://hub/hub.tscn"


func _ready() -> void:
	add_to_group("hub_portal")
	visible = false
	monitoring = false
	body_entered.connect(_on_body_entered)


func activate() -> void:
	visible = true
	monitoring = true


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file(hub_scene_path)
