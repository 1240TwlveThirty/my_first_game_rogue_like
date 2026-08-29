extends State

var timer: float = 0.0


func can_be_interrupted() -> bool:
	return timer > actor.heavy_attack_duration / 2.0


func enter() -> void:
	actor.velocity.x = 0.0
	timer = actor.heavy_attack_duration
	actor.current_attack_damage = actor.heavy_attack_damage

	actor.combo_step = 0
	actor.combo_reset_timer = 0.0

	var animation_name := "heavy_attack_%d" % (actor.heavy_combo_step + 1)
	actor.animated_sprite.play(animation_name)

	actor.attack_hitbox.position.x = actor.heavy_attack_reach * actor.facing_direction
	actor.attack_shape.set_deferred("disabled", false)


func exit() -> void:
	actor.attack_shape.set_deferred("disabled", true)


func physics_update(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		_end_attack()


func _end_attack() -> void:
	actor.heavy_combo_step = (actor.heavy_combo_step + 1) % actor.heavy_combo_max_steps
	actor.heavy_combo_reset_timer = actor.heavy_combo_reset_time

	if not actor.is_on_floor():
		state_machine.transition_to("Fall")
		return

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		state_machine.transition_to("Run")
	else:
		state_machine.transition_to("Idle")
