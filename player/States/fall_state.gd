extends State


func enter() -> void:
	player.animated_sprite.play("fall_light")


func physics_update(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var wall_dir : float = player.get_climbable_wall_direction()

	if wall_dir != 0.0 and player.wall_jump_grace_timer <= 0.0 and direction != -wall_dir:
		state_machine.transition_to("WallClimb")
		return

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

	if direction != 0.0:
		player.facing_direction = direction
		player.animated_sprite.flip_h = direction < 0.0
		player.velocity.x = direction * player.speed

	if player.is_on_floor():
		state_machine.transition_to("Land")
