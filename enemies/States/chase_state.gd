extends State


func enter() -> void:
	actor.animated_sprite.play("run")


func physics_update(_delta: float) -> void:
	if not actor.target:
		state_machine.transition_to("Idle")
		return

	if actor.in_attack_range and actor.attack_cooldown_left <= 0.0:
		state_machine.transition_to("Attack")
		return

	var direction: float = sign(actor.target.global_position.x - actor.global_position.x)
	actor.animated_sprite.flip_h = direction < 0.0
	actor.velocity.x = direction * actor.speed
