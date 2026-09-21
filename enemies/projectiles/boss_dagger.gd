extends CharacterBody2D

## Кинжал Гонца - зеркало weapons/dagger.gd для боевого паттерна босса
## (прибивание игрока к стене), сделан ОТДЕЛЬНЫМ файлом по тому же
## принципу, что и enemies/projectiles/enemy_arrow.gd относительно
## weapons/arrow.gd: боссу не нужна логика зарядки во время TimeStop
## (группа frozen_dagger, charge_multiplier/max_charge_stacks) - только
## полёт, попадание по игроку и разбиваемость обычной атакой игрока (см.
## дочерний Area2D группы "boss_dagger" ниже и
## player.tscn.gd._on_attack_hitbox_area_entered()).
##
## В отличие от кинжала игрока, который ВСТРЕВАЕТ в стену и остаётся в
## мире (embedding нужен для его собственной механики прибивания ВРАГА) -
## кинжал Гонца при попадании в мир (не в игрока) просто queue_free(), тот
## же стиль, что и у enemies/projectiles/enemy_arrow.gd. Проверка "стена
## ЗА ИГРОКОМ" (для прибивания) - это отдельный от коллизии самого кинжала
## raycast вдоль вектора полёта из точки удара, тот же приём, что уже есть
## в dagger.gd._is_wall_behind(), только источник позиции - игрок, не враг.

const WORLD_LAYER_MASK: int = 1

@export var speed: float = 900.0
@export var damage: int = 1
@export var wall_check_distance: float = 100.0

var direction: Vector2 = Vector2.LEFT
var thrower: Node = null

@onready var break_hurtbox: Area2D = $BreakHurtbox


func _ready() -> void:
	break_hurtbox.add_to_group("boss_dagger")


## thrower - опциональная ссылка на бросившего (Messenger), нужна только
## для сброса actor.time_since_last_hit при подтверждённом попадании (см.
## _hit_player() ниже) - без этого evasion_punish_threshold мог бы сорвать
## Teleport даже при регулярных удачных бросках кинжала, потому что урон
## наносится напрямую через player.take_damage(), в обход
## messenger.gd._on_attack_hitbox_area_entered() (там обычно и происходит
## сброс для ближних атак).
func launch(from_position: Vector2, target_position: Vector2, thrower_actor: Node = null) -> void:
	global_position = from_position
	direction = (target_position - from_position).normalized()
	rotation = direction.angle()
	thrower = thrower_actor


func _physics_process(delta: float) -> void:
	if TimeStop.is_active and TimeStop.exempt_actor != self:
		return

	var collision := move_and_collide(direction * speed * delta)
	if collision != null:
		_handle_collision(collision)


func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider()
	if collider is Node and collider.is_in_group("player"):
		_hit_player(collider, collision.get_position())
	else:
		queue_free()


func _hit_player(player: Node, impact_position: Vector2) -> void:
	var should_pin: bool = _is_wall_behind(impact_position)

	# Флаг выставляется ДО урона - та же причина, что и в
	# dagger.gd._hit_enemy()/enemy.pin_next_stagger(): take_damage() может
	# сам перевести игрока в Hurt через сигнал damaged, и is_wall_pinned
	# обязан быть true ДО первого enter() - иначе повторный
	# transition_to("Hurt") будет no-op'ом (см. CLAUDE.md, 17.08.2026).
	if should_pin and player.has_method("mark_next_hurt_as_pinned"):
		player.mark_next_hurt_as_pinned()

	var hit_landed: bool = false
	if player.has_method("take_damage"):
		hit_landed = player.take_damage(damage, self)

	# pin_player() форсирует переход в Hurt в обход can_be_interrupted() -
	# но только если удар реально прошёл (не парирован, не поглощён
	# i-frames дэша) - иначе игрок, успешно уклонившийся или
	# запарировавший, всё равно оказался бы пригвождён без урона.
	if should_pin and hit_landed and player.has_method("pin_player"):
		player.pin_player()

	if hit_landed and thrower != null:
		thrower.time_since_last_hit = 0.0

	queue_free()


func _is_wall_behind(impact_position: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		impact_position,
		impact_position + direction * wall_check_distance,
		WORLD_LAYER_MASK
	)
	var result := space_state.intersect_ray(query)
	return not result.is_empty()
