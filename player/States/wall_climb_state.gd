extends State

var wall_direction: float = 0.0  # +1 - стена справа, -1 - слева. Фиксируется при входе.


func enter() -> void:
	wall_direction = player.get_climbable_wall_direction()
	player.velocity.y = 0.0
	player.velocity.x = 0.0
	player.animated_sprite.play("fall_light")  # ВРЕМЕННО: нет отдельной анимации wall-slide в ассете
	player.animated_sprite.flip_h = wall_direction < 0.0

	player.jumps_used = 0  # раскомментировать, если хотите обновлять прыжки при захвате стены


func physics_update(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	if Input.is_action_just_pressed("jump"):
		_wall_jump()
		return

	if direction == -wall_direction or not player.is_on_wall():
		state_machine.transition_to("Fall")
		return

	var target_speed : float = player.wall_slide_speed
	if Input.is_action_pressed("move_down"):
		target_speed = player.wall_slide_fast_speed

	player.velocity.y = move_toward(player.velocity.y, target_speed, player.wall_slide_acceleration * delta)
	player.velocity.x = 0.0

	if player.is_on_floor():
		state_machine.transition_to("Land")


func _wall_jump() -> void:
	player.velocity.x = -wall_direction * player.wall_jump_horizontal_speed
	player.velocity.y = player.wall_jump_vertical_velocity
	player.facing_direction = -wall_direction
	player.animated_sprite.flip_h = player.facing_direction < 0.0
	player.wall_jump_grace_timer = player.wall_jump_grace_time
	state_machine.transition_to("Fall")
