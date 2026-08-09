extends Node
class_name HealthComponent

@export var max_health: int = 5

var current_health: int

signal health_changed(current: int, max: int)
signal died


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()
