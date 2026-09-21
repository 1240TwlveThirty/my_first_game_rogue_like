extends CharacterBody2D

## Снаряд лучника (архетип Archer, enemies/archer.gd). Прямолинейный полёт
## без гравитации, по стилю weapons/arrow.gd/dagger.gd игрока - но
## сознательно отдельный файл: у оружия игрока есть charge-механика во
## время TimeStop (группы frozen_arrow/frozen_dagger, charge_multiplier) -
## это специфика конкретно лука/кинжала игрока, для снаряда врага не
## нужна и не переносится. TimeStop.is_active гейтит движение как мировое
## правило, общее для любого актора (см. enemy.gd/arrow.gd), не как часть
## charge-системы.
##
## Направление не самонаводится в полёте - снап один раз в launch(), в
## момент выстрела (target_position приходит уже готовой точкой прицела
## от ArcherAttackState, которая знает своего единственного target
## напрямую, поэтому не нужен ProjectileAim.find_aim_direction() - та
## функция ищет ЛУЧШУЮ цель по группе "enemy" среди нескольких кандидатов,
## что здесь не требуется).

@export var speed: float = 700.0
@export var damage: int = 1

var direction: Vector2 = Vector2.LEFT


func launch(from_position: Vector2, target_position: Vector2) -> void:
	global_position = from_position
	direction = (target_position - from_position).normalized()
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if TimeStop.is_active and TimeStop.exempt_actor != self:
		return

	var collision := move_and_collide(direction * speed * delta)
	if collision != null:
		_handle_collision(collision)


func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider()
	if collider is Node and collider.is_in_group("player") and collider.has_method("take_damage"):
		collider.take_damage(damage)
	queue_free()
