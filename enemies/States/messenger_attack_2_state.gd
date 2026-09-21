extends State

## Четвёртый вариант ротации ближних атак Гонца (см. melee_rotation на
## messenger_chase_state.gd) - широкий горизонтальный замах, визуально
## отдельный клип "attack_2" (art/Bosses/Messenger, _Attack2NoMovement.png,
## 6 кадров) - НЕ переигрывание "attack_1" под другим именем, как
## Combo/QuickLunge/WideSwing. Структура WINDUP/ACTIVE/RECOVERY та же, что
## у остальных вариантов, но тайминг подобран так, чтобы ощущаться иначе,
## не только цифрами: умеренный windup (короче, чем у WideSwing - труднее
## среагировать заранее), но САМОЕ ДОЛГОЕ окно ACTIVE среди всех четырёх
## вариантов (0.35с против 0.15/0.1/0.25) - широкая дуга удара физически
## угрожает дольше, чем мгновенный укол или even один длинный замах
## WideSwing. Дальность - между Combo и WideSwing, не крайняя ни в одну
## сторону: разница читается через длительность угрозы, а не только через
## охват.

enum Phase { WINDUP, ACTIVE, RECOVERY }

@export var windup_duration: float = 0.35
@export var active_duration: float = 0.35
@export var recovery_duration: float = 0.4
@export var hitbox_offset_x: float = 30.0
@export var shape_offset_x: float = 40.0

var phase: Phase = Phase.WINDUP
var timer: float = 0.0
var _direction: float = 1.0


func enter() -> void:
	phase = Phase.WINDUP
	timer = windup_duration
	actor.velocity.x = 0.0
	if actor.target:
		_direction = sign(actor.target.global_position.x - actor.global_position.x)
		actor.animated_sprite.flip_h = _direction < 0.0
	actor.animated_sprite.play("attack_2")


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
