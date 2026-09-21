extends Node

## Глобальная остановка времени (референс: "The World", Dio Brando - весь
## мир замирает, кроме исключения). Изначально спайк-прототип жёстко
## исключал игрока - теперь исключение выбирается явно через exempt_actor,
## чтобы тот же механизм годился и для будущих боевых паттернов врагов
## (например, телепорт-тайм-стоп Гонца, где исключением должен быть БОСС,
## а игрок - подчиняться заморозке наравне с остальным миром). Автозагружаемый
## синглтон: просто источник состояния, который читают другие акторы
## (enemy.gd, player.tscn.gd, arrow.gd, dagger.gd, enemy_arrow.gd) через
## is_active/exempt_actor - сам ничего не знает про конкретных акторов.

var is_active: bool = false
var exempt_actor: Node = null

@export var base_duration: float = 5.0
@export var cooldown_after_use: float = 8.0

var duration_left: float = 0.0
var cooldown_left: float = 0.0


func can_start() -> bool:
	return not is_active and cooldown_left <= 0.0


func start(actor: Node) -> void:
	if not can_start():
		return
	exempt_actor = actor
	is_active = true
	duration_left = base_duration


## Досрочное ручное отключение (input action "time_stop" повторным нажатием)
## заканчивается тем же путём, что и истечение таймера в _process() -
## единая точка выхода, cooldown_after_use стартует в обоих случаях одинаково.
## exempt_actor сбрасывается здесь же - не оставлять висячую ссылку на актора
## после окончания заморозки.
func stop() -> void:
	if not is_active:
		return
	is_active = false
	duration_left = 0.0
	cooldown_left = cooldown_after_use
	exempt_actor = null


func _process(delta: float) -> void:
	if is_active:
		# exempt_actor мог быть queue_free()-нут за время заморозки (например,
		# исключение-босс умерло от чего-то, что само же тайм-стоп не гейтит) -
		# на этот случай корректно завершаем тайм-стоп через тот же stop(),
		# а не падаем и не оставляем is_active=true навсегда.
		if exempt_actor != null and not is_instance_valid(exempt_actor):
			stop()
			return
		duration_left -= delta
		if duration_left <= 0.0:
			stop()
	elif cooldown_left > 0.0:
		cooldown_left -= delta
