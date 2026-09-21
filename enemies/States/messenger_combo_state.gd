extends State

## Комбо ближнего боя Гонца - фазовая структура WINDUP/ACTIVE/RECOVERY
## совпадает с player/States/heavy_attack_state.gd и enemies/States/
## attack_state.gd (честный, читаемый windup - не опционально для боя с
## боссом), но повторяется combo_hits раз с короткой паузой между ударами
## (PAUSE), а не одним циклом. Визуал каждого удара - анимация "attack_1"
## переигрывается заново (у placeholder Black Knight нет отдельных
## attack_2/3 - осознанное ограничение ассета, та же причина, что и в
## обычном attack_state.gd), удары отличаются только таймингом фаз, не
## анимацией.
##
## Успешное попадание НЕ сообщается сюда откуда-то извне и не читается
## отсюда наружу - сброс actor.time_since_last_hit происходит в
## messenger.gd._on_attack_hitbox_area_entered() (уже подключена в
## enemy.gd._ready() ко всем этим же area_entered на actor.attack_hitbox,
## который эта же state включает/выключает по таймеру ниже). Это
## состояние просто честно телеграфирует и разрешает хитбокс - реальное
## "попал/не попал" физически подтверждает Area2D сам, как и у любого
## другого Enemy.

enum Phase { WINDUP, ACTIVE, RECOVERY, PAUSE }

@export var combo_hits: int = 3
@export var hit_pause: float = 0.15
@export var hitbox_offset_x: float = 19.2
@export var shape_offset_x: float = 28.2

var phase: Phase = Phase.WINDUP
var timer: float = 0.0
var hits_left: int = 0
var _direction: float = 1.0


func enter() -> void:
	hits_left = combo_hits
	_start_windup()


func exit() -> void:
	actor.attack_shape.set_deferred("disabled", true)


func physics_update(delta: float) -> void:
	actor.velocity.x = 0.0
	timer -= delta
	match phase:
		Phase.WINDUP:
			if timer <= 0.0:
				_start_active()
		Phase.ACTIVE:
			if timer <= 0.0:
				_start_recovery()
		Phase.RECOVERY:
			if timer <= 0.0:
				hits_left -= 1
				if hits_left > 0:
					_start_pause()
				else:
					_end_combo()
		Phase.PAUSE:
			if timer <= 0.0:
				_start_windup()


func _start_windup() -> void:
	phase = Phase.WINDUP
	timer = actor.attack_windup
	if actor.target:
		_direction = sign(actor.target.global_position.x - actor.global_position.x)
		actor.animated_sprite.flip_h = _direction < 0.0
	actor.animated_sprite.play("attack_1")


func _start_active() -> void:
	phase = Phase.ACTIVE
	timer = actor.attack_active_duration
	# Тот же приём зеркалирования hitbox/shape, что и в attack_state.gd -
	# CollisionShape2D внутри AttackHitbox зеркалится отдельно от самого
	# Area2D, иначе при развороте влево хитбокс не уходит на нужную сторону.
	actor.attack_hitbox.position.x = absf(hitbox_offset_x) * _direction
	actor.attack_shape.position.x = absf(shape_offset_x) * _direction
	actor.attack_shape.set_deferred("disabled", false)


func _start_recovery() -> void:
	phase = Phase.RECOVERY
	timer = actor.attack_recovery
	actor.attack_shape.set_deferred("disabled", true)


func _start_pause() -> void:
	phase = Phase.PAUSE
	timer = hit_pause


func _end_combo() -> void:
	actor.attack_cooldown_left = actor.attack_cooldown
	if actor.target:
		state_machine.transition_to("Chase")
	else:
		state_machine.transition_to("Idle")
