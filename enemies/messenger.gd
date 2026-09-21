extends Enemy
class_name Messenger

## Первый полноценный боевой ИИ босса - "Гонец" (Messenger). Расширяет
## Enemy, совместим со всеми уже работающими системами без правки в них:
## группа "enemy" (автоприцел стрелы/кинжала игрока ищет именно по ней),
## HealthComponent/died/damaged, on_parried()/pin_next_stagger() (механика
## прибивания кинжалом - Stagger всё ещё существует и переключается как
## обычно, просто обычные удары в него не отправляют, см.
## _on_health_component_damaged ниже), TimeStop-исключение через
## exempt_actor (см. messenger_teleport_state.gd). take_damage() всё же
## пришлось переопределить (см. ниже) - единственное исключение из
## "ничего не трогаем" - ради is_invulnerable на время Dodge, для которого
## у базового Enemy нет никакой инфраструктуры вообще (в отличие от
## игрока, где take_damage() уже проверяет is_invulnerable).
##
## time_since_last_hit живёт ЗДЕСЬ, на акторе. Инкремент и проверка порога
## (evasion_punish_threshold -> Teleport) централизованы в
## _physics_process() ниже - тикают безусловно каждый кадр независимо от
## текущего состояния ФСМ (раньше жили внутри messenger_chase_state.gd и
## тикали только пока Гонец был именно в Chase - см. комментарий у
## _physics_process() про причину переноса). Сброс в 0 - либо честное
## попадание ближней атаки (через override _on_attack_hitbox_area_entered
## ниже - единая точка, где урон реально подтверждён контактом, а не
## просто "хитбокс был включён"), либо попадание boss_dagger.gd, либо
## явно MessengerTeleportState после гарантированного удара расплаты.
@export var evasion_punish_threshold: float = 6.0
var time_since_last_hit: float = 0.0

## Неуязвимость на время Dodge (enemies/States/messenger_dodge_state.gd) -
## тот же ЭФФЕКТ, что у actor.is_invulnerable на player.tscn.gd (dash i-frames),
## но другой МЕХАНИЗМ: у Player это поле проверяется прямо внутри
## take_damage(), у базового Enemy.take_damage() такой проверки нет вообще
## (Enemy и Player - разные классы без общего предка для этой логики).
## Поэтому пришлось переопределить take_damage() именно здесь (см. ниже),
## по прецеденту Shieldman.take_damage() - своя защитная механика поверх
## super().
var is_invulnerable: bool = false

## Кулдаун реактивного уклонения - тикает в _physics_process() ниже,
## выставляется в дальнем конце Dodge (messenger_dodge_state.gd), тот же
## паттерн, что actor.dash_cooldown_left у игрока в dash_state.gd.
var dodge_cooldown_left: float = 0.0

## Лимит бросков кинжала за один заход - без него messenger_chase_state.gd
## ничем не гейтит возврат в DaggerThrow (windup/recovery того состояния -
## единственная пауза), и Гонец кидал кинжалы практически без остановки,
## пока игрок стоял в dagger_range. daggers_thrown_in_burst считает
## brosки внутри одной серии (сбрасывается messenger_dagger_throw_state.gd
## при достижении max_daggers_per_burst), dagger_burst_cooldown_left
## тикает здесь же и гейтит вход в DaggerThrow в messenger_chase_state.gd -
## тот же паттерн, что и dodge_cooldown_left выше.
@export var max_daggers_per_burst: int = 2
@export var dagger_burst_cooldown: float = 15.0
var daggers_thrown_in_burst: int = 0
var dagger_burst_cooldown_left: float = 0.0

## Прыжковая подвижность (messenger_jump_state.gd/messenger_wall_climb_state.gd) -
## первая у ЛЮБОГО архетипа врага в проекте, поэтому живёт на Messenger,
## не на базовом Enemy. Двойной прыжок - как у игрока (jump_velocity/
## max_jumps - те же названия полей, что на player.tscn.gd, для
## единообразия, хотя классы не связаны). Базовый Enemy._physics_process()
## уже тикает гравитацию и безусловно детектит приземление
## (is_on_floor() and not was_on_floor -> transition_to("Land")) для
## ЛЮБОГО текущего состояния - значит Jump/WallClimb ничего специально
## обрабатывать при посадке не должны, это уже готовая инфраструктура.
@export var jump_velocity: float = -500.0
@export var max_jumps: int = 2
var jumps_used: int = 0


