extends Enemy
class_name Archer

## Третий архетип врага - "Лучник" (art/Enemies/GandalfHardcore Archer).
## Держит дистанцию и атакует стрелами вместо ближнего боя - вся логика
## удержания дистанции и выстрела живёт в archer_chase_state.gd/
## archer_attack_state.gd (States/), не здесь. Никакого take_damage()/
## facing_direction-переопределения не требуется: в отличие от Shieldman,
## у Archer нет собственного состояния, завязанного на постоянно
## хранимое направление взгляда (обычные chase/attack-состояния у Enemy
## тоже считают направление на лету через sign(delta_x), не сохраняя его
## полем актора - см. ответ в чате по CLAUDE.md-сессии добавления Archer).
