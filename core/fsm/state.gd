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
