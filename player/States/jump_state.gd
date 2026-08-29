extends State


func enter() -> void:
	_do_jump()


func physics_update(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var wall_dir : float = actor.get_climbable_wall_direction()

	if wall_dir != 0.0 and actor.wall_jump_grace_timer <= 0.0 and direction != -wall_dir:
		state_machine.transition_to("WallClimb")
		return

	actor.velocity.y += actor.gravity * delta

	if direction != 0.0:
		actor.facing_direction = direction
		actor.animated_sprite.flip_h = direction < 0.0
		actor.velocity.x = direction * actor.speed

	if Input.is_action_just_pressed("jump") and actor.jumps_used < actor.max_jumps:
		_do_jump()
		return

	if actor.velocity.y >= 0.0:
		state_machine.transition_to("Fall")

	if Input.is_action_just_pressed("dash") and actor.dash_cooldown_left <= 0.0:
		state_machine.transition_to("Dash")
		return

	if Input.is_action_just_pressed("parry"):
		state_machine.transition_to("Parry")
		return

	if Input.is_action_just_pressed("heavy_attack"):
		state_machine.transition_to("HeavyAttack")
		return

	if Input.is_action_just_pressed("Attack"):
		state_machine.transition_to("Attack")
		return


func _do_jump() -> void:
	actor.velocity.y = actor.jump_velocity
	actor.jumps_used += 1
	actor.animated_sprite.play("jump")
