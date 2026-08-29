extends CharacterBody2D

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

@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.6

@export var attack_damage: int = 1
@export var combo_reset_time: float = 0.6
@export var combo_max_steps: int = 4
@export var attack_reach: float = 40.0
@export var hurt_knockback_speed: float = 150.0
@export var heavy_attack_damage: int = 3
@export var heavy_attack_reach: float = 45.0
@export var heavy_combo_max_steps: int = 3
@export var heavy_combo_reset_time: float = 0.7
@export var hitstop_duration: float = 0.08


signal player_died
signal health_changed(current: int, max_health: int)


const INPUT_BUFFER_WINDOW: float = 0.2


var combo_step: int = 0
var combo_reset_timer: float = 0.0
var heavy_combo_step: int = 0
var heavy_combo_reset_timer: float = 0.0
var current_attack_damage: int = 0
var is_frozen: bool = false
var freeze_timer: float = 0.0
var attack_buffer_timer: float = 0.0
var heavy_attack_buffer_timer: float = 0.0

@onready var state_machine: StateMachine = $StateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

var jumps_used: int = 0
var facing_direction: float = 1.0

var dash_cooldown_left: float = 0.0
var wall_jump_grace_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")
	hurtbox.add_to_group("player_hurtbox")
	attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
	health_component.died.connect(_on_health_component_died)
	health_component.health_changed.connect(_on_health_component_health_changed)
	health_component.damaged.connect(_on_health_component_damaged)
	state_machine.start()

func _physics_process(delta: float) -> void:
	if is_frozen:
		freeze_timer -= delta
		if freeze_timer <= 0.0:
			_unfreeze()
		return

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

	if combo_reset_timer > 0.0 and state_machine.current_state.name != "Attack":
		combo_reset_timer -= delta
	if combo_reset_timer <= 0.0:
		combo_step = 0

	if heavy_combo_reset_timer > 0.0 and state_machine.current_state.name != "HeavyAttack":
		heavy_combo_reset_timer -= delta
	if heavy_combo_reset_timer <= 0.0:
		heavy_combo_step = 0

	state_machine.physics_update(delta)
	move_and_slide()

	if is_on_floor():
		jumps_used = 0


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		var enemy := area.get_parent()
		if enemy.has_method("take_damage"):
			enemy.take_damage(current_attack_damage)
			freeze(hitstop_duration)
			if enemy.has_method("freeze"):
				enemy.freeze(hitstop_duration)

func take_damage(amount: int, attacker: Node = null) -> void:
	if state_machine.current_state.try_parry():
		if attacker and attacker.has_method("on_parried"):
			attacker.on_parried()
		return
	health_component.take_damage(amount)


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


func _on_health_component_died() -> void:
	state_machine.transition_to("Death")


func _on_health_component_health_changed(current: int, max_health: int) -> void:
	health_changed.emit(current, max_health)


func _on_health_component_damaged(_amount: int) -> void:
	if state_machine.current_state.can_be_interrupted():
		state_machine.transition_to("Hurt")


func freeze(duration: float) -> void:
	is_frozen = true
	freeze_timer = duration
	animated_sprite.speed_scale = 0.0


func _unfreeze() -> void:
	is_frozen = false
	animated_sprite.speed_scale = 1.0


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
