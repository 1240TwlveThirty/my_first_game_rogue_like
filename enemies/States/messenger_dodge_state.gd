extends State

## Реактивный уклоняющийся рывок Гонца - чисто оборонительная механика,
## БЕЗ урона при контакте (в отличие от messenger_quick_lunge_state.gd -
## тот уже покрывает наступательный "рывок с уроном" из исходной
## задумки, дублировать здесь не нужно). Триггер живёт в
## messenger.gd._physics_process() (централизованная проверка, тот же
## принцип, что и evasion_punish_threshold), не здесь - это состояние
## только исполняет сам рывок.
##
## Двигается прямолинейно ОТ target на всё время dodge_duration.

@export var dodge_speed: float = 550.0
@export var dodge_duration: float = 0.25
@export var dodge_cooldown: float = 1.5

var timer: float = 0.0
var _direction: float = 1.0


func can_be_interrupted() -> bool:
	return false


func enter() -> void:
	timer = dodge_duration
	if actor.target:
		_direction = -sign(actor.target.global_position.x - actor.global_position.x)
		actor.animated_sprite.flip_h = _direction < 0.0
	actor.animated_sprite.play("run")
	actor.is_invulnerable = true


## Safety-fallback, если Dodge прервали раньше своего конца (тот же
## паттерн, что и в player/States/dash_state.gd) - cooldown при этом НЕ
## трогаем здесь, он выставляется по факту честного завершения рывка в
## physics_update() ниже, как и dash_cooldown_left у игрока.
func exit() -> void:
	actor.is_invulnerable = false


func physics_update(delta: float) -> void:
	actor.velocity.x = _direction * dodge_speed
	timer -= delta
	if timer <= 0.0:
		actor.dodge_cooldown_left = dodge_cooldown
		if actor.target:
			state_machine.transition_to("Chase")
		else:
			state_machine.transition_to("Idle")
