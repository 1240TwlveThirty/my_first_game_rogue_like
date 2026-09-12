extends CharacterBody2D

## Изолированный спайк-прототип кинжала (VERTICAL_SLICE_PLAN.md, Этап 1):
## бросок -> зацеп в стену, попадание во врага с прибиванием у стены.
## Без пула зарядов, без магнитного возврата, без связи с буллет-таймом
## лука - это следующие отдельные шаги, сюда сознательно не добавлены.

const WORLD_LAYER_MASK: int = 1

@export var speed: float = 900.0
@export var damage: int = 1
@export var wall_check_distance: float = 100.0

var direction: float = 1.0
var is_stuck: bool = false


func launch(from_position: Vector2, launch_direction: float) -> void:
	global_position = from_position
	direction = launch_direction
	scale.x = direction


func _physics_process(delta: float) -> void:
	if is_stuck:
		return

	var collision := move_and_collide(Vector2(direction * speed * delta, 0.0))
	if collision != null:
		_handle_collision(collision)


func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider()
	if collider is Node and collider.is_in_group("enemy"):
		_hit_enemy(collider, collision.get_position())
	else:
		_stick(collision)


func _hit_enemy(enemy: Node, impact_position: Vector2) -> void:
	# Флаг прибивания выставляется ДО урона - take_damage() сам переведёт
	# врага в Stagger через сигнал damaged, второй transition_to("Stagger")
	# после урона был бы no-op (переход в уже активное состояние).
	if _is_wall_behind(impact_position) and enemy.has_method("pin_next_stagger"):
		enemy.pin_next_stagger()

	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)

	queue_free()


func _is_wall_behind(impact_position: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		impact_position,
		impact_position + Vector2(direction * wall_check_distance, 0.0),
		WORLD_LAYER_MASK
	)
	var result := space_state.intersect_ray(query)
	return not result.is_empty()


func _stick(collision: KinematicCollision2D) -> void:
	global_position = collision.get_position()
	velocity = Vector2.ZERO
	is_stuck = true
