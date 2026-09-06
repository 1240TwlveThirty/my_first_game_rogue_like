class_name State
extends Node

## Базовый класс для всех состояний игрока.
## Конкретные состояния (Idle, Run, Jump...) наследуются от него.

@onready var actor: CharacterBody2D = owner as CharacterBody2D
@onready var state_machine: StateMachine = get_parent() as StateMachine


func try_parry() -> bool:
	return false


## Возвращает реальную длительность анимации (в секундах), вычисленную из
## числа кадров и скорости проигрывания в SpriteFrames. Использовать вместо
## хранения длительности атаки как отдельного магического числа - иначе оно
## неизбежно рассинхронизируется с анимацией при любой правке ассета.
func get_animation_duration(sprite: AnimatedSprite2D, animation_name: String) -> float:
	var frames := sprite.sprite_frames
	var speed := frames.get_animation_speed(animation_name)
	if speed <= 0.0:
		return 0.0
	return frames.get_frame_count(animation_name) / speed


func enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func can_be_interrupted() -> bool:
	return true


## Общие для Idle/Run/Fall проверки глобальных переходов (jump, dash,
## лёгкая атака) - в этих трёх состояниях они дословно совпадают и всегда
## идут одной подряд идущей группой. Возвращает true, если переход
## произошёл - вызывающий код должен сразу сделать return.
## Jump этот метод не использует: там повторный прыжок в воздухе зовёт
## _do_jump() напрямую вместо transition_to("Jump") (см. нюанс с
## транзишном в уже активное состояние), а проверка атаки в Jump стоит
## после parry/heavy attack, а не перед ними - объединение изменило бы
## порядок проверок и реально повлияло бы на исход при одновременном вводе.
func _check_global_transitions() -> bool:
	if Input.is_action_just_pressed("jump") and actor.jumps_used < actor.max_jumps:
		state_machine.transition_to("Jump")
		return true

	if Input.is_action_just_pressed("dash") and actor.dash_cooldown_left <= 0.0:
		state_machine.transition_to("Dash")
		return true

	if actor.consume_buffered_attack():
		state_machine.transition_to("Attack")
		return true

	return false
