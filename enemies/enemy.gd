extends CharacterBody2D

@export var speed: float = 120.0
@export var gravity: float = 980.0
@export var attack_damage: int = 1
@export var attack_duration: float = 0.3
@export var attack_cooldown: float = 1.0

var target: Node2D = null
var is_attacking: bool = false
var attack_timer: float = 0.0
var attack_cooldown_left: float = 0.0
var in_attack_range: bool = false

@onready var health_component: HealthComponent = $HealthComponent
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

func _ready() -> void:
	health_component.died.connect(_on_health_component_died)
	$Hurtbox.add_to_group("enemy_hurtbox")
	attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
	attack_shape.disabled = true


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	if attack_cooldown_left > 0.0:
		attack_cooldown_left -= delta

	if is_attacking:
		_process_attack(delta)
		velocity.x = 0.0
	elif target and in_attack_range and attack_cooldown_left <= 0.0:
		_start_attack()
	elif target:
		var direction: float = sign(target.global_position.x - global_position.x)
		velocity.x = direction * speed
	else:
		velocity.x = 0.0

	move_and_slide()


func _start_attack() -> void:
	is_attacking = true
	attack_timer = attack_duration
	var direction: float = sign(target.global_position.x - global_position.x)
	attack_hitbox.position.x = abs(30.0) * direction
	attack_shape.disabled = false


func _process_attack(delta: float) -> void:
	attack_timer -= delta
	if attack_timer <= 0.0:
		is_attacking = false
		attack_shape.disabled = true
		attack_cooldown_left = attack_cooldown


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		var player := area.get_parent()
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)


func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body


func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body == target:
		target = null


func take_damage(amount: int) -> void:
	health_component.take_damage(amount)


func _on_health_component_died() -> void:
	queue_free()

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		in_attack_range = true


func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		in_attack_range = false
