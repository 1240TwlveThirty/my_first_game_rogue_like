extends Area2D

## Зона цепи/лестницы для свободного вертикального лазания (см.
## player/States/wall_ladder_state.gd). Сама зона не хранит состояние - только
## уведомляет игрока о входе/выходе, вся логика климбинга живёт в игроке.


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("enter_ladder"):
		body.enter_ladder(self)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("exit_ladder"):
		body.exit_ladder(self)
