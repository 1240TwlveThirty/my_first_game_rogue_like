extends CanvasLayer

## Текстовый плейсхолдер-индикатор активного ближнего оружия. Отдельный
## узел от ui/hud.tscn (здоровье) - разная ответственность.

const ACTIVE_COLOR: Color = Color(1.0, 0.9, 0.3, 1.0)
const INACTIVE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.5)

@onready var mace_label: Label = $Weapons/MaceLabel
@onready var sword_label: Label = $Weapons/SwordLabel

var mace_data: MeleeWeaponData
var sword_data: MeleeWeaponData


func setup(mace: MeleeWeaponData, sword: MeleeWeaponData, current: MeleeWeaponData) -> void:
	mace_data = mace
	sword_data = sword
	_on_melee_weapon_changed(current)


func _on_melee_weapon_changed(weapon: MeleeWeaponData) -> void:
	_update_label(mace_label, mace_data, weapon == mace_data, 1)
	_update_label(sword_label, sword_data, weapon == sword_data, 2)


func _update_label(label: Label, weapon_data: MeleeWeaponData, is_active: bool, slot: int) -> void:
	if is_active:
		label.text = "[%d] %s" % [slot, weapon_data.display_name]
		label.modulate = ACTIVE_COLOR
	else:
		label.text = "%d) %s" % [slot, weapon_data.display_name]
		label.modulate = INACTIVE_COLOR
