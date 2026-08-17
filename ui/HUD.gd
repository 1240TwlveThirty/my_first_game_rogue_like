extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/HealthBar


func setup(current_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health


func _on_health_changed(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
