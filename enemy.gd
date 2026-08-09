extends CharacterBody2D

@export var speed: float = 120.0
@export var gravity: float = 980.0
@export var max_health: int = 3

var target: Node2D = null
var health: int = 0

func _ready() -> void:
	health = max_health
	$Hurtbox.add_to_group("enemy_hurtbox")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	if target:
		var direction: float = sign(target.global_position.x - global_position.x)
		velocity.x = direction * speed
	else:
		velocity.x = 0.0

	move_and_slide()


func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body


func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body == target:
		target = null


func take_damage(amount: int) -> void:
	health -= amount
	print("Враг получил урон, здоровье: ", health)
	if health <= 0:
		queue_free()
