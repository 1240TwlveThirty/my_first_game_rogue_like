extends CanvasLayer

## Плейсхолдер-индикатор активной глобальной остановки времени (спайк).
## Опрашивает TimeStop.is_active каждый кадр - у синглтона нет сигналов,
## polling проще, чем заводить их ради одного bool здесь.

@onready var overlay: ColorRect = $Overlay


func _process(_delta: float) -> void:
	overlay.visible = TimeStop.is_active
