extends State

## Переработанная сцена смерти Гонца - НЕ переиспользует общий
## enemies/States/death_state.gd. Три фазы: CROUCH (поза "на колени",
## клип "crouch" - см. messenger_frames.tres, честный animation_finished,
## не зациклен) -> DIALOGUE (показ пяти предсмертных реплик через
## ui/dialogue_box.tscn, дословно из SCRIPT_VERTICAL_SLICE.md) -> DEATH
## (честная анимация "death" с начала, ожидание animation_finished - у
## Гонца тоже сознательно loop=false с самого создания ресурса, в отличие
## от известного бага "death"/"parry" на других акторах, см. CLAUDE.md).
## После DEATH - появление портала в хаб (environment/hub_portal.gd,
## найден по группе "hub_portal") и queue_free() актора.
##
## СОЗНАТЕЛЬНО не трогает get_tree().paused нигде во всех трёх фазах -
## раньше DIALOGUE ставил/снимал глобальную паузу дерева, что гонялось с
## arena.gd._on_player_died() (тоже владеет get_tree().paused) при
## одновременной смерти игрока и Гонца: чужая пауза замораживала
## SAFETY_TIMEOUT смерти игрока/анимацию "death" самого Гонца буквально
## посреди процесса, искажая порядок событий (см. разбор в чате). Теперь
## DialogueBox сам выставляет DialogueState.is_active (autoload) вместо
## паузы - player.tscn.gd читает этот флаг явно и блокирует только
## обычный ввод, НЕ состояние Death (см. комментарий там же). Messenger
## (весь узел, process_mode=Always в messenger.tscn) продолжает
## обрабатываться независимо от того, ставит ли arena.gd
## get_tree().paused ИЗ-ЗА смерти игрока где-то параллельно - собственная
## сцена смерти Гонца доигрывается корректно в любом случае.

enum Phase { CROUCH, DIALOGUE, DEATH }

## Безусловно false на все три фазы - без этого централизованные проверки
## в messenger.gd._physics_process() (evasion_punish_threshold -> Teleport,
## _check_dodge_trigger()) обе читают именно can_be_interrupted() текущего
## состояния и, видя дефолтный true, спокойно обрывали сцену смерти прямо
## посреди CROUCH/DIALOGUE/DEATH - см. разбор в чате. Раньше это маскировала
## пауза дерева (messenger.gd._physics_process() просто не выполнялся),
## после перехода Messenger на process_mode=Always маскировка исчезла и
## дыра обнажилась.
func can_be_interrupted() -> bool:
	return false

const DIALOGUE_BOX_SCENE: PackedScene = preload("res://ui/dialogue_box.tscn")
const SAFETY_TIMEOUT: float = 1.5  # запасной выход из фазы DEATH, если "death" всё же не доиграет штатно

## Дословно из SCRIPT_VERTICAL_SLICE.md, раздел "Гонец — предсмертные фразы" -
## не сокращено и не перефразировано.
const DIALOGUE_LINES: Array[String] = [
	"— Ты видел? Видел, как я двигался? Быстрее тебя... почти.",
	"— Он обещал, что я стану первым, кого заметят. Первым, о ком заговорят у костра.",
	"— Странно... я думал, это ты меня убиваешь. А внутри — как будто я кого-то отпускаю. Не умираю сам, а... отпускаю.",
	"— Скажи ему... скажи, что я был быстрым.",
]

var phase: Phase = Phase.CROUCH
var _safety_timer: float = 0.0
var _dialogue_box: CanvasLayer = null
var _finished: bool = false


func enter() -> void:
	phase = Phase.CROUCH
	_finished = false
	actor.velocity.x = 0.0
	actor.modulate.a = 1.0
	actor.hurtbox_shape.set_deferred("disabled", true)
	actor.animated_sprite.play("crouch")
	actor.animated_sprite.animation_finished.connect(_on_crouch_finished, CONNECT_ONE_SHOT)


func physics_update(delta: float) -> void:
	if phase != Phase.DEATH:
		return
	_safety_timer += delta
	if _safety_timer >= SAFETY_TIMEOUT:
		_on_death_finished()


func _on_crouch_finished() -> void:
	phase = Phase.DIALOGUE
	_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	get_tree().current_scene.add_child(_dialogue_box)
	_dialogue_box.finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	_dialogue_box.show_lines(DIALOGUE_LINES)


func _on_dialogue_finished() -> void:
	if is_instance_valid(_dialogue_box):
		_dialogue_box.queue_free()
	_dialogue_box = null

	phase = Phase.DEATH
	_safety_timer = 0.0
	actor.animated_sprite.play("death")
	actor.animated_sprite.animation_finished.connect(_on_death_finished, CONNECT_ONE_SHOT)


func _on_death_finished() -> void:
	if _finished:
		return
	_finished = true
	RunState.bosses_killed += 1
	_spawn_portal()
	actor.queue_free()


func _spawn_portal() -> void:
	var portal := get_tree().get_first_node_in_group("hub_portal")
	if portal and portal.has_method("activate"):
		portal.activate()
