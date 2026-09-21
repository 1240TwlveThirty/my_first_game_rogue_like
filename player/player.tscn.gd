extends CharacterBody2D

const HIT_PARTICLES_SCENE: PackedScene = preload("res://components/hit_particles.tscn")
const DAGGER_SCENE: PackedScene = preload("res://weapons/dagger.tscn")
const ARROW_SCENE: PackedScene = preload("res://weapons/arrow.tscn")

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0
@export var max_jumps: int = 2
@export var wall_slide_speed: float = 60.0
@export var wall_slide_fast_speed: float = 220.0
@export var wall_slide_acceleration: float = 500.0
@export var wall_jump_horizontal_speed: float = 400.0
@export var wall_jump_vertical_velocity: float = -420.0
@export var wall_jump_grace_time: float = 0.15
@export var ladder_grace_time: float = 0.15

@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.6

@export var hurt_knockback_speed: float = 150.0
@export var hitstop_duration: float = 0.08

@export var current_melee_weapon: MeleeWeaponData = preload("res://weapons/data/sword.tres")
@export var mace_data: MeleeWeaponData = preload("res://weapons/data/mace.tres")
@export var sword_data: MeleeWeaponData = preload("res://weapons/data/sword.tres")
@export var dagger_cooldown: float = 1.5
@export var dagger_throw_height_offset: float = 40.0
@export var max_arrows_on_field: int = 3
@export var shot_cooldown: float = 0.4


signal player_died
signal health_changed(current: int, max_health: int)
signal melee_weapon_changed(weapon: MeleeWeaponData)


const INPUT_BUFFER_WINDOW: float = 0.2


var combo_step: int = 0
var combo_reset_timer: float = 0.0
var heavy_combo_step: int = 0
var heavy_combo_reset_timer: float = 0.0
var current_attack_damage: int = 0
var current_attack_is_heavy: bool = false
var attack_buffer_timer: float = 0.0
var heavy_attack_buffer_timer: float = 0.0

@onready var state_machine: StateMachine = $StateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var camera: Camera2D = $Camera2D
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

var jumps_used: int = 0
var facing_direction: float = 1.0

var dash_cooldown_left: float = 0.0
var wall_jump_grace_timer: float = 0.0
var is_invulnerable: bool = false
var dagger_cooldown_left: float = 0.0
var ladder_grace_timer: float = 0.0
var current_ladder: Node2D = null
var shot_cooldown_left: float = 0.0
var was_time_stopped: bool = false

func _ready() -> void:
	add_to_group("player")
	hurtbox.add_to_group("player_hurtbox")
	attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
	health_component.died.connect(_on_health_component_died)
	health_component.health_changed.connect(_on_health_component_health_changed)
	health_component.damaged.connect(_on_health_component_damaged)
	state_machine.start()

