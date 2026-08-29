extends State

const SAFETY_TIMEOUT: float = 1.5

var _safety_timer: float = 0.0


func can_be_interrupted() -> bool:
	return false


func enter() -> void:
	_safety_timer = 0.0
	actor.velocity.x = 0.0
	actor.animated_sprite.play("death")
	actor.animated_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


func exit() -> void:
	if actor.animated_sprite.animation_finished.is_connected(_on_animation_finished):
		actor.animated_sprite.animation_finished.disconnect(_on_animation_finished)


func physics_update(delta: float) -> void:
	actor.velocity.x = move_toward(actor.velocity.x, 0.0, actor.speed * delta * 4.0)

	_safety_timer += delta
	if _safety_timer >= SAFETY_TIMEOUT:
		push_warning("DeathState: анимация 'death' не завершилась вовремя, выхожу по таймауту")
		_finish()


func _on_animation_finished() -> void:
	_finish()


func _finish() -> void:
	actor.player_died.emit()
