extends State

@export var active_start_ratio: float = 0.3
@export var active_end_ratio: float = 0.6

var timer: float = 0.0
var duration: float = 0.0
var hitbox_active: bool = false


func can_be_interrupted() -> bool:
	return timer > duration / 2.0


func enter() -> void:
	actor.velocity.x = 0.0
	actor.current_attack_damage = actor.attack_damage

	actor.heavy_combo_step = 0
	actor.heavy_combo_reset_timer = 0.0

	var animation_name := "attack_%d" % (actor.combo_step + 1)
	actor.animated_sprite.play(animation_name)
	duration = get_animation_duration(actor.animated_sprite, animation_name)
	timer = duration

	actor.attack_hitbox.position.x = actor.attack_reach * actor.facing_direction
	hitbox_active = false
	actor.attack_shape.set_deferred("disabled", true)


func exit() -> void:
	actor.attack_shape.set_deferred("disabled", true)
	hitbox_active = false


func physics_update(delta: float) -> void:
	timer -= delta

	var elapsed := duration - timer
	var should_be_active := elapsed >= duration * active_start_ratio and elapsed <= duration * active_end_ratio
	if should_be_active != hitbox_active:
		hitbox_active = should_be_active
		actor.attack_shape.set_deferred("disabled", not hitbox_active)

	if timer <= 0.0:
		_end_attack()

func _end_attack() -> void:
	actor.combo_step = (actor.combo_step + 1) % actor.combo_max_steps
	actor.combo_reset_timer = actor.combo_reset_time

	if actor.consume_buffered_attack():
		state_machine.transition_to("Attack")
		return

	if actor.consume_buffered_heavy_attack():
		state_machine.transition_to("HeavyAttack")
		return

	if not actor.is_on_floor():
		state_machine.transition_to("Fall")
		return

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		state_machine.transition_to("Run")
	else:
		state_machine.transition_to("Idle")
