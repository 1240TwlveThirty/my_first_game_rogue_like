extends State

## Отдельное состояние от enemies/States/chase_state.gd - Лучник держит
## дистанцию вместо того, чтобы сближаться до attack_range. Три полосы по
## расстоянию до target вместо одного порога in_attack_range:
##   - дальше max_range: сближается (обычная погоня).
##   - ближе min_range: отступает (тот же sign(delta_x), но с обратным
##     знаком - direction движения, а не разворот спрайта).
##   - между ними: останавливается и атакует.
## Имя узла в FSM остаётся "Chase" по той же причине, что и у
## shieldman_chase_state.gd (17.08/21.09) - stagger_state.gd и
## land_state.gd безусловно зовут transition_to("Chase"), когда
## actor.target != null, независимо от архетипа.

@export var min_range: float = 180.0
@export var max_range: float = 420.0


func enter() -> void:
	actor.animated_sprite.play("run")


func physics_update(_delta: float) -> void:
	if not actor.target:
		state_machine.transition_to("Idle")
		return

	var delta_x: float = actor.target.global_position.x - actor.global_position.x
	var distance: float = absf(delta_x)

	if distance > max_range:
		var direction: float = sign(delta_x)
		actor.animated_sprite.flip_h = direction < 0.0
		actor.velocity.x = direction * actor.speed
		return

	if distance < min_range:
		var direction: float = -sign(delta_x)
		actor.animated_sprite.flip_h = direction < 0.0
		actor.velocity.x = direction * actor.speed
		return

	# В "рабочей полосе" - стоим на месте и разворачиваемся лицом к цели.
	# attack_cooldown_left переиспользован с базового Enemy (тикает в
	# enemy.gd._physics_process безусловно) - без этой проверки лучник
	# заходил бы в Attack на каждом кадре, пока цель в полосе, полностью
	# игнорируя fire_cooldown, заданный в инспекторе на самом акторе.
	actor.velocity.x = 0.0
	if delta_x != 0.0:
		actor.animated_sprite.flip_h = delta_x < 0.0
	if actor.attack_cooldown_left <= 0.0:
		state_machine.transition_to("Attack")
