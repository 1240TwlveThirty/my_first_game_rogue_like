
extends State

@export var invulnerable_ratio: float = 0.65  # доля dash_duration, на которую активны i-frames

var time_left: float = 0.0
var direction: float = 1.0
var _invulnerable_until_time_left: float = 0.0


func enter() -> void:
	actor.animated_sprite.play("dash")
	direction = actor.facing_direction
	time_left = actor.dash_duration
	actor.velocity.y = 0.0

	actor.is_invulnerable = true
	_invulnerable_until_time_left = actor.dash_duration * (1.0 - invulnerable_ratio)


func exit() -> void:
	actor.is_invulnerable = false  # safety-fallback, если Dash прервали раньше своего конца


func physics_update(delta: float) -> void:
	actor.velocity.x = direction * actor.dash_speed
	actor.velocity.y = 0.0

	time_left -= delta

	if actor.is_invulnerable and time_left <= _invulnerable_until_time_left:
		actor.is_invulnerable = false

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
