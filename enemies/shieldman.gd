extends Enemy
class_name Shieldman

## Второй архетип врага - "Щитовик" (art/Enemies/Shield/tarkus). Пассивный
## щит блокирует урон СПЕРЕДИ, пока shield_active == true (поднят в Idle/
## Chase щитовика, опущен во время его собственной атаки и во время любого
## стана - см. shieldman_idle_state.gd/shieldman_chase_state.gd/
## shieldman_attack_state.gd и enemies/States/stagger_state.gd). Разрушение
## щита - отдельный, более длинный стан (is_shield_break/
## shield_break_stagger_duration в общем stagger_state.gd) с полным
## восстановлением щита разом по выходу именно из этого стана.

@export var shield_max_durability: float = 6.0
@export var shield_light_damage: float = 2.0
@export var shield_heavy_damage: float = 5.0
@export var shield_overhead_threshold: float = 60.0

## Акцентный цвет партиклов на блокированном ударе - отличается от обычного
## красного "урон" (components/hit_particles.tscn), чтобы блок читался
## отдельно от настоящего попадания.
const BLOCK_PARTICLE_COLOR: Color = Color(0.4, 0.75, 1.0, 1.0)

var shield_active: bool = false
var shield_durability: float = 0.0

## У базового Enemy такого поля нет - направление там нужно только для
## flip_h спрайта и считается на лету в chase_state.gd/attack_state.gd, не
## сохраняется. Здесь оно требуется постоянно (take_damage() сравнивает
## его с положением атакующего хитбокса), поэтому хранится явно и
## обновляется в shieldman_chase_state.gd/shieldman_attack_state.gd.
var facing_direction: float = 1.0


func _ready() -> void:
	super._ready()
	shield_durability = shield_max_durability


func set_shield_active(value: bool) -> void:
	shield_active = value


func restore_shield() -> void:
	shield_durability = shield_max_durability
	shield_active = true


func take_damage(amount: int, attacker: Node = null, is_heavy: bool = false) -> void:
	if not shield_active or not _is_frontal_hit(attacker):
		super.take_damage(amount, attacker, is_heavy)
		return

	var shield_damage: float = shield_heavy_damage if is_heavy else shield_light_damage
	shield_durability = maxf(shield_durability - shield_damage, 0.0)
	_spawn_block_particles()

	if shield_durability <= 0.0:
		var stagger: Node = state_machine.states.get("Stagger")
		if stagger:
			stagger.is_shield_break = true
		state_machine.transition_to("Stagger")


## Та же система хит-партиклов, что и у обычного попадания
## (components/hit_particles.tscn, HIT_PARTICLES_SCENE унаследован из
## Enemy), но с другим цветом. Просто modulate тут не подошёл бы:
## process_material.color в hit_particles.tscn задан как чистый красный
## (зелёный и синий каналы = 0), а modulate только УМНОЖАЕТ базовый цвет
## партикла - умножение не может поднять уже нулевой канал выше нуля, то
## есть увести цвет от красного одним modulate физически нельзя. Поэтому
## process_material дублируется (.duplicate()) перед правкой - без этого
## перезапись .color задела бы общий ресурс, разделяемый ВСЕМИ инстансами
## HIT_PARTICLES_SCENE (обычные красные партиклы прочих попаданий тоже
## посинели бы, т.к. sub_resource в PackedScene не копируется на лету при
## instantiate()).
func _spawn_block_particles() -> void:
	var hit_particles: GPUParticles2D = HIT_PARTICLES_SCENE.instantiate()
	get_tree().current_scene.add_child(hit_particles)
	hit_particles.global_position = hurtbox_shape.global_position

	var block_material: Resource = hit_particles.process_material.duplicate()
	block_material.color = BLOCK_PARTICLE_COLOR
	hit_particles.process_material = block_material


## "Спереди" - атакующий хитбокс на той же стороне по X, куда сейчас смотрит
## щитовик (facing_direction), и не выше него больше чем на
## shield_overhead_threshold (иначе это удар сверху - щит от него не
## защищает). attacker может быть кинжалом/стрелой (у них нет своего
## attack_hitbox с таким именем) - тогда считать нечего, удар просто не
## блокируется щитом и проходит как обычный урон (щит сейчас реагирует
## только на ближний бой игрока, не на метательное оружие).
func _is_frontal_hit(attacker: Node) -> bool:
	if attacker == null:
		return false

	var attack_hitbox: Node = attacker.get("attack_hitbox")
	if not (attack_hitbox is Node2D):
		return false

	var hit_position: Vector2 = attack_hitbox.global_position

	if (global_position.y - hit_position.y) > shield_overhead_threshold:
		return false

	var dx := hit_position.x - global_position.x
	return signf(dx) == facing_direction
