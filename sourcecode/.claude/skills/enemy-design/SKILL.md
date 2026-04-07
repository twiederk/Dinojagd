# Enemy Design & AI for Dinojagd

**Use when:** creating new enemies, tweaking T-Rex behavior, or designing enemy mechanics.

---

## 🎮 Current Enemy: T-Rex

The T-Rex (`enemies/t_rex.gd`) is the main antagonist with state-based AI.

### AI States

```
PATROL → (Player in range) → CHASE → (Player escaped) → RETURN → PATROL
```

| State | Behavior | Conditions |
|-------|----------|-----------|
| **PATROL** | Walk in random pattern | Player not detected |
| **CHASE** | Hunt player/vehicles | Detection area triggered |
| **IDLE** | Wait | Cooldown after failed attack |
| **RETURN** | Go back to spawn | Player out of range for 5 seconds |

---

## 🧠 T-Rex AI Architecture

### 1. Detection System
```gdscript
@onready var detection_area = $DetectionArea  # Circular range
@onready var damage_area = $DamageArea        # Melee damage zone

func _on_detection_entered(body: Node2D) -> void:
	if body is Player:
		player_in_detection = true
		ai_mode = "CHASE"
	elif body.name == "Brontosaurus":
		brontosaurus_in_detection = body
	elif body.name == "Lore":
		lore_in_detection = body
```

### 2. Target Priority
```gdscript
# Priority: Player > Brontosaurus > Lore
func _get_chase_target() -> CharacterBody2D:
	if player_in_detection and player_ref:
		return player_ref
	elif brontosaurus_in_detection:
		return brontosaurus_in_detection
	elif lore_in_detection:
		return lore_in_detection
	return null
```

### 3. State Machine
```gdscript
func _physics_process(delta: float) -> void:
	match ai_mode:
		"PATROL":
			_patrol()
		"CHASE":
			_chase()
		"IDLE":
			velocity = Vector2.ZERO
		"RETURN":
			_return_home()
	
	velocity = move_and_slide(velocity)
	_update_animation(velocity)
```

### 4. Damage Cooldown (Anti-Cheese)
```gdscript
var damage_cooldown: float = 0.0
const DAMAGE_COOLDOWN_MAX = 0.5  # Can't damage faster than this

func take_damage(amount: int) -> void:
	if is_dead:
		return
	
	hp -= amount
	damage_cooldown = DAMAGE_COOLDOWN_MAX
	health_changed.emit(hp, max_hp)
	
	if hp <= 0:
		die()
```

---

## ⚖️ Balance Parameters (constants.gd)

```gdscript
# T-Rex Stats
const T_REX_HP = 50
const T_REX_MAX_HP = 50
const T_REX_DAMAGE = 15
const T_REX_SPEED = 100.0
const T_REX_CHASE_SPEED = 150.0
const T_REX_DETECTION_RANGE = 300.0
const T_REX_SPRITE_PATH = "res://assets/T-Rex.png"

# Difficulty Scaling
const T_REX_COOLDOWN_DAMAGE = 0.5  # Seconds between damage hits
```

### Balancing Guide

| Parameter | Impact | Recommendation |
|-----------|--------|-----------------|
| `T_REX_HP` | Durability | ↑ if enemies die too fast |
| `T_REX_SPEED` | Patrol speed | ↑ for active world feeling |
| `T_REX_CHASE_SPEED` | Hunt speed | ↑ for harder difficulty |
| `T_REX_DETECTION_RANGE` | Awareness distance | ↑ for larger maps |
| `T_REX_DAMAGE` | Player threat | ↑ if battles feel trivial |

---

## 🎯 Creating New Enemies

### Template Structure

```gdscript
class_name NewEnemy
extends CharacterBody2D

var Constants = preload("res://scripts/constants.gd")

# 1. Stats
var hp: int = Constants.ENEMY_HP
var max_hp: int = Constants.ENEMY_MAX_HP
var damage: int = Constants.ENEMY_DAMAGE
var speed: float = Constants.ENEMY_SPEED

# 2. AI State
var ai_mode: String = "PATROL"
var chase_target: CharacterBody2D = null

# 3. Nodes
@onready var sprite = $Sprite2D
@onready var detection_area = $DetectionArea
@onready var damage_area = $DamageArea

# 4. Signals
signal health_changed(hp: int, max_hp: int)
signal enemy_died

func _ready() -> void:
	add_to_group("enemies")
	if detection_area:
		detection_area.body_entered.connect(_on_detection_entered)

func _physics_process(delta: float) -> void:
	match ai_mode:
		"PATROL":
			_patrol()
		"CHASE":
			_chase()
	
	velocity = move_and_slide(velocity)

func take_damage(amount: int) -> void:
	hp -= amount
	health_changed.emit(hp, max_hp)
	if hp <= 0:
		die()

func die() -> void:
	enemy_died.emit()
	queue_free()
```

