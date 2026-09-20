extends State

## Дефолт 1.0 сохраняет старое поведение (атака всегда, как только готов
## кулдаун и цель в радиусе) - у обычного Enemy это значение не трогается
## (см. enemy.tscn). У Shieldman - свой shieldman_chase_state.gd с тем же
## полем, выставленным заметно ниже.
@export var attack_probability: float = 1.0


func enter() -> void:
	actor.animated_sprite.play("run")


func physics_update(_delta: float) -> void:
	if not actor.target:
		state_machine.transition_to("Idle")
		return

	if actor.in_attack_range and actor.attack_cooldown_left <= 0.0:
		# randf() перепроверялся бы каждый физический кадр, пока условие
		# истинно - при 60 fps это практически гарантированная атака в
		# первые доли секунды даже с низкой attack_probability. Поэтому при
		# провале броска не оставляем cooldown на 0 (что дало бы reroll на
		# следующем кадре), а списываем это окно ожидания целиком - следующая
		# попытка будет не раньше, чем через полный attack_cooldown.
		if randf() < attack_probability:
			state_machine.transition_to("Attack")
			return
		actor.attack_cooldown_left = actor.attack_cooldown

	var delta_x: float = actor.target.global_position.x - actor.global_position.x
	if abs(delta_x) < actor.horizontal_deadzone:
		actor.velocity.x = 0.0
		return

	var direction: float = sign(delta_x)
	actor.animated_sprite.flip_h = direction < 0.0
	actor.velocity.x = direction * actor.speed
