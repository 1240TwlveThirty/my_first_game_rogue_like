class_name State
extends Node

## Базовый класс для всех состояний игрока.
## Конкретные состояния (Idle, Run, Jump...) наследуются от него.

@onready var player: CharacterBody2D = owner as CharacterBody2D
@onready var state_machine: StateMachine = get_parent() as StateMachine


func enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
