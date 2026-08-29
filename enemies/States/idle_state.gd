extends State


func enter() -> void:
	actor.velocity.x = 0.0
	actor.animated_sprite.play("idle")


func physics_update(_delta: float) -> void:
	if actor.target:
		state_machine.transition_to("Chase")
