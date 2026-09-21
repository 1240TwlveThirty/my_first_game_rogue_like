extends State

## ИИ-версия лазания по стене - в отличие от player/States/wall_climb_state.gd
## (держится/скользит, ждёт ввода для прыжка со стены), Гонец
## ЦЕЛЕНАПРАВЛЕННО карабкается вверх, пока цель выше него - активный
## поиск, а не пассивное сцепление. Вход - только из messenger_jump_state.gd,
## и только когда стена находится именно со стороны цели.
##
## Выход: (1) стена кончилась/сменила сторону - обратно в Chase (не в
## Jump - базовый Enemy и так продолжает применять гравитацию и
## обрабатывать move_and_slide() независимо от состояния, Chase просто
## подхватит горизонтальное сближение, пока тело падает; посадка сама
## переключит в Land благодаря общей логике enemy.gd), (2) цель больше не
## выше - тоже в Chase, забираться дальше незачем, (3) добрался до пола -
## общая логика enemy.gd сама уводит в Land, здесь ничего делать не надо.

@export var climb_speed: float = 120.0

var wall_direction: float = 0.0


func enter() -> void:
	wall_direction = actor.get_climbable_wall_direction()
	actor.velocity.x = 0.0
	actor.velocity.y = 0.0
	actor.animated_sprite.play("run")  # плейсхолдер - отдельной анимации лазания у Гонца в ассете нет
	actor.animated_sprite.flip_h = wall_direction < 0.0


func physics_update(_delta: float) -> void:
	if not actor.target:
		state_machine.transition_to("Idle")
		return

	if not actor.is_on_wall() or actor.get_climbable_wall_direction() != wall_direction:
		state_machine.transition_to("Chase")
		return

	if actor.target.global_position.y >= actor.global_position.y:
		state_machine.transition_to("Chase")
		return

	actor.velocity.y = -climb_speed
	actor.velocity.x = 0.0

	if actor.is_on_floor():
		state_machine.transition_to("Land")
