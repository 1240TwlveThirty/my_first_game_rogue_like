extends State


func enter() -> void:
	player.animated_sprite.play("idle")
	player.velocity.x = 0.0


func physics_update(delta: float) -> void:

	if Input.is_action_just_pressed("jump") and player.jumps_used < player.max_jumps:
		state_machine.transition_to("Jump")
		return

	if Input.is_action_just_pressed("dash") and player.dash_cooldown_left <= 0.0:
		state_machine.transition_to("Dash")
		return

	if Input.is_action_just_pressed("Attack"):
		state_machine.transition_to("Attack")
		return

	player.velocity.y += player.gravity * delta

	if not player.is_on_floor():
		state_machine.transition_to("Fall")
		return

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		state_machine.transition_to("Run")
