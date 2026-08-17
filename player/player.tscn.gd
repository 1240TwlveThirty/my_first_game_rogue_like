extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0
@export var max_jumps: int = 2

@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.6

@export var attack_damage: int = 1
@export var attack_duration: float = 0.15
@export var combo_reset_time: float = 0.6
@export var combo_max_steps: int = 4
@export var attack_reach: float = 40.0
@export var hurt_knockback_speed: float = 150.0

signal player_died
signal health_changed(current: int, max_health: int)

var combo_step: int = 0
var combo_reset_timer: float = 0.0

@onready var state_machine: StateMachine = $StateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

var jumps_used: int = 0
var facing_direction: float = 1.0

var dash_cooldown_left: float = 0.0

func _ready() -> void:
	add_to_group("player")
	hurtbox.add_to_group("player_hurtbox")
	attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
	health_component.died.connect(_on_health_component_died)
	health_component.health_changed.connect(_on_health_component_health_changed)
	health_component.damaged.connect(_on_health_component_damaged)
	state_machine.start()

func _physics_process(delta: float) -> void:
	if dash_cooldown_left > 0.0:
		dash_cooldown_left -= delta

	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0:
			combo_step = 0

	state_machine.physics_update(delta)
	move_and_slide()

	if is_on_floor():
		jumps_used = 0


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		var enemy := area.get_parent()
		if enemy.has_method("take_damage"):
			enemy.take_damage(attack_damage)

func take_damage(amount: int) -> void:
	health_component.take_damage(amount)


func get_current_health() -> int:
	return health_component.current_health


func get_max_health() -> int:
	return health_component.max_health


func _on_health_component_died() -> void:
	player_died.emit()


func _on_health_component_health_changed(current: int, max_health: int) -> void:
	health_changed.emit(current, max_health)


func _on_health_component_damaged(_amount: int) -> void:
	if state_machine.current_state.can_be_interrupted():
		state_machine.transition_to("Hurt")
