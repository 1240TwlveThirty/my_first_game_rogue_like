extends State

## Отдельное состояние от enemies/States/attack_state.gd - Лучник не бьёт
## в ближнем бою, actor.attack_hitbox остаётся выключенным всегда (узел
## существует в сцене только потому, что enemy.gd._ready() безусловно
## обращается к $AttackHitbox через @onready - без него список onready-
## полей упал бы при старте сцены).
##
## Длительность состояния = реальная длительность анимации "fire"
## (get_animation_duration() из базового State, тот же принцип, что и у
## melee-атак игрока/врага с 29.08.2026 - не хранить длительность атаки
## отдельной цифрой, рассинхронизирующейся с ассетом). Выстрел происходит
## сразу при входе в состояние, не на конкретном кадре анимации - по
## прямому разрешению на упрощение для первого теста; если позже
## понадобится точный кадр релиза тетивы, сюда добавится фазовый таймер
## по образцу WINDUP/ACTIVE/RECOVERY у attack_state.gd.

const ENEMY_ARROW_SCENE: PackedScene = preload("res://enemies/projectiles/enemy_arrow.tscn")

## Точка вылета стрелы относительно actor.global_position - примерная
## высота лука, стартовая цифра без подгонки под конкретный кадр анимации
## "fire" (кадры на сетке 64x64, персонаж занимает не весь кадр по высоте -
## см. CLAUDE.md про подгонку коллайдеров врагов). Нужна ручная подгонка
## в редакторе, когда лучник будет виден на экране.
@export var spawn_offset: Vector2 = Vector2(0.0, -20.0)

var timer: float = 0.0


func enter() -> void:
	actor.velocity.x = 0.0

	var direction: float = sign(actor.target.global_position.x - actor.global_position.x)
	actor.animated_sprite.flip_h = direction < 0.0
	actor.animated_sprite.play("fire")
	timer = get_animation_duration(actor.animated_sprite, "fire")

	_shoot()


func physics_update(delta: float) -> void:
	actor.velocity.x = 0.0
	timer -= delta
	if timer <= 0.0:
		actor.attack_cooldown_left = actor.attack_cooldown
		if actor.target:
			state_machine.transition_to("Chase")
		else:
			state_machine.transition_to("Idle")


## Целится в actor.target напрямую (единственная известная цель), а не
## через ProjectileAim.find_aim_direction() - та функция ищет ЛУЧШУЮ цель
## по углу/дистанции среди всех узлов группы "enemy", что уместно для
## оружия игрока (может стрелять в любого врага на экране), но избыточно
## здесь: у лучника уже есть конкретный target из DetectionZone. aim_point
## берётся из target.hurtbox_shape (если есть), а не global_position - та
## же причина, что и в projectile_aim.gd: global_position игрока/врага не
## обязательно совпадает с центром тела.
func _shoot() -> void:
	if not actor.target:
		return

	var aim_point: Vector2 = actor.target.global_position
	var target_hurtbox: Node = actor.target.get("hurtbox_shape")
	if target_hurtbox is Node2D:
		aim_point = target_hurtbox.global_position

	var arrow: Node2D = ENEMY_ARROW_SCENE.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.launch(actor.global_position + spawn_offset, aim_point)
