extends State

var timer: float = 0.0


func can_be_interrupted() -> bool:
	return timer > player.attack_duration / 2.0


func enter() -> void:
	player.velocity.x = 0.0
	timer = player.attack_duration

	var animation_name := "attack_%d" % (player.combo_step + 1)
	player.animated_sprite.play(animation_name)

	player.attack_hitbox.position.x = player.attack_reach * player.facing_direction
	player.attack_shape.disabled = false


func exit() -> void:
	player.attack_shape.disabled = true


func physics_update(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		_end_attack()


func _end_attack() -> void:
	player.combo_step = (player.combo_step + 1) % player.combo_max_steps
	player.combo_reset_timer = player.combo_reset_time

	if not player.is_on_floor():
		state_machine.transition_to("Fall")
		return

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		state_machine.transition_to("Run")
	else:
		state_machine.transition_to("Idle")
