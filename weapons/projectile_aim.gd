class_name ProjectileAim

## Автоприцел (снап угла в момент выстрела/броска, без самонаведения в
## полёте - референс Dead Cells). Чистый utility-класс со статическим
## методом, не узел сцены - implicit extends RefCounted, get_tree() внутри
## недоступен напрямую, поэтому дерево берётся через Engine.get_main_loop().

static func find_aim_direction(origin: Vector2, facing_direction: float, max_angle_degrees: float, max_range: float) -> Vector2:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return Vector2(facing_direction, 0.0)

	var best_aim_point: Vector2 = Vector2.ZERO
	var best_distance: float = INF
	var found_target: bool = false

	for enemy in tree.get_nodes_in_group("enemy"):
		if not (enemy is Node2D):
			continue

		var aim_point := _get_aim_point(enemy)
		var to_enemy: Vector2 = aim_point - origin
		if signf(to_enemy.x) != facing_direction:
			continue

		var distance := to_enemy.length()
		if distance > max_range:
			continue

		# Угол считаем относительно вектора facing_direction (а не абсолютной
		# горизонтали) - иначе при facing_direction == -1 враг строго слева
		# получил бы angle() == 180° и был бы ошибочно отфильтрован.
		var angle_degrees := absf(rad_to_deg(Vector2(facing_direction, 0.0).angle_to(to_enemy)))
		if angle_degrees > max_angle_degrees:
			continue

		if distance < best_distance:
			best_distance = distance
			best_aim_point = aim_point
			found_target = true

	if not found_target:
		return Vector2(facing_direction, 0.0)

	return (best_aim_point - origin).normalized()


## Точка прицеливания на теле врага. enemy.global_position - это origin узла
## Enemy (у текущего арта капсула тела смещена так, что origin приходится
## почти на макушку, а не на центр масс - см. enemy.tscn), поэтому целиться
## в него напрямую наводило снаряды заметно выше цели даже при стрельбе в
## упор на одном уровне с игроком. hurtbox_shape - уже существующая на
## Enemy ссылка на CollisionShape2D хёртбокса (используется, например, для
## спавна партиклов урона в enemy.gd) - её глобальная позиция гораздо ближе
## к реальному центру тела и переиспользует уже принятую в проекте точку
## "куда засчитывается попадание", а не вводит новое магическое число.
static func _get_aim_point(enemy: Node2D) -> Vector2:
	var hurtbox_shape: Node = enemy.get("hurtbox_shape")
	if hurtbox_shape is Node2D:
		return hurtbox_shape.global_position
	return enemy.global_position