## is_invulnerable гасит урон ДО того, как он вообще дойдёт до
## HealthComponent - значит и _on_health_component_damaged() (партиклы/
## вспышка), и take_damage() base Enemy (Stagger-триггер там нет, но
## damaged-сигнал всё равно не будет отправлен) во время Dodge просто не
## вызываются. attacker/is_heavy передаются в super() как есть - сигнатура
## не меняется, существующие вызывающие (player.tscn.gd, dagger.gd,
## arrow.gd) ничего не замечают.
func take_damage(amount: int, attacker: Node = null, is_heavy: bool = false) -> void:
	if is_invulnerable:
		return
	super.take_damage(amount, attacker, is_heavy)


## Немедленная агрессия - Гонец не "обнаруживает" игрока постепенно через
## DetectionZone, бой начинается сразу при входе в арену. call_deferred()
## обязателен здесь: порядок _ready() узлов-сиблингов в дереве сцены
## (Arena) зависит от порядка объявления в .tscn, и в arena.tscn Messenger
## объявлен РАНЬШЕ Player - без отсрочки get_first_node_in_group("player")
## мог бы вернуть null, потому что Player ещё не успел выполнить свой
## _ready() (где он добавляет себя в группу "player"). call_deferred()
## откладывает вызов до момента, когда ВСЕ _ready() текущего кадра уже
## отработали - результат не зависит от порядка узлов в сцене.
func _ready() -> void:
	super._ready()
	call_deferred("_acquire_target_immediately")


func _acquire_target_immediately() -> void:
	target = get_tree().get_first_node_in_group("player")


## Централизованный тик расплаты за уклонение - раньше actor.time_since_last_hit
## инкрементировался и проверялся только внутри messenger_chase_state.gd,
## а значит только пока Гонец был именно в Chase. Из-за этого реальное
## время до Teleport растягивалось: пока Гонец чередует Chase/DaggerThrow
## (или Chase/Combo/QuickLunge/WideSwing), большая часть игрового времени
## проходит внутри windup/active/recovery этих состояний, где инкремента
## не было вообще. Перенесено сюда и тикает БЕЗУСЛОВНО каждый кадр
## независимо от текущего состояния ФСМ - реальное время до телепорта
## теперь равно ровно evasion_punish_threshold секунд игрового времени, а
## не игрового времени минус время, проведённое в атаках/бросках.
##
## Исключение - собственная заморозка мира ЧУЖИМ TimeStop (Гонец не
## exempt_actor): вызывается super._physics_process(delta), который для
## этого случая делает ранний return и полностью пропускает игровую
## логику - время в буквальном смысле стоит для всех, включая terminal
## отсчёт уклонения, поэтому проверяем то же условие и здесь, а не
## тикаем совсем "безусловно" в отрыве от мирового правила TimeStop,
## общего для каждого актора в проекте. Во время СОБСТВЕННОГО телепорта
## Гонца (exempt_actor == self) это условие ложно - тик продолжается, но
## повторный transition_to("Teleport") в уже активное состояние - no-op
## (см. StateMachine, нюанс от 17.08.2026), безвредно.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if TimeStop.is_active and TimeStop.exempt_actor != self:
		return

	if dodge_cooldown_left > 0.0:
		dodge_cooldown_left -= delta

	if dagger_burst_cooldown_left > 0.0:
		dagger_burst_cooldown_left -= delta

	if is_on_floor():
		jumps_used = 0

	time_since_last_hit += delta
	if time_since_last_hit >= evasion_punish_threshold:
		# Расплата за уклонение - приоритет 1, поверх ВСЕГО (включая
		# только что добавленный Dodge-триггер ниже, до которого этот
		# return просто не даёт дойти в этом кадре). can_be_interrupted()
		# всё же уважаем, а не рвём состояние силой - см. предупреждение в
		# чате: ни одно из пяти боевых состояний Гонца сейчас не
		# переопределяет can_be_interrupted() (все true по умолчанию),
		# поэтому на практике это условие сегодня никогда не блокирует
		# переход - но код написан на случай, если кто-то из них получит
		# правильный can_be_interrupted() -> false в будущем.
		if state_machine.current_state.can_be_interrupted():
			state_machine.transition_to("Teleport")
		return

	_check_dodge_trigger()


