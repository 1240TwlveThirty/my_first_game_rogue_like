extends State

## Средняя дистанция ротации Гонца (см. messenger_chase_state.gd) -
## давление на расстоянии через boss_dagger.gd, отдельный самостоятельный
## вариант, а не только крайняя мера. evasion_punish_threshold/Teleport
## срабатывает независимо от этого состояния - тикает и проверяется
## централизованно в messenger.gd._physics_process(), не завязан на то,
## какое состояние сейчас активно.
##
## Прицеливание - тот же приём, что и у archer_attack_state.gd: целится
## напрямую в actor.target.hurtbox_shape (единственная известная цель),
## не через ProjectileAim.find_aim_direction() (та функция ищет ЛУЧШУЮ
## цель по группе "enemy" среди кандидатов - здесь не нужна).
##
## throw_offset - точка ВЫЛЕТА кинжала (не путать с точкой прицела выше).
## Раньше был (0,-10) и кинжал стартовал над головой Гонца - actor.global_position
## у текущего арта (Outline-вариант, сетка кадра 120x80, AnimatedSprite2D
## centered=true) и так почти на макушке: bbox силуэта idle-кадра
## x[44,64] y[42,79] в координатах кадра, центр кадра - y=40, значит
## голова (y=42) всего на 2px ниже origin, а -10 уводил точку вылета ещё
## на 10px выше макушки. Пересчитано под грудь/руку: ~40% пути от головы
## к ногам ((42-40) + (79-42)*0.4 ≈ 17 px в локальных координатах спрайта),
## умножено на текущий scale спрайта (3.1) -> ~52px вниз. Округлено до 50 -
## тот же уровень приблизительности, что и у Archer/Shieldman до финального
## арта: если визуально окажется чуть ниже/выше "руки" - это ожидаемо для
## плейсхолдера, точная подгонка ждёт финального перса.

enum Phase { WINDUP, RECOVERY }

@export var windup_duration: float = 0.3
@export var recovery_duration: float = 0.4
@export var throw_offset: Vector2 = Vector2(0.0, 50.0)

const BOSS_DAGGER_SCENE: PackedScene = preload("res://enemies/projectiles/boss_dagger.tscn")

var phase: Phase = Phase.WINDUP
var timer: float = 0.0


func enter() -> void:
	phase = Phase.WINDUP
	timer = windup_duration
	actor.velocity.x = 0.0
	if actor.target:
		var direction: float = sign(actor.target.global_position.x - actor.global_position.x)
		actor.animated_sprite.flip_h = direction < 0.0
	actor.animated_sprite.play("attack_1")


func physics_update(delta: float) -> void:
	actor.velocity.x = 0.0
	timer -= delta
	match phase:
		Phase.WINDUP:
			if timer <= 0.0:
				_throw()
		Phase.RECOVERY:
			if timer <= 0.0:
				_end_attack()


func _throw() -> void:
	phase = Phase.RECOVERY
	timer = recovery_duration
	if actor.target:
		var aim_point: Vector2 = actor.target.global_position
		var target_hurtbox: Node = actor.target.get("hurtbox_shape")
		if target_hurtbox is Node2D:
			aim_point = target_hurtbox.global_position

		var dagger: Node2D = BOSS_DAGGER_SCENE.instantiate()
		get_tree().current_scene.add_child(dagger)
		dagger.launch(actor.global_position + throw_offset, aim_point, actor)

		# Лимит серии - не более actor.max_daggers_per_burst бросков подряд,
		# затем actor.dagger_burst_cooldown секунд простоя (гейтится в
		# messenger_chase_state.gd, не здесь). Считаем ТОЛЬКО реально
		# состоявшиеся броски (внутри if actor.target - если цель исчезла
		# в последний момент, кинжал не улетел, серия не расходуется).
		actor.daggers_thrown_in_burst += 1
		if actor.daggers_thrown_in_burst >= actor.max_daggers_per_burst:
			actor.daggers_thrown_in_burst = 0
			actor.dagger_burst_cooldown_left = actor.dagger_burst_cooldown


func _end_attack() -> void:
	actor.attack_cooldown_left = actor.attack_cooldown
	if actor.target:
		state_machine.transition_to("Chase")
	else:
		state_machine.transition_to("Idle")
