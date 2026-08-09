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
@export var combo_max_steps: int = 3
@export var max_health: int = 5

var health: int = 0
var is_attacking: bool = false
var attack_timer: float = 0.0
var combo_step: int = 0
var combo_reset_timer: float = 0.0

@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

var jumps_used: int = 0
var facing_direction: float = 1.0

var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var dash_direction: float = 1.0

func _ready() -> void:
	add_to_group("player")
	health = max_health
	hurtbox.add_to_group("player_hurtbox")
	attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)

func _physics_process(delta: float) -> void:
	if dash_cooldown_left > 0.0:
		dash_cooldown_left -= delta

	if is_dashing:
		_process_dash(delta)
	else:
		_process_movement(delta)

	_process_attack(delta)

	move_and_slide()

	if is_on_floor():
		jumps_used = 0


func _process_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing_direction = direction

	velocity.x = direction * speed
	velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and jumps_used < max_jumps:
		velocity.y = jump_velocity
		jumps_used += 1

	if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0.0:
		_start_dash()


func _start_dash() -> void:
	is_dashing = true
	dash_time_left = dash_duration
	dash_direction = facing_direction
	velocity.y = 0.0


func _process_dash(delta: float) -> void:
	velocity.x = dash_direction * dash_speed
	velocity.y = 0.0

	dash_time_left -= delta
	if dash_time_left <= 0.0:
		is_dashing = false
		dash_cooldown_left = dash_cooldown

func _process_attack(delta: float) -> void:
	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0:
			combo_step = 0

	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			_end_attack()
		return

	if Input.is_action_just_pressed("Attack") and not is_dashing:
		_start_attack()


func _start_attack() -> void:
	is_attacking = true
	attack_timer = attack_duration
	attack_hitbox.position.x = abs(40.0) * facing_direction
	attack_shape.disabled = false


func _end_attack() -> void:
	is_attacking = false
	attack_shape.disabled = true
	combo_step = (combo_step + 1) % combo_max_steps
	combo_reset_timer = combo_reset_time


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		var enemy := area.get_parent()
		if enemy.has_method("take_damage"):
			enemy.take_damage(attack_damage)

func take_damage(amount: int) -> void:
	health -= amount
	print("Игрок получил урон, здоровье: ", health)
	# TODO: смерть и геймовер будут отдельной задачей
