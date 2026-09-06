extends State


func enter() -> void:
	actor.animated_sprite.play("run")


func physics_update(delta: float) -> void:

	if _check_global_transitions():
		return

	actor.velocity.y += actor.gravity * delta

	if not actor.is_on_floor():
		state_machine.transition_to("Fall")
		return

	var direction := Input.get_axis("move_left", "move_right")
	if direction == 0.0:
		state_machine.transition_to("Idle")
		return

	if Input.is_action_just_pressed("parry"):
		state_machine.transition_to("Parry")
		return

	if actor.consume_buffered_heavy_attack():
		state_machine.transition_to("HeavyAttack")
		return


	actor.facing_direction = direction
	actor.animated_sprite.flip_h = direction < 0.0
	actor.velocity.x = direction * actor.speed
