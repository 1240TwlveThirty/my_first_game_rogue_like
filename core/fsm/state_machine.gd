class_name StateMachine
extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name] = child


func start() -> void:
	current_state = initial_state if initial_state else get_child(0)
	current_state.enter()


func physics_update(delta: float) -> void:
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
