class_name MeleeWeaponData
extends Resource

## Данные ближнего оружия (light+heavy комбо одного предмета) - вынесены из
## разрозненных @export на player.tscn.gd, чтобы новое оружие добавлялось
## файлом ресурса, а не правкой attack_state.gd/heavy_attack_state.gd.
##
## Сознательно НЕТ полей длительности атаки (light_attack_duration и т.п.) -
## duration по-прежнему вычисляется динамически из числа кадров реальной
## анимации через State.get_animation_duration() (см. фикс рассинхрона от
## 29.08.2026 в CLAUDE.md). Хранить её здесь как отдельное число значило бы
## вернуть именно тот баг, который тогда был осознанно устранён.
##
## Окна активности хитбокса (active_start_ratio/active_end_ratio) тоже
## остаются per-state на attack_state.gd/heavy_attack_state.gd, а не здесь -
## пока нет ни одного реального разного значения под конкретное оружие,
## переносить инфраструктуру под гипотетическую вариативность рано (YAGNI).

@export var display_name: String = ""

@export var light_damage: int = 1
@export var light_combo_max_steps: int = 4
@export var light_combo_reset_time: float = 0.6
@export var light_reach: float = 40.0
@export var light_animation_prefix: String = "attack"

@export var heavy_damage: int = 3
@export var heavy_combo_max_steps: int = 3
@export var heavy_combo_reset_time: float = 0.7
@export var heavy_reach: float = 45.0
@export var heavy_animation_prefix: String = "heavy_attack"
