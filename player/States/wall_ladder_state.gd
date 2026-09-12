extends State

## Лазание по цепям/лестницам - отдельное от WallClimb состояние (осознанно
## не переиспользует его): WallClimb - это скольжение по стене с вариацией
## скорости падения и wall-jump, без свободного движения вверх. Здесь же
## нужно произвольное перемещение вверх/вниз по вертикали через move_up/
## move_down, что физически другая механика.

@export var climb_speed: float = 150.0


func enter() -> void:
	actor.velocity.x = 0.0
	actor.velocity.y = 0.0
	actor.animated_sprite.play("wall_climb")  # ВРЕМЕННО: та же заглушка, что и у WallClimb
	actor.jumps_used = 0


func physics_update(_delta: float) -> void:
	if actor.current_ladder == null:
		state_machine.transition_to("Fall")
		return

	if Input.is_action_just_pressed("jump"):
		actor.ladder_grace_timer = actor.ladder_grace_time
		state_machine.transition_to("Jump")
		return

	var vertical := Input.get_axis("move_up", "move_down")
	actor.velocity.y = vertical * climb_speed
	actor.velocity.x = 0.0

	if actor.is_on_floor():
		state_machine.transition_to("Land")
