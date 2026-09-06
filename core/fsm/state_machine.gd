class_name StateMachine
extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary = {}
var freeze_time_left: float = 0.0

@onready var actor: CharacterBody2D = owner as CharacterBody2D


func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name] = child


func start() -> void:
	current_state = initial_state if initial_state else get_child(0)
	current_state.enter()


## Hit-stop: замораживает и анимацию, и логику состояний на duration секунд.
## Физику (move_and_slide) и таймеры буферов/комбо актор гейтит/тикает сам -
## StateMachine отвечает только за то, что происходит внутри физики самого
## состояния, и за проигрывание анимации.
func freeze(duration: float) -> void:
	freeze_time_left = duration
	actor.animated_sprite.speed_scale = 0.0


func physics_update(delta: float) -> void:
	if freeze_time_left > 0.0:
		freeze_time_left = max(freeze_time_left - delta, 0.0)
		if freeze_time_left <= 0.0:
			actor.animated_sprite.speed_scale = 1.0
		return

	current_state.physics_update(delta)


func transition_to(state_name: String) -> void:
	if not states.has(state_name):
		push_warning("StateMachine: состояние '%s' не найдено" % state_name)
		return

	if state_name == current_state.name:
		return

	current_state.exit()
	current_state = states[state_name]
	current_state.enter()
