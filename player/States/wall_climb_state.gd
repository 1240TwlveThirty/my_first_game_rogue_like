extends State

var wall_direction: float = 0.0  # +1 - стена справа, -1 - слева. Фиксируется при входе.


func enter() -> void:
	wall_direction = actor.get_climbable_wall_direction()
	actor.velocity.y = 0.0
	actor.velocity.x = 0.0
	actor.animated_sprite.play("fall_light")  # ВРЕМЕННО: нет отдельной анимации wall-slide в ассете
	actor.animated_sprite.flip_h = wall_direction < 0.0

	actor.jumps_used = 0  # раскомментировать, если хотите обновлять прыжки при захвате стены


func physics_update(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	if Input.is_action_just_pressed("jump"):
		_wall_jump()
		return

	if direction == -wall_direction or not actor.is_on_wall():
		state_machine.transition_to("Fall")
		return

	var target_speed : float = actor.wall_slide_speed
	if Input.is_action_pressed("move_down"):
		target_speed = actor.wall_slide_fast_speed

	actor.velocity.y = move_toward(actor.velocity.y, target_speed, actor.wall_slide_acceleration * delta)
	actor.velocity.x = 0.0

	if actor.is_on_floor():
		state_machine.transition_to("Land")


func _wall_jump() -> void:
	actor.velocity.x = -wall_direction * actor.wall_jump_horizontal_speed
	actor.velocity.y = actor.wall_jump_vertical_velocity
	actor.facing_direction = -wall_direction
	actor.animated_sprite.flip_h = actor.facing_direction < 0.0
	actor.wall_jump_grace_timer = actor.wall_jump_grace_time
	state_machine.transition_to("Fall")
