extends State

enum Phase { WINDUP, ACTIVE, RECOVERY }

var phase: Phase = Phase.WINDUP
var timer: float = 0.0
var _direction: float = 1.0


func enter() -> void:
	phase = Phase.WINDUP
	timer = actor.attack_windup
	actor.velocity.x = 0.0

	_direction = sign(actor.target.global_position.x - actor.global_position.x)
	actor.animated_sprite.flip_h = _direction < 0.0
	actor.animated_sprite.play("attack_1")


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
	actor.attack_hitbox.position.x = abs(30.0) * _direction
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
