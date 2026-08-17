extends State


func enter() -> void:
	_do_jump()


func physics_update(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var wall_dir : float = player.get_climbable_wall_direction()

	if wall_dir != 0.0 and player.wall_jump_grace_timer <= 0.0 and direction != -wall_dir:
		state_machine.transition_to("WallClimb")
		return

	player.velocity.y += player.gravity * delta

	if direction != 0.0:
		player.facing_direction = direction
		player.animated_sprite.flip_h = direction < 0.0
		player.velocity.x = direction * player.speed

	if Input.is_action_just_pressed("jump") and player.jumps_used < player.max_jumps:
		_do_jump()
		return

	if player.velocity.y >= 0.0:
		state_machine.transition_to("Fall")

	if Input.is_action_just_pressed("dash") and player.dash_cooldown_left <= 0.0:
		state_machine.transition_to("Dash")
		return

	if Input.is_action_just_pressed("Attack"):
		state_machine.transition_to("Attack")
		return


func _do_jump() -> void:
	player.velocity.y = player.jump_velocity
	player.jumps_used += 1
	player.animated_sprite.play("jump")