### Checklist for New Enemies

- [ ] Create `enemies/NewEnemy.gd` script
- [ ] Add stats to `constants.gd` (`ENEMY_HP`, `ENEMY_SPEED`, etc.)
- [ ] Create `scenes/enemies/NewEnemy.tscn` with:
  - CharacterBody2D root
  - Sprite2D child
  - CollisionShape2D child
  - DetectionArea (Area2D) with collision
  - DamageArea (Area2D) with collision
- [ ] Attach script to root node
- [ ] Add sprite texture in `Constants.ENEMY_SPRITE_PATH`
- [ ] Test with `Main.tscn` (add instance, check pathing)

---

## 🎪 Behavioral Variations

### 1. Ranged Enemy
```gdscript
var projectile_cooldown: float = 0.0
const PROJECTILE_COOLDOWN_MAX = 1.5

func _chase() -> void:
	if chase_target:
		var dist = global_position.distance_to(chase_target.global_position)
		if dist < Constants.RANGED_DETECTION_RANGE:
			if projectile_cooldown <= 0:
				_fire_projectile()
				projectile_cooldown = PROJECTILE_COOLDOWN_MAX
```

### 2. Pack Behavior
```gdscript
@export var pack_range: float = 150.0
var nearby_allies: Array = []

func _ready() -> void:
	add_to_group("pack_enemies")

func _get_pack_members() -> Array:
	var allies: Array = []
	for enemy in get_tree().call_group("pack_enemies", "get_nearby_count"):
		if global_position.distance_to(enemy.global_position) < pack_range:
			allies.append(enemy)
	return allies
```

### 3. Fleeing Behavior
```gdscript
func _process(delta: float) -> void:
	if hp < max_hp * 0.3:  # Below 30% HP
		ai_mode = "FLEE"
		_flee_from_player()
```

---

## 🛡️ Damage & Defense

### Damage Types
```gdscript
# Melee (T-Rex claws)
func _on_damage_area_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(Constants.T_REX_DAMAGE)

# Ranged (projectiles)
var Projectile = preload("res://scenes/projectiles/EnemyBullet.tscn")
func _fire_projectile() -> void:
	var proj = Projectile.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position
	proj.velocity = (chase_target.global_position - global_position).normalized() * 200
```

### Invincibility Frames
```gdscript
var invincible: bool = false
var invincible_timer: float = 0.0
const INVINCIBLE_DURATION = 0.5

func take_damage(amount: int) -> void:
	if invincible:
		return
	
	hp -= amount
	invincible = true
	invincible_timer = INVINCIBLE_DURATION
	health_changed.emit(hp, max_hp)

func _process(delta: float) -> void:
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			invincible = false
```

---

## 📊 T-Rex Difficulty Scaling

### Easy Mode
```gdscript
const T_REX_HP = 30
const T_REX_SPEED = 80.0
const T_REX_CHASE_SPEED = 120.0
const T_REX_DAMAGE = 8
```

### Normal Mode
```gdscript
const T_REX_HP = 50
const T_REX_SPEED = 100.0
const T_REX_CHASE_SPEED = 150.0
const T_REX_DAMAGE = 15
```

### Hard Mode
```gdscript
const T_REX_HP = 80
const T_REX_SPEED = 120.0
const T_REX_CHASE_SPEED = 180.0
const T_REX_DAMAGE = 20
```

---

## 🐛 Common Enemy Bugs

| Bug | Cause | Fix |
|-----|-------|-----|
| Enemy stuck in wall | Collision overlap | Check CollisionShape2D size |
| AI always chasing | Signal not disconnecting | Disconnect in `_on_detection_exited()` |
| Enemy won't take damage | No `damage_cooldown` check | Add cooldown gate |
| Game lag when enemies spawn | `load()` in loop | Use `preload()` |
| Dead enemy still dealing damage | No `is_dead` check | Add `var is_dead: bool = false` state |

---

## 🎯 When to Use This Skill

- Adding new enemy types
- Tweaking T-Rex difficulty/balance
- Debugging enemy AI behavior
- Understanding enemy damage/health systems
