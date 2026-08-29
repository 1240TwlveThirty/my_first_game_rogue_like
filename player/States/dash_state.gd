
extends State

var time_left: float = 0.0
var direction: float = 1.0


func enter() -> void:
	actor.animated_sprite.play("dash")
	direction = actor.facing_direction
	time_left = actor.dash_duration
	actor.velocity.y = 0.0


func physics_update(delta: float) -> void:
	actor.velocity.x = direction * actor.dash_speed
	actor.velocity.y = 0.0

	time_left -= delta
	if time_left <= 0.0:
		actor.dash_cooldown_left = actor.dash_cooldown
		_exit_to_next_state()


func _exit_to_next_state() -> void:
	if not actor.is_on_floor():
		state_machine.transition_to("Fall")
		return

	var move_input := Input.get_axis("move_left", "move_right")
	if move_input != 0.0:
		state_machine.transition_to("Run")
	else:
		state_machine.transition_to("Idle")
