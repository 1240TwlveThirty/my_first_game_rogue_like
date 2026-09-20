extends Node

## Изолированный спайк-прототип глобальной остановки времени лука
## (референс: "The World", Dio Brando - весь мир замирает, кроме игрока).
## Автозагружаемый синглтон "TimeStop": просто источник состояния,
## который читают другие акторы (enemy.gd, arrow.gd) через is_active -
## сам ничего не знает про врагов, стрелы или игрока.

var is_active: bool = false

@export var base_duration: float = 5.0
@export var cooldown_after_use: float = 8.0

var duration_left: float = 0.0
var cooldown_left: float = 0.0


func can_start() -> bool:
	return not is_active and cooldown_left <= 0.0


func start() -> void:
	if not can_start():
		return
	is_active = true
	duration_left = base_duration


## Досрочное ручное отключение (input action "time_stop" повторным нажатием)
## заканчивается тем же путём, что и истечение таймера в _process() -
## единая точка выхода, cooldown_after_use стартует в обоих случаях одинаково.
func stop() -> void:
	if not is_active:
		return
	is_active = false
	duration_left = 0.0
	cooldown_left = cooldown_after_use


func _process(delta: float) -> void:
	if is_active:
		duration_left -= delta
		if duration_left <= 0.0:
			stop()
	elif cooldown_left > 0.0:
		cooldown_left -= delta
