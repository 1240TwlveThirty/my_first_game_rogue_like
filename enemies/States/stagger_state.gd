extends State

@export var punish_multiplier: float = 2.5
@export var punish_extra_time: float = 0.3  # запас поверх анимации parry игрока, чтобы успеть нанести punish-удар
@export var pin_duration: float = 1.5  # полный стан от кинжала, воткнувшегося во врага у стены

var timer: float = 0.0
var is_punished: bool = false
var is_pinned: bool = false


func enter() -> void:
	var duration: float = actor.stagger_duration
	if is_punished:
		duration = _get_punish_duration()
	elif is_pinned:
		duration = pin_duration
	is_punished = false
	is_pinned = false

	timer = duration
	actor.velocity.x = 0.0
	actor.attack_shape.set_deferred("disabled", true)
	actor.animated_sprite.play("hurt")


# Punish-окно не должно закрываться раньше, чем у игрока доиграет анимация
# "parry" (см. player/States/parry_state.gd) - иначе окно наказания
# закрывается визуально раньше, чем игрок вообще успел закончить парирование.
# punish_multiplier остаётся нижней границей на случай, если анимация parry
# станет короче базового стаггера.
func _get_punish_duration() -> float:
	var fallback: float = actor.stagger_duration * punish_multiplier
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return fallback
	var player_sprite: AnimatedSprite2D = player.get("animated_sprite")
	if player_sprite == null or player_sprite.sprite_frames == null or not player_sprite.sprite_frames.has_animation("parry"):
		return fallback
	var parry_duration: float = get_animation_duration(player_sprite, "parry") + punish_extra_time
	return maxf(fallback, parry_duration)


func physics_update(delta: float) -> void:
	actor.velocity.x = 0.0
	timer -= delta
	if timer <= 0.0:
		if actor.target:
			state_machine.transition_to("Chase")
		else:
			state_machine.transition_to("Idle")
