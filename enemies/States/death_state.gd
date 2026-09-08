extends State

const SAFETY_TIMEOUT: float = 1.5

var _safety_timer: float = 0.0


func enter() -> void:
	_safety_timer = 0.0
	actor.velocity.x = 0.0
	actor.modulate.a = 1.0
	actor.hurtbox_shape.set_deferred("disabled", true)
	actor.animated_sprite.play("death")
	actor.animated_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


func physics_update(delta: float) -> void:
	_safety_timer += delta
	# Анимация "death" зациклена в SpriteFrames (тот же баг, что и у игрока,
	# см. CLAUDE.md) - animation_finished никогда не срабатывает сам, выход
	# всегда идёт по SAFETY_TIMEOUT. Поэтому угасание считаем от него же,
	# а не от длительности анимации - иначе прозрачность не успевала бы
	# дойти до 0 к моменту queue_free().
	actor.modulate.a = clampf(1.0 - _safety_timer / SAFETY_TIMEOUT, 0.0, 1.0)
	if _safety_timer >= SAFETY_TIMEOUT:
		actor.modulate.a = 0.0
		actor.queue_free()


func _on_animation_finished() -> void:
	actor.modulate.a = 0.0
	actor.queue_free()
