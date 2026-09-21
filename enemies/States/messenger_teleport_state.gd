extends State

## Расплата за уклонение (messenger.gd._physics_process(): time_since_last_hit >=
## evasion_punish_threshold, тикает и проверяется централизованно там, не
## здесь). На время всего паттерна Гонец берёт
## TimeStop-исключение через exempt_actor (autoload/time_stop.gd) - весь
## остальной мир, включая игрока, физически замирает (player.tscn.gd
## гейтит собственный _physics_process тем же TimeStop.exempt_actor !=
## self). Несколько дискретных скачков позиции вокруг игрока, затем
## телепорт вплотную и ГАРАНТИРОВАННЫЙ удар напрямую (не через
## MessengerComboState с честным windup - это осознанно нечитаемая,
## непредотвратимая через блок/уклонение расплата).
##
## Гарантированный удар вызывает actor.target.take_damage()/оба
## state_machine.freeze() НАПРЯМУЮ, минуя area_entered/AttackHitbox -
## решение объяснено в чате: физическая коллизия после случайного
## телепорт-скачка зависит от точности позиционирования и требует лишнего
## кадра на срабатывание Area2D-сигнала, что противоречит слову
## "гарантированный". Прямой вызов - тот же самый эффект (те же две
## функции, что вызвал бы обычный удар через Enemy._on_attack_hitbox_area_entered),
## просто без физического посредника. take_damage() по-прежнему уважает
## is_invulnerable (i-frames дэша) и try_parry() у игрока - это тот же
## путь урона, что и у честной атаки, а не принудительный бесплатный урон
## в обход существующих механик защиты.
##
## Валидность точки скачка - _do_hop() до присвоения позиции пускает
## raycast вниз (_has_floor_below(), тот же общий приём, что и у
## dagger.gd._is_wall_behind(), только луч вниз, а не вдоль полёта). Если
## пола не нашлось в пределах max_hop_fall_check - просто не двигаемся в
## этом скачке (остаёмся на текущей позиции), hops_left всё равно
## расходуется по бюджету - гарантирует, что паттерн не зависнет в
## ожидании валидной точки; следующий _do_hop() на следующем hop_interval
## подберёт новую случайную точку заново.
##
## Гравитация - Enemy._physics_process() продолжает копить velocity.y
## обычным образом даже во время Teleport (TimeStop гейтит только чужих
## акторов, не собственную физику Гонца). Между скачками (hop_interval)
## это могло бы просадить актора вниз до следующего _do_hop(), портя
## визуально рассчитанные позиции. Фикс - НЕ отдельный was_time_stopped-флаг
## (той edge-detection здесь не нужно - в отличие от animated_sprite.speed_scale,
## velocity.y не persist-состояние, которое надо восстанавливать при
## выходе, оно просто пересчитывается заново каждый кадр самим
## Enemy._physics_process() по факту is_on_floor()): просто принудительно
## обнуляем actor.velocity.y на каждом кадре physics_update() ниже - это
## гасит именно то приращение гравитации, которое базовый класс успел
## добавить ДО вызова state_machine.physics_update() в этом же кадре, ещё
## до move_and_slide().

@export var teleport_hops: int = 3
@export var hop_interval: float = 0.25
@export var hop_radius: float = 220.0
@export var max_hop_fall_check: float = 250.0

const HIT_PARTICLES_SCENE: PackedScene = preload("res://components/hit_particles.tscn")
const WORLD_LAYER_MASK: int = 1

## Акцентный цвет партиклов появления/исчезновения - отличается от
## обычного красного "урон" (components/hit_particles.tscn), чтобы
## телепорт-вспышка читалась как магия/перемещение, а не как ещё одно
## попадание по Гонцу. Тот же приём, что и BLOCK_PARTICLE_COLOR у
## Shieldman - process_material.duplicate() перед правкой .color в
## _spawn_flash() ниже, не трогая общий разделяемый ресурс сцены.
const TELEPORT_PARTICLE_COLOR: Color = Color(0.55, 0.25, 0.85, 1.0)

var hops_left: int = 0
var timer: float = 0.0


func enter() -> void:
	actor.velocity = Vector2.ZERO
	TimeStop.start(actor)
	hops_left = teleport_hops
	actor.animated_sprite.play("idle")
	_do_hop()


## Safety net - если состояние прервано чем-то непредвиденным раньше, чем
## паттерн сам успел дойти до TimeStop.stop() (например, актор убит другим
## источником урона посреди скачков) - не оставляем мир замороженным
## навсегда. Ничего не делает, если exempt_actor уже не actor (обычный
## путь, TimeStop.stop() ниже в _finish() уже сам всё сбросил).
func exit() -> void:
	if TimeStop.exempt_actor == actor:
		TimeStop.stop()


func physics_update(delta: float) -> void:
	actor.velocity.y = 0.0

	timer -= delta
	if timer > 0.0:
		return

	if hops_left > 0:
		_do_hop()
		return

	_finish()


func _do_hop() -> void:
	if actor.target:
		var offset := Vector2(
			randf_range(-hop_radius, hop_radius),
			randf_range(-hop_radius * 0.3, 0.0)
		)
		var candidate: Vector2 = actor.target.global_position + offset
		if _has_floor_below(candidate):
			actor.global_position = candidate
		# иначе - под точкой нет пола в пределах max_hop_fall_check,
		# остаёмся на месте в этом скачке (см. комментарий вверху файла).
	_spawn_flash()
	hops_left -= 1
	timer = hop_interval


func _has_floor_below(point: Vector2) -> bool:
	var space_state := actor.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		point,
		point + Vector2(0.0, max_hop_fall_check),
		WORLD_LAYER_MASK
	)
	var result := space_state.intersect_ray(query)
	return not result.is_empty()


func _finish() -> void:
	if actor.target:
		var direction: float = sign(actor.target.global_position.x - actor.global_position.x)
		if direction != 0.0:
			actor.global_position = actor.target.global_position - Vector2(direction * 40.0, 0.0)
			actor.animated_sprite.flip_h = direction < 0.0
	_spawn_flash()
	_guaranteed_hit()
	TimeStop.stop()
	actor.time_since_last_hit = 0.0
	if actor.target:
		state_machine.transition_to("Chase")
	else:
		state_machine.transition_to("Idle")


func _spawn_flash() -> void:
	var hit_particles: GPUParticles2D = HIT_PARTICLES_SCENE.instantiate()
	get_tree().current_scene.add_child(hit_particles)
	hit_particles.global_position = actor.global_position

	var teleport_material: Resource = hit_particles.process_material.duplicate()
	teleport_material.color = TELEPORT_PARTICLE_COLOR
	hit_particles.process_material = teleport_material


## Тот же эффект, что даёт Enemy._on_attack_hitbox_area_entered() при
## честном попадании - урон + обоюдный hitstop-фриз - вызванный напрямую,
## без прохождения через AttackHitbox/Area2D.
func _guaranteed_hit() -> void:
	if actor.target == null:
		return
	if actor.target.has_method("take_damage"):
		actor.target.take_damage(actor.attack_damage, actor)
		actor.state_machine.freeze(actor.hitstop_duration)
		actor.target.state_machine.freeze(actor.hitstop_duration)