## Реактивное уклонение - срабатывает, если игрок начал атаку в пределах
## её досягаемости. Централизовано здесь по той же причине, что и
## evasion_punish_threshold: должно проверяться независимо от текущего
## состояния ФСМ Гонца, а не только пока он в Chase.
func _check_dodge_trigger() -> void:
	if target == null:
		return
	if dodge_cooldown_left > 0.0:
		return
	if state_machine.current_state.name == "Dodge":
		return
	if not state_machine.current_state.can_be_interrupted():
		return

	var player_state_machine: Node = target.get("state_machine")
	if player_state_machine == null:
		return
	var player_state_name: String = player_state_machine.current_state.name
	if player_state_name != "Attack" and player_state_name != "HeavyAttack":
		return

	var weapon: MeleeWeaponData = target.get("current_melee_weapon")
	if weapon == null:
		return
	var reach: float = weapon.heavy_reach if player_state_name == "HeavyAttack" else weapon.light_reach

	var distance: float = absf(target.global_position.x - global_position.x)
	if distance < reach:
		state_machine.transition_to("Dodge")


## Копия player.tscn.gd.get_climbable_wall_direction() - логика целиком
## завязана на штатную физику CharacterBody2D (is_on_wall()/
## get_last_slide_collision()/группа "climbable_wall"), никаких
## Player-специфичных полей не использует, поэтому просто дублируется
## сюда, а не выносится в общий предок ради одного метода на два
## несвязанных класса (Player и Enemy не имеют общего промежуточного
## класса, кроме CharacterBody2D/Node).
func get_climbable_wall_direction() -> float:
	if not is_on_wall():
		return 0.0
	var collision := get_last_slide_collision()
	if collision == null:
		return 0.0
	var collider := collision.get_collider()
	if not (collider is Node and collider.is_in_group("climbable_wall")):
		return 0.0
	var normal := collision.get_normal()
	if absf(normal.x) < 0.1:
		return 0.0
	return -signf(normal.x)


## Гонец никогда не теряет цель через DetectionZone - design-решение
## "агрится сразу и не отпускает" (в отличие от рядовых врагов/щитовика/
## лучника, у которых "потерять из виду" - нормальное поведение,
## переопределённое сознательно только здесь). До этой правки выход
## игрока за пределы DetectionZone (радиус 230.6) взводил
## enemy.gd.lose_target_timer, и по истечении lose_target_grace (1.5с)
## target обнулялся - единственное место во всём проекте, где target
## вообще присваивается null (enemy.gd:81). Это ломало не только
## "реагирует по всей арене", но и рикошетом evasion_punish_threshold в
## messenger_chase_state.gd: та проверка тикает только пока текущее
## состояние - Chase, а после потери target любое ближнее/дальнее
## действие Гонца по завершению уходило в Idle вместо Chase - таймер
## переставал тикать вообще, не "зависал на нуле". С пустым _exited
## lose_target_timer у Гонца никогда не станет больше 0, значит
## enemy.gd:81 для него физически недостижим - единственный источник
## target остаётся _acquire_target_immediately() при старте сцены,
## никакой периодической проверки/fallback не требуется.
func _on_detection_zone_body_exited(_body: Node2D) -> void:
	pass


## Гонец невосприимчив к обычному стану - в отличие от рядового Enemy,
## удар не прерывает его текущее состояние (можно всадить комбо в стан от
## удара игрока, будь оно так - это было бы нечестно для боя с боссом).
## Партиклы и тряска камеры оставлены (дёшево, даёт понятную обратную
## связь "удар засчитан"), вместо transition_to("Stagger") - короткая
## modulate-вспышка, не трогающая state_machine вообще.
func _on_health_component_damaged(_amount: int) -> void:
	var hit_particles: GPUParticles2D = HIT_PARTICLES_SCENE.instantiate()
	get_tree().current_scene.add_child(hit_particles)
	hit_particles.global_position = hurtbox_shape.global_position
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("shake_camera"):
		player.shake_camera()
	_flash_hit()


func _flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1.0, 0.35, 0.35), 0.04)
	tween.tween_property(animated_sprite, "modulate", Color(1.0, 1.0, 1.0), 0.08)


## Расширяет (не подменяет) базовую реакцию Enemy на попадание своей атаки
## по игроку - урон/хитстоп идут как обычно через super(), дополнительно
## обнуляется time_since_last_hit, если контакт действительно был с
## player_hurtbox. Это и есть "успешное попадание комбо" из ТЗ: не нужен
## отдельный канал связи Combo -> Chase, потому что оба состояния делят
## одно и то же поле актора, а сброс происходит там, где урон реально
## подтверждён физическим контактом (area_entered), а не по факту того,
## что хитбокс был просто активен во время ACTIVE-фазы удара.
func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	super._on_attack_hitbox_area_entered(area)
	if area.is_in_group("player_hurtbox"):
		time_since_last_hit = 0.0
