extends Node2D

## NPC-торговец в хабе. Реплики выбираются по RunState.bosses_killed -
## Слой Б из SCRIPT_VERTICAL_SLICE.md (общий мета-сюжетный счётчик, живёт
## в autoload, переживает смену сцены арена -> хаб). Слой А (по прогрессу
## этажей текущей локации) ещё не реализуем - см. RunState.current_floor.
##
## Торговца можно опрашивать сколько угодно раз подряд - _get_lines()
## просто пересчитывает актуальные реплики по текущему значению счётчика
## каждый раз заново, ничего не помечается как "уже показано" и не
## блокируется после первого раза.

const DIALOGUE_BOX_SCENE: PackedScene = preload("res://ui/dialogue_box.tscn")

## Дословно из SCRIPT_VERTICAL_SLICE.md, раздел "NPC в хабе - счётчик
## убитых боссов". Счётчики 2-5 там пока не написаны ("предстоит по мере
## того, как дойдёт очередь до остальных боссов") - массив нарочно короче
## возможного диапазона RunState.bosses_killed, _get_lines() ниже держит
## последний написанный набор реплик, если счётчик уйдёт дальше.
const LINES_BY_BOSS_COUNT: Array = [
	["— Ещё один поднялся из бездны. Раньше вас таких было пятеро. Теперь — ты один и я. Бери, что можешь унести, воин. Здесь этому всё равно не пригодится."],
	["— Гонца больше нет?", "Он всегда бежал впереди всех — даже в бездну, кажется, добежал первым. Странно... с каждым, кого ты кладёшь в землю, воздух здесь как будто теплее. Ты замечал?"],
]

var _player_in_range: bool = false

@onready var interaction_zone: Area2D = $InteractionZone
@onready var prompt_label: Label = $PromptLabel


func _ready() -> void:
	prompt_label.visible = false
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)


## Гейт на DialogueState.is_active здесь же, а не только в _update_prompt() -
## не даёт открыть диалог поверх уже идущего (ни поверх собственного, ни
## поверх чужого, например предсмертной сцены Гонца, если бы игрок как-то
## успел добежать досюда во время неё).
func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range or DialogueState.is_active:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_start_dialogue()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		_update_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_update_prompt()


func _update_prompt() -> void:
	prompt_label.visible = _player_in_range and not DialogueState.is_active


func _start_dialogue() -> void:
	var dialogue_box: CanvasLayer = DIALOGUE_BOX_SCENE.instantiate()
	get_tree().current_scene.add_child(dialogue_box)
	dialogue_box.finished.connect(_on_dialogue_finished.bind(dialogue_box), CONNECT_ONE_SHOT)
	dialogue_box.show_lines(_get_lines())
	_update_prompt()


func _on_dialogue_finished(dialogue_box: CanvasLayer) -> void:
	dialogue_box.queue_free()
	_update_prompt()


func _get_lines() -> Array[String]:
	var index: int = clampi(RunState.bosses_killed, 0, LINES_BY_BOSS_COUNT.size() - 1)
	var lines: Array[String] = []
	lines.assign(LINES_BY_BOSS_COUNT[index])
	return lines
