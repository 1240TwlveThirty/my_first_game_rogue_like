extends State

## Погоня Гонца - сближение по X/flip_h как в chase_state.gd, три зоны по
## дистанции вместо одной:
##   - вплотную (<= melee_range): ротация по кругу между несколькими
##     разными ближними состояниями (melee_rotation ниже) -
##     ДЕТЕРМИНИРОВАННЫЙ round-robin, не случайный выбор - сохраняем
##     предсказуемость для тестирования, как договаривались в этой сессии.
##   - средняя дистанция (melee_range < dist <= dagger_range): бросок
##     BossDagger - давление на расстоянии как самостоятельный вариант,
##     не только крайняя мера при уклонении.
##   - дальше dagger_range: обычное сближение.
## Обе ближние зоны дополнительно требуют delta_y <= max_engage_height_diff -
## без этого гейта близость считалась чисто по X, и при разной высоте
## (плавающие платформы арены, см. arena.tscn/Floor - перепады кратны
## 64px, минимальный между тайлами реально встречается 128px) игрок в
## горизонтальной проекции читался как "вплотную", хотя физически
## недостижим - Гонец бил в пустоту/бесконечно бросал кинжал сквозь пол.
## Если высота не подходит - просто Приоритет 3 (сближение по X), атаки
## не срабатывают независимо от горизонтальной дистанции.
##
## evasion_punish_threshold здесь БОЛЬШЕ НЕТ - инкремент actor.time_since_last_hit
## и сама проверка порога перенесены в messenger.gd._physics_process(),
## тикают безусловно каждый кадр независимо от текущего состояния ФСМ (не
## только пока актор в Chase, как было раньше - см. комментарий там же про
## причину переноса). Здесь эта зона дистанции больше ни на что не влияет.
##
## melee_rotation_index живёт ЗДЕСЬ (не на акторе), в отличие от
## actor.time_since_last_hit - эту переменную читает/пишет ТОЛЬКО это
## состояние, сами ближние состояния не обязаны знать своё место в
## ротации, просто отрабатывают и возвращаются в Chase. Не сбрасывается в
## enter() - State-узлы в этом проекте не пересоздаются между переходами
## (StateMachine хранит только указатель current_state, все State-дети
## живут в дереве постоянно), поэтому поле корректно переживает
## многократные входы/выходы из Chase.

@export var melee_range: float = 90.0
@export var dagger_range: float = 320.0
@export var max_engage_height_diff: float = 80.0
@export var melee_rotation: Array[String] = ["Combo", "QuickLunge", "WideSwing", "Attack2"]

var melee_rotation_index: int = 0


func enter() -> void:
	actor.animated_sprite.play("run")


func physics_update(_delta: float) -> void:
	if not actor.target:
		state_machine.transition_to("Idle")
		return

	var delta_x: float = actor.target.global_position.x - actor.global_position.x
	var delta_y: float = absf(actor.target.global_position.y - actor.global_position.y)
	var distance: float = absf(delta_x)
	var height_ok: bool = delta_y <= max_engage_height_diff

	# Приоритет 1 - вплотную по X И на досягаемой высоте, ротация ближних вариантов.
	if height_ok and distance <= melee_range:
		actor.velocity.x = 0.0
		_enter_next_melee_state()
		return

	# Приоритет 2 - средняя дистанция по X И на досягаемой высоте, давление
	# кинжалом - НО только если серия бросков ещё не исчерпана
	# (actor.dagger_burst_cooldown_left, см. messenger.gd/
	# messenger_dagger_throw_state.gd - без этого гейта Гонец кидал
	# кинжалы практически без остановки, пока игрок стоял в dagger_range).
	# Если кулдаун активен - просто падаем в Приоритет 4 (сближение).
	if height_ok and distance <= dagger_range and actor.dagger_burst_cooldown_left <= 0.0:
		actor.velocity.x = 0.0
		state_machine.transition_to("DaggerThrow")
		return

	# Приоритет 3 - цель заметно ВЫШЕ (не просто "недосягаема по высоте" в
	# любую сторону - прыжок помогает только вверх, вниз и так доберёмся
	# сближением по X + гравитацией) - прыгаем к ней вместо того, чтобы
	# упереться в подножие платформы и просто идти по X.
	if not height_ok and actor.target.global_position.y < actor.global_position.y - max_engage_height_diff:
		state_machine.transition_to("Jump")
		return

	# Приоритет 4 - обычное сближение (в т.ч. когда высота не подходит, но
	# цель не выше - просто идём к цели по X, ни одна атака не срабатывает).
	var direction: float = sign(delta_x)
	actor.animated_sprite.flip_h = direction < 0.0
	actor.velocity.x = direction * actor.speed


func _enter_next_melee_state() -> void:
	if melee_rotation.is_empty():
		return
	var state_name: String = melee_rotation[melee_rotation_index % melee_rotation.size()]
	melee_rotation_index += 1
	state_machine.transition_to(state_name)
