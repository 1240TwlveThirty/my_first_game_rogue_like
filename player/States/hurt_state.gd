extends State

const SAFETY_TIMEOUT: float = 1.0  # на случай, если "hurt" не доиграет штатно

var _safety_timer: float = 0.0


func can_be_interrupted() -> bool:
	return false


func enter() -> void:
	_safety_timer = 0.0
	player.velocity.x = -player.facing_direction * player.hurt_knockback_speed
	player.animated_sprite.play("hurt")
	player.animated_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


func exit() -> void:
	if player.animated_sprite.animation_finished.is_connected(_on_animation_finished):
		player.animated_sprite.animation_finished.disconnect(_on_animation_finished)


func physics_update(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.speed * delta * 4.0)

	_safety_timer += delta
	if _safety_timer >= SAFETY_TIMEOUT:
		push_warning("HurtState: анимация 'hurt' не завершилась вовремя, выхожу по таймауту")
		_end_hurt()


func _on_animation_finished() -> void:
	_end_hurt()


func _end_hurt() -> void:
	if not player.is_on_floor():
		state_machine.transition_to("Fall")
		return

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		state_machine.transition_to("Run")
	else:
		state_machine.transition_to("Idle")
