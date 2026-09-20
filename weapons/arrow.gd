extends CharacterBody2D

## Изолированный спайк-прототип стрелы лука для глобальной остановки времени
## (VERTICAL_SLICE_PLAN.md, следующий этап после кинжала - референс "The
## World"). Полёт прямолинейный без гравитации, по стилю weapons/dagger.gd.
## Заморозка читается напрямую из автозагружаемого TimeStop - отдельного
## флага заморозки на самой стреле не нужно.

@export var speed: float = 1000.0
@export var damage: int = 2
@export var max_charge_stacks: int = 6

var direction: float = 1.0
var charge_multiplier: float = 1.0
var charge_stacks: int = 0

@onready var charge_hurtbox: Area2D = $ChargeHurtbox


func _ready() -> void:
	add_to_group("player_arrow")
	charge_hurtbox.add_to_group("frozen_arrow")


func launch(from_position: Vector2, launch_direction: float) -> void:
	global_position = from_position
	direction = launch_direction
	scale.x = direction


func _physics_process(delta: float) -> void:
	if TimeStop.is_active:
		return

	var collision := move_and_collide(Vector2(direction * speed * delta, 0.0))
	if collision != null:
		_handle_collision(collision)


func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider()
	if collider is Node and collider.is_in_group("enemy"):
		_hit_enemy(collider)
	else:
		queue_free()


func _hit_enemy(enemy: Node) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(int(round(damage * charge_multiplier)))
	queue_free()


## Вызывается из player.tscn.gd, когда AttackHitbox попадает по этой
## стреле, пока она группе "frozen_arrow" и TimeStop.is_active == true (см.
## _on_attack_hitbox_area_entered). Каждое попадание добавляет +1 стак,
## вплоть до max_charge_stacks - иначе урон одной стрелы можно было бы
## довести до абсурда бесконечными ударами за время остановки.
func add_charge() -> void:
	if charge_stacks >= max_charge_stacks:
		return
	charge_stacks += 1
	charge_multiplier = 1.0 + float(charge_stacks)
