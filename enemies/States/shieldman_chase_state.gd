extends State

## Отдельное состояние от enemies/States/chase_state.gd. Имя узла в FSM
## остаётся "Chase" (не переименовано) - это имя жёстко зашито строкой в
## нескольких МЕСТАХ, общих с обычным Enemy: enemies/States/stagger_state.gd
## и shieldman_land_state.gd оба безусловно зовут transition_to("Chase"),
## когда actor.target != null. Переименование узла потребовало бы либо
## развилки по типу актора в этих общих файлах, либо отдельных копий этих
## состояний для Shieldman - непропорционально задаче.
##
## Поведение при этом НЕ повторяет обычную погоню: по прямому запросу
## щитовик, увидев игрока, встаёт на месте со щитом (не идёт вперёд, не
## толкает игрока и не упирается в стены при погоне) - velocity.x всегда
## 0. Доворот лицом к цели (facing_direction/flip_h) оставлен - без него
## щит замер бы лицом в ту сторону, где игрок был обнаружен, и take_damage()
## неверно считал бы "удар сзади" для удара, который пришёл спереди уже
## после того, как игрок обошёл щитовика сбоку.
@export var attack_probability: float = 1.0


func enter() -> void:
	actor.shield_active = true
	actor.velocity.x = 0.0
	actor.animated_sprite.play("block")


func physics_update(_delta: float) -> void:
	if not actor.target:
		state_machine.transition_to("Idle")
		return

	if actor.in_attack_range and actor.attack_cooldown_left <= 0.0:
		if randf() < attack_probability:
			state_machine.transition_to("Attack")
			return
		actor.attack_cooldown_left = actor.attack_cooldown

	actor.velocity.x = 0.0

	var delta_x: float = actor.target.global_position.x - actor.global_position.x
	if abs(delta_x) < actor.horizontal_deadzone:
		return

	var direction: float = sign(delta_x)
	actor.facing_direction = direction
	actor.animated_sprite.flip_h = direction < 0.0
