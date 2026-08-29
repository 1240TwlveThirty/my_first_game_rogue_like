extends State

@export var land_duration: float = 0.15

var timer: float = 0.0


func enter() -> void:
	actor.animated_sprite.play("land")
	actor.velocity.x = 0.0
	timer = land_duration


func physics_update(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		if actor.target:
			state_machine.transition_to("Chase")
		else:
			state_machine.transition_to("Idle")