func _physics_process(delta: float) -> void:
	if attack_buffer_timer > 0.0:
		attack_buffer_timer -= delta
	if heavy_attack_buffer_timer > 0.0:
		heavy_attack_buffer_timer -= delta

	if Input.is_action_just_pressed("Attack"):
		buffer_attack()

	if Input.is_action_just_pressed("heavy_attack"):
		buffer_heavy_attack()

	if dash_cooldown_left > 0.0:
		dash_cooldown_left -= delta
	if wall_jump_grace_timer > 0.0:
		wall_jump_grace_timer -= delta
	if ladder_grace_timer > 0.0:
		ladder_grace_timer -= delta

	if dagger_cooldown_left > 0.0:
		dagger_cooldown_left -= delta
	if Input.is_action_just_pressed("throw_dagger") and dagger_cooldown_left <= 0.0:
		_throw_dagger()

	if shot_cooldown_left > 0.0:
		shot_cooldown_left -= delta
	if Input.is_action_just_pressed("shoot") and shot_cooldown_left <= 0.0:
		_shoot_arrow()

	if Input.is_action_just_pressed("time_stop"):
		if TimeStop.is_active:
			TimeStop.stop()
		elif TimeStop.can_start():
			TimeStop.start(self)

	if Input.is_action_just_pressed("select_weapon_1"):
		_select_melee_weapon(mace_data)

	if Input.is_action_just_pressed("select_weapon_2"):
		_select_melee_weapon(sword_data)

	if combo_reset_timer > 0.0 and state_machine.current_state.name != "Attack":
		combo_reset_timer -= delta
	if combo_reset_timer <= 0.0:
		combo_step = 0

	if heavy_combo_reset_timer > 0.0 and state_machine.current_state.name != "HeavyAttack":
		heavy_combo_reset_timer -= delta
	if heavy_combo_reset_timer <= 0.0:
		heavy_combo_step = 0

	# Чужая заморозка тайм-стопа (TimeStop.exempt_actor - не игрок, например
	# будущий телепорт-тайм-стоп Гонца) - тот же паттерн edge-detection, что
	# и в enemy.gd (was_on_floor): гасим анимацию, запоминаем факт заморозки,
	# не вызываем state_machine.physics_update()/move_and_slide() в этом
	# кадре. Ввод (Attack/dash/throw_dagger/shoot/time_stop/выбор оружия) и
	# таймеры комбо/кулдаунов уже обработаны ВЫШЕ этой проверки и продолжают
	# тикать независимо от неё - иначе игрок не смог бы сам выключить чужую
	# заморозку кнопкой "time_stop" или воспользоваться луком/кинжалом, пока
	# пойман в ней. Когда TimeStop.exempt_actor == self (собственный тайм-стоп
	# игрока) - условие ложно, игрок продолжает двигаться как обычно.
	if TimeStop.is_active and TimeStop.exempt_actor != self:
		animated_sprite.speed_scale = 0.0
		was_time_stopped = true
		return

	if was_time_stopped:
		animated_sprite.speed_scale = 1.0
		was_time_stopped = false

	# Диалог (сейчас - предсмертная сцена Гонца, позже - любой другой NPC)
	# блокирует обычный ввод/движение игрока - НО не тогда, когда игрок
	# уже в Death: его SAFETY_TIMEOUT/выход в player_died обязаны идти
	# независимо от чужого диалога, иначе получаем ровно ту гонку с
	# get_tree().paused, которую эта правка и устраняет (см. CLAUDE.md/чат
	# про одновременную смерть игрока и Гонца).
	if DialogueState.is_active and state_machine.current_state.name != "Death":
		return

	state_machine.physics_update(delta)
	if state_machine.freeze_time_left <= 0.0:
		move_and_slide()

	if is_on_floor():
		jumps_used = 0


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		var enemy := area.get_parent()
		if enemy.has_method("take_damage"):
			enemy.take_damage(current_attack_damage, self, current_attack_is_heavy)
			state_machine.freeze(hitstop_duration)
			enemy.state_machine.freeze(hitstop_duration)
	elif area.is_in_group("frozen_arrow") and TimeStop.is_active:
		var arrow := area.get_parent()
		if arrow.has_method("add_charge"):
			arrow.add_charge()
	elif area.is_in_group("frozen_dagger") and TimeStop.is_active:
		var dagger := area.get_parent()
		if dagger.has_method("add_charge"):
			dagger.add_charge()
	elif area.is_in_group("boss_dagger"):
		# Разбивание летящего кинжала Гонца обычной атакой - бинарно, без
		# урона в любую сторону, работает одинаково от light/heavy
		# (просто "долетел до AttackHitbox - сломан"), тот же паттерн
		# хит-партиклов, что и везде в проекте.
		var boss_dagger := area.get_parent()
		var break_particles: GPUParticles2D = HIT_PARTICLES_SCENE.instantiate()
		get_tree().current_scene.add_child(break_particles)
		break_particles.global_position = boss_dagger.global_position
		boss_dagger.queue_free()

## Возвращает true, если удар реально прошёл (не парирован, не поглощён
## i-frames дэша) - нужно вызывающему коду, которому важно ЗНАТЬ, попал ли
## удар, прежде чем делать что-то ещё (см. enemies/projectiles/
## boss_dagger.gd - pin_player() зовётся, только если здесь вернулось true,
## иначе успешно уклонившийся/запарировавший игрок оказался бы прибит без
## единого полученного урона). Существующие вызывающие (enemy.gd,
## messenger_teleport_state.gd, enemy_arrow.gd) как звали это как обычный
## оператор, игнорируя возврат - так и продолжают, синтаксически ничего не
## меняется для них.
func take_damage(amount: int, attacker: Node = null) -> bool:
	if state_machine.current_state.try_parry():
		if attacker and attacker.has_method("on_parried"):
			attacker.on_parried()
		return false
	if is_invulnerable:
		return false
	health_component.take_damage(amount)
	return true


## Помечает следующий вход в Hurt как "прибит к стене" - флаг нужно
## выставить ДО take_damage(), по той же причине, что и enemy.pin_next_stagger()
## на враге: take_damage() может сам перевести игрока в Hurt через сигнал
## damaged (см. _on_health_component_damaged), и повторный
## transition_to("Hurt") в уже активное состояние будет no-op'ом (см.
## CLAUDE.md, 17.08.2026) - is_wall_pinned обязан быть true до ПЕРВОГО
## enter().
func mark_next_hurt_as_pinned() -> void:
	var hurt: Node = state_machine.states.get("Hurt")
	if hurt:
		hurt.is_wall_pinned = true


