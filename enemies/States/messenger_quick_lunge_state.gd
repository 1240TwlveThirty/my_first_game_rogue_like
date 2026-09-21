extends State

## Один из вариантов ротации ближних атак Гонца (см. melee_rotation на
## messenger_chase_state.gd) - быстрый короткий выпад. Минимальный
## windup, короткое окно урона, но актор физически рвётся к игроку ВО
## ВРЕМЯ windup (в отличие от Combo/WideSwing, которые стоят на месте) -
## сам закрывает небольшую дистанцию, а не полагается на то, что игрок
## уже вплотную. Визуал - та же "attack_1" (единственный доступный клип,
## см. messenger_combo_state.gd про ограничение ассета), отличие
## исключительно в тайминге фаз и коротком рывке скорости.

enum Phase { WINDUP, ACTIVE, RECOVERY }

@export var lunge_speed: float = 500.0
@export var windup_duration: float = 0.12
@export var active_duration: float = 0.1
@export var recovery_duration: float = 0.2
@export var hitbox_offset_x: float = 18.0
@export var shape_offset_x: float = 26.0

var phase: Phase = Phase.WINDUP
var timer: float = 0.0
var _direction: float = 1.0


func enter() -> void:
	phase = Phase.WINDUP
	timer = windup_duration
	if actor.target:
		_direction = sign(actor.target.global_position.x - actor.global_position.x)
		actor.animated_sprite.flip_h = _direction < 0.0
	actor.animated_sprite.play("attack_1")


func exit() -> void:
	actor.attack_shape.set_deferred("disabled", true)
	actor.velocity.x = 0.0


func physics_update(delta: float) -> void:
	timer -= delta
	match phase:
		Phase.WINDUP:
			actor.velocity.x = _direction * lunge_speed
			if timer <= 0.0:
				_start_active()
		Phase.ACTIVE:
			actor.velocity.x = 0.0
			if timer <= 0.0:
				_start_recovery()
		Phase.RECOVERY:
			actor.velocity.x = 0.0
			if timer <= 0.0:
				_end_attack()


func _start_active() -> void:
	phase = Phase.ACTIVE
	timer = active_duration
	actor.attack_hitbox.position.x = absf(hitbox_offset_x) * _direction
	actor.attack_shape.position.x = absf(shape_offset_x) * _direction
	actor.attack_shape.set_deferred("disabled", false)


func _start_recovery() -> void:
	phase = Phase.RECOVERY
	timer = recovery_duration
	actor.attack_shape.set_deferred("disabled", true)


func _end_attack() -> void:
	actor.attack_cooldown_left = actor.attack_cooldown
	if actor.target:
		state_machine.transition_to("Chase")
	else:
		state_machine.transition_to("Idle")
