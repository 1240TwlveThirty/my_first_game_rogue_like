extends State

const SAFETY_TIMEOUT: float = 1.5

var _safety_timer: float = 0.0


func enter() -> void:
	_safety_timer = 0.0
	actor.velocity.x = 0.0
	actor.hurtbox_shape.set_deferred("disabled", true)
	actor.animated_sprite.play("death")
	actor.animated_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


func physics_update(delta: float) -> void:
	_safety_timer += delta
	if _safety_timer >= SAFETY_TIMEOUT:
		actor.queue_free()


func _on_animation_finished() -> void:
	actor.queue_free()
