extends State

## Отдельное состояние от enemies/States/idle_state.gd - в отличие от
## обычного Enemy, Shieldman поднимает щит в покое и показывает это
## анимацией "block", а не "idle". Логика перехода (ждать target) та же.


func enter() -> void:
	actor.velocity.x = 0.0
	actor.shield_active = true
	actor.animated_sprite.play("block")


func physics_update(_delta: float) -> void:
	if actor.target:
		state_machine.transition_to("Chase")
