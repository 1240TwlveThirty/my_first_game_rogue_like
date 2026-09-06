extends Camera2D

@export var shake_strength: float = 8.0
@export var shake_duration: float = 0.15

var _shake_timer: float = 0.0


func shake() -> void:
	_shake_timer = shake_duration


func _physics_process(delta: float) -> void:
	if _shake_timer <= 0.0:
		offset = Vector2.ZERO
		return

	_shake_timer -= delta
	var falloff := _shake_timer / shake_duration
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength * falloff
