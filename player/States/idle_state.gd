extends State


func enter() -> void:
	actor.animated_sprite.play("idle")
	actor.velocity.x = 0.0


func physics_update(delta: float) -> void:

	if _check_global_transitions():
		return

	actor.velocity.y += actor.gravity * delta

	if not actor.is_on_floor():
		state_machine.transition_to("Fall")
		return

	if Input.is_action_just_pressed("parry"):
		state_machine.transition_to("Parry")
		return

	if actor.consume_buffered_heavy_attack():
		state_machine.transition_to("HeavyAttack")
		return

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		state_machine.transition_to("Run")
