extends State

enum Phase { ACTIVE, SUCCESS, MISS }

@export var window_duration: float = 0.25
@export var miss_duration: float = 0.3

var phase: Phase = Phase.ACTIVE
var timer: float = 0.0
var _connected: bool = false


func can_be_interrupted() -> bool:
	return phase == Phase.MISS


func enter() -> void:
	phase = Phase.ACTIVE
	timer = window_duration
	actor.velocity.x = 0.0
	actor.animated_sprite.play("parry_start")


func exit() -> void:
	if _connected and actor.animated_sprite.animation_finished.is_connected(_on_success_finished):
		actor.animated_sprite.animation_finished.disconnect(_on_success_finished)
	_connected = false


func physics_update(delta: float) -> void:
	actor.velocity.x = 0.0
	timer -= delta

	match phase:
		Phase.ACTIVE:
			if timer <= 0.0:
				_start_miss()
		Phase.MISS:
			if timer <= 0.0:
				_exit_state()


func try_parry() -> bool:
	if phase != Phase.ACTIVE:
		return false
	phase = Phase.SUCCESS
	actor.animated_sprite.play("parry")
	actor.animated_sprite.animation_finished.connect(_on_success_finished, CONNECT_ONE_SHOT)
	_connected = true
	return true


func _start_miss() -> void:
	phase = Phase.MISS
	timer = miss_duration
	actor.animated_sprite.play("parry_miss")


func _on_success_finished() -> void:
	_connected = false
	_exit_state()


func _exit_state() -> void:
	if not actor.is_on_floor():
		state_machine.transition_to("Fall")
		return

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		state_machine.transition_to("Run")
	else:
		state_machine.transition_to("Idle")
