extends State

## ИИ-версия прыжка Гонца - решения принимаются алгоритмически (по
## позиции target), не по Input, в отличие от player/States/jump_state.gd.
## Одно состояние покрывает весь полёт целиком (подъём + падение) -
## отдельный "Fall", как у игрока, не нужен: приземление уже безусловно
## детектится в базовом enemy.gd._physics_process()
## (is_on_floor() and not was_on_floor -> transition_to("Land")) для ЛЮБОГО
## текущего состояния, значит Jump сам себя корректно прервёт в момент
## посадки без дополнительного кода здесь.
##
## Триггер входа - messenger_chase_state.gd: цель выше вне
## max_engage_height_diff. Двойной прыжок - как у игрока (actor.max_jumps
## = 2): второй прыжок используется на пике первого (velocity.y
## пересекает 0, тело начинает падать), если цель всё ещё выше и бюджет
## прыжков не исчерпан - простое, но рабочее приближение "не долетаю -
## прыгай ещё раз", без честного прогнозирования траектории (в отличие от
## игрока, второй прыжок здесь не по нажатию кнопки, а по этому условию).
##
## Wall-climb - активный поиск: если Гонец коснулся climbable_wall именно
## со стороны цели (не любой стены, попавшейся на пути) и цель всё ещё
## выше - тут же уходит в WallClimb, а не просто скользит вдоль стены как
## вдоль препятствия.

func enter() -> void:
	_do_jump()


func physics_update(_delta: float) -> void:
	if not actor.target:
		state_machine.transition_to("Idle")
		return

	var delta_x: float = actor.target.global_position.x - actor.global_position.x
	var direction: float = sign(delta_x)

	var wall_dir: float = actor.get_climbable_wall_direction()
	if wall_dir != 0.0 and wall_dir == direction and actor.target.global_position.y < actor.global_position.y:
		state_machine.transition_to("WallClimb")
		return

	if direction != 0.0:
		actor.animated_sprite.flip_h = direction < 0.0
	actor.velocity.x = direction * actor.speed

	if actor.velocity.y >= 0.0 and actor.jumps_used < actor.max_jumps and actor.target.global_position.y < actor.global_position.y:
		_do_jump()


func _do_jump() -> void:
	actor.velocity.y = actor.jump_velocity
	actor.jumps_used += 1
	actor.animated_sprite.play("run")  # плейсхолдер - отдельной анимации прыжка у Гонца в ассете нет
