extends State

@export var punish_multiplier: float = 2.5

var timer: float = 0.0
var is_punished: bool = false


func enter() -> void:
	var duration: float = actor.stagger_duration
	if is_punished:
		duration *= punish_multiplier
	is_punished = false

	timer = duration
	actor.velocity.x = 0.0
	actor.attack_shape.set_deferred("disabled", true)
	actor.animated_sprite.play("hurt")


func physics_update(delta: float) -> void:
	actor.velocity.x = 0.0
	timer -= delta
	if timer <= 0.0:
		if actor.target:
			state_machine.transition_to("Chase")
		else:
			state_machine.transition_to("Idle")
