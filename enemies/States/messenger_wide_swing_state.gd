extends State

## Другой вариант ротации ближних атак Гонца (см. melee_rotation на
## messenger_chase_state.gd) - широкий медленный замах. Длинный, ясно
## читаемый windup и заметно бОльшая дальность/длительность активного
## окна хитбокса, чем у Combo/QuickLunge - высокий риск для самого Гонца
## (долго "закоммичен", ничего не делает всё это время), но бьёт дальше и
## дольше держит угрозу. Один удар, не серия. Визуал - та же "attack_1"
## (см. messenger_combo_state.gd про ограничение ассета), тайминг и
## дальность хитбокса - единственное отличие от остальных вариантов.

enum Phase { WINDUP, ACTIVE, RECOVERY }

@export var windup_duration: float = 0.6
@export var active_duration: float = 0.25
@export var recovery_duration: float = 0.5
@export var hitbox_offset_x: float = 38.0
@export var shape_offset_x: float = 48.0

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
	actor.animated_sprite.play("attack_1")


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
