extends State

@export var land_duration: float = 0.15

var timer: float = 0.0


func enter() -> void:
	player.animated_sprite.play("land")
	player.velocity.x = 0.0
	timer = land_duration


func physics_update(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		var direction := Input.get_axis("move_left", "move_right")
		if direction != 0.0:
			state_machine.transition_to("Run")
		else:
			state_machine.transition_to("Idle")
