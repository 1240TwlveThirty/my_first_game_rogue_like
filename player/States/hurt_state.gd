extends State

const SAFETY_TIMEOUT: float = 1.0  # на случай, если "hurt" не доиграет штатно

## Прибивание к стене броском кинжала Гонца (enemies/projectiles/
## boss_dagger.gd) - зеркало enemy-стороны (is_pinned/pin_duration на
## enemies/States/stagger_state.gd). Выставляется ИЗВНЕ через
## player.tscn.gd.mark_next_hurt_as_pinned() ДО фактического входа в это
## состояние (см. комментарий там же про причину). can_be_interrupted()
## НЕ менял - он и так безусловно false для любого Hurt, что уже строже,
## чем требуется ("false на всё время pin'а" - подмножество уже
## существующего поведения).
@export var wall_pin_duration: float = 1.2

var is_wall_pinned: bool = false
var _safety_timer: float = 0.0


func can_be_interrupted() -> bool:
	return false


func enter() -> void:
	_safety_timer = 0.0
	if is_wall_pinned:
		actor.velocity.x = 0.0
	else:
		actor.velocity.x = -actor.facing_direction * actor.hurt_knockback_speed
	actor.animated_sprite.play("hurt")
	actor.animated_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


func exit() -> void:
	if actor.animated_sprite.animation_finished.is_connected(_on_animation_finished):
		actor.animated_sprite.animation_finished.disconnect(_on_animation_finished)
	is_wall_pinned = false


func physics_update(delta: float) -> void:
	if is_wall_pinned:
		actor.velocity.x = 0.0
	else:
		actor.velocity.x = move_toward(actor.velocity.x, 0.0, actor.speed * delta * 4.0)

	_safety_timer += delta
	# Пока прибит - длительность считает wall_pin_duration, а не короткий
	# клип "hurt" (см. _on_animation_finished ниже, сигнал игнорируется во
	# время pin'а) - это САМ механизм, не защитный таймаут поверх сигнала.
	var timeout: float = wall_pin_duration if is_wall_pinned else SAFETY_TIMEOUT
	if _safety_timer >= timeout:
		if not is_wall_pinned:
			push_warning("HurtState: анимация 'hurt' не завершилась вовремя, выхожу по таймауту")
		_end_hurt()


func _on_animation_finished() -> void:
	# "hurt" короче wall_pin_duration - если выйти по сигналу, pin
	# закончился бы раньше срока. Ждём таймер в physics_update() вместо
	# этого; анимация просто держится на последнем кадре (loop=false).
	if not is_wall_pinned:
		_end_hurt()


func _end_hurt() -> void:
	if not actor.is_on_floor():
		state_machine.transition_to("Fall")
		return

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		state_machine.transition_to("Run")
	else:
		state_machine.transition_to("Idle")
