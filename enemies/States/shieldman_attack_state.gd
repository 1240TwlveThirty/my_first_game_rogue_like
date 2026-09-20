extends State

## Отдельное состояние от enemies/States/attack_state.gd - структура
## (WINDUP/ACTIVE/RECOVERY) та же, но: (1) щит опускается на время замаха
## (shield_active = false - по заданию щит не активен, пока щитовик сам
## атакует), (2) анимация "attack" (весь Tarkusfullattack.png одним
## клипом), а не "attack_1", (3) hitbox_offset_x/shape_offset_x - ПЛЕЙСХОЛДЕР,
## пока не пересчитаны по силуэту Tarkus (в отличие от 19.2/28.2 у обычного
## Enemy, это не перемеренные под конкретный арт числа, а просто взятые как
## отправная точка - нужна подгонка в редакторе после того, как визуал будет
## виден на экране).

enum Phase { WINDUP, ACTIVE, RECOVERY }

@export var hitbox_offset_x: float = 19.2
@export var shape_offset_x: float = 28.2

var phase: Phase = Phase.WINDUP
var timer: float = 0.0
var _direction: float = 1.0


func enter() -> void:
	phase = Phase.WINDUP
	timer = actor.attack_windup
	actor.velocity.x = 0.0
	actor.shield_active = false

	_direction = sign(actor.target.global_position.x - actor.global_position.x)
	actor.facing_direction = _direction
	actor.animated_sprite.flip_h = _direction < 0.0
	actor.animated_sprite.play("attack")


func exit() -> void:
	actor.attack_shape.set_deferred("disabled", true)


func physics_update(delta: float) -> void:
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
				actor.attack_cooldown_left = actor.attack_cooldown
				_end_attack()


func _start_active() -> void:
	phase = Phase.ACTIVE
	timer = actor.attack_active_duration
	actor.attack_hitbox.position.x = hitbox_offset_x * _direction
	actor.attack_shape.position.x = shape_offset_x * _direction
	actor.attack_shape.set_deferred("disabled", false)


func _start_recovery() -> void:
	phase = Phase.RECOVERY
	timer = actor.attack_recovery
	actor.attack_shape.set_deferred("disabled", true)


func _end_attack() -> void:
	if actor.target:
		state_machine.transition_to("Chase")
	else:
		state_machine.transition_to("Idle")
