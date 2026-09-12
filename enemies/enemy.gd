extends CharacterBody2D

const HIT_PARTICLES_SCENE: PackedScene = preload("res://components/hit_particles.tscn")

@export var speed: float = 120.0
@export var gravity: float = 980.0
@export var attack_damage: int = 1
@export var attack_windup: float = 0.35
@export var attack_active_duration: float = 0.15
@export var attack_recovery: float = 0.3
@export var attack_cooldown: float = 1.0
@export var stagger_duration: float = 0.4
@export var hitstop_duration: float = 0.08
@export var horizontal_deadzone: float = 8.0

var target: Node2D = null
var attack_cooldown_left: float = 0.0
var in_attack_range: bool = false
var was_on_floor: bool = true

@onready var health_component: HealthComponent = $HealthComponent
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var state_machine: StateMachine = $StateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		var player := area.get_parent()
		if player.has_method("take_damage"):
			player.take_damage(attack_damage, self)
			state_machine.freeze(hitstop_duration)
			player.state_machine.freeze(hitstop_duration)

func on_parried() -> void:
	var stagger: Node = state_machine.states.get("Stagger")
	if stagger:
		stagger.is_punished = true
	state_machine.transition_to("Stagger")


## Помечает следующий Stagger как "прибивание" (увеличенная длительность).
## Флаг нужно выставить ДО take_damage() - урон уже сам переводит в
## Stagger через сигнал damaged, и повторный transition_to("Stagger") в
## уже активное состояние был бы no-op (см. нюанс от 17.08.2026).
func pin_next_stagger() -> void:
	var stagger: Node = state_machine.states.get("Stagger")
	if stagger:
		stagger.is_pinned = true


func _ready() -> void:
	add_to_group("enemy")
	health_component.died.connect(_on_health_component_died)
	health_component.damaged.connect(_on_health_component_damaged)
	$Hurtbox.add_to_group("enemy_hurtbox")
	attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
	attack_shape.disabled = true
	state_machine.start()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	if attack_cooldown_left > 0.0:
		attack_cooldown_left -= delta

	state_machine.physics_update(delta)
	if state_machine.freeze_time_left <= 0.0:
		move_and_slide()

	if is_on_floor() and not was_on_floor:
		state_machine.transition_to("Land")
	was_on_floor = is_on_floor()


func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body


func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body == target:
		target = null


func take_damage(amount: int) -> void:
	health_component.take_damage(amount)


func _on_health_component_died() -> void:
	state_machine.transition_to("Death")

func _on_health_component_damaged(_amount: int) -> void:
	var hit_particles: GPUParticles2D = HIT_PARTICLES_SCENE.instantiate()
	get_tree().current_scene.add_child(hit_particles)
	hit_particles.global_position = hurtbox_shape.global_position
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("shake_camera"):
		player.shake_camera()
	state_machine.transition_to("Stagger")


func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		in_attack_range = true


func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		in_attack_range = false
