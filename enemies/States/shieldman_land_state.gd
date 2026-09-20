extends State

## Отдельное состояние от enemies/States/land_state.gd - тот играет
## анимацию "land", которой нет в наборе Tarkus (пак не содержит отдельной
## анимации приземления). Логика-мост та же самая (короткая пауза перед
## Chase/Idle), только вместо "land" играем "block" - у щитовика это и так
## дефолтная поза покоя.

@export var land_duration: float = 0.15

var timer: float = 0.0


func enter() -> void:
	actor.animated_sprite.play("block")
	actor.velocity.x = 0.0
	timer = land_duration


func physics_update(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		if actor.target:
			state_machine.transition_to("Chase")
		else:
			state_machine.transition_to("Idle")