## Форсирует переход в Hurt, минуя can_be_interrupted() базового State -
## обычная реакция на урон (_on_health_component_damaged) сама проверяет
## can_be_interrupted() и может ничего не сделать, если игрок сейчас в
## непрерываемом состоянии; прибивание кинжалом Гонца обязано пробить
## гарантированно, как и зеркальная механика на враге. Вызывающий код
## (boss_dagger.gd) зовёт это только после take_damage(), вернувшего true.
func pin_player() -> void:
	if state_machine.current_state.name == "Death":
		return
	state_machine.transition_to("Hurt")


func get_current_health() -> int:
	return health_component.current_health


func get_max_health() -> int:
	return health_component.max_health


func get_climbable_wall_direction() -> float:
	# Возвращает направление к стене относительно игрока: +1 - справа, -1 - слева, 0 - нет контакта.
	# Источник направления - нормаль столкновения от физики, а не ввод игрока или facing_direction,
	# чтобы не зависеть от того, что игрок делал кадром раньше.
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


func enter_ladder(ladder: Node2D) -> void:
	current_ladder = ladder


func exit_ladder(ladder: Node2D) -> void:
	if current_ladder == ladder:
		current_ladder = null


func _on_health_component_died() -> void:
	state_machine.transition_to("Death")


func _on_health_component_health_changed(current: int, max_health: int) -> void:
	health_changed.emit(current, max_health)


func _on_health_component_damaged(_amount: int) -> void:
	var hit_particles: GPUParticles2D = HIT_PARTICLES_SCENE.instantiate()
	get_tree().current_scene.add_child(hit_particles)
	hit_particles.global_position = hurtbox_shape.global_position
	shake_camera()
	if state_machine.current_state.can_be_interrupted():
		state_machine.transition_to("Hurt")


func shake_camera() -> void:
	camera.shake()


## Прямой выбор оружия по клавише (не переключатель) - смена в уже выбранное
## оружие ничего не делает (не сбрасывает комбо и не дёргает state_machine
## зря). "Безусловно" здесь - только в смысле can_be_interrupted(): смена
## оружия обязана прервать любое текущее состояние (включая активную атаку и
## парирование) независимо от его фазы. StateMachine.transition_to() сам по
## себе can_be_interrupted() не проверяет (это делает вызывающий код, как в
## _on_health_component_damaged для Hurt) - значит для безусловного
## прерывания достаточно просто не делать эту проверку самим. А вот КУДА
## переходить после прерывания - решается по is_on_floor()/направлению
## ввода, тем же способом, что и в _end_attack() у attack_state.gd /
## heavy_attack_state.gd, а не всегда в Idle.
func _select_melee_weapon(weapon: MeleeWeaponData) -> void:
	if current_melee_weapon == weapon:
		return
	if state_machine.current_state.name == "Death":
		return

	current_melee_weapon = weapon
	combo_step = 0
	combo_reset_timer = 0.0
	heavy_combo_step = 0
	heavy_combo_reset_timer = 0.0

	if not is_on_floor():
		state_machine.transition_to("Fall")
	else:
		var direction := Input.get_axis("move_left", "move_right")
		if direction != 0.0:
			state_machine.transition_to("Run")
		else:
			state_machine.transition_to("Idle")

	melee_weapon_changed.emit(current_melee_weapon)


func _throw_dagger() -> void:
	var dagger: Node2D = DAGGER_SCENE.instantiate()
	get_tree().current_scene.add_child(dagger)
	dagger.launch(global_position + Vector2(0, dagger_throw_height_offset), facing_direction)
	dagger_cooldown_left = dagger_cooldown


func _shoot_arrow() -> void:
	if get_tree().get_nodes_in_group("player_arrow").size() >= max_arrows_on_field:
		return
	var arrow: Node2D = ARROW_SCENE.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.launch(global_position + Vector2(0, dagger_throw_height_offset), facing_direction)
	shot_cooldown_left = shot_cooldown


func buffer_attack() -> void:
	attack_buffer_timer = INPUT_BUFFER_WINDOW


func buffer_heavy_attack() -> void:
	heavy_attack_buffer_timer = INPUT_BUFFER_WINDOW


func consume_buffered_attack() -> bool:
	if attack_buffer_timer > 0.0:
		attack_buffer_timer = 0.0
		return true
	return false


func consume_buffered_heavy_attack() -> bool:
	if heavy_attack_buffer_timer > 0.0:
		heavy_attack_buffer_timer = 0.0
		return true
	return false
