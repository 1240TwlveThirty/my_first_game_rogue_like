extends CanvasLayer

## Переиспользуемый механизм показа последовательности строк - ничего не
## знает заранее ни про Гонца, ни про будущего торговца в хабе, только
## "показать lines[0], по interact - следующая, пока не кончатся, потом
## скрыться и сообщить finished". process_mode = Always (тот же паттерн,
## что у ui/game_over_ui.gd/.tscn) - работает в любом дереве, паузнутом
## или нет.
##
## НЕ трогает get_tree().paused вообще - вместо паузы дерева (общий,
## ничем не защищённый ресурс, за который конкурировали Game Over и эта
## сцена, см. чат) выставляет автозагружаемый DialogueState.is_active.
## Кто угодно, кому нужно "не даём игроку двигаться, пока идёт диалог",
## сам читает этот флаг там, где ему нужно (см. player.tscn.gd) - вместо
## того, чтобы диалог глушил вообще всё дерево целиком, включая чужие
## независимые процессы (например, SAFETY_TIMEOUT смерти игрока).

signal finished

@onready var label: Label = $Control/VBoxContainer/Label

var lines: Array[String] = []
var current_index: int = 0


func _ready() -> void:
	visible = false


func show_lines(new_lines: Array[String]) -> void:
	lines = new_lines
	current_index = 0
	if lines.is_empty():
		finished.emit()
		return
	label.text = lines[current_index]
	visible = true
	DialogueState.is_active = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_advance()


func _advance() -> void:
	current_index += 1
	if current_index >= lines.size():
		_finish()
		return
	label.text = lines[current_index]


func _finish() -> void:
	visible = false
	DialogueState.is_active = false
	finished.emit()
