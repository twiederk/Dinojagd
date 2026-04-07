# Game Systems & Architecture

**Use when:** working on core game loops, main scene logic, inventory, item spawning, or overall game architecture.

---

## 🎮 Core Game Loop

### Game States (main.gd)
```gdscript
var game_state: String = "playing"  # "playing", "paused", "game_over"

func _ready() -> void:
	game_state = "playing"

func _process(delta: float) -> void:
	match game_state:
		"playing":
			_handle_playing()
		"paused":
			_handle_paused()
		"game_over":
			_handle_game_over()
```

### Main Scene Structure
```
Main (Node2D) - main.gd
├── Player (CharacterBody2D) - player.gd
├── TRex (CharacterBody2D) - t_rex.gd
├── Brontosaurus (CharacterBody2D) - brontosaurus.gd
├── Lore (CharacterBody2D) - lore.gd
├── ItemSpawner (Node2D) - item_spawner.gd
├── HUD (CanvasLayer) - hud.gd
│   ├── HealthBar (Control)
│   └── InventoryUI (Control)
└── Camera2D - follows Player
```

---

## 📦 Item System Architecture

### Item Types (constants.gd)
```gdscript
enum ItemType {
	WEAPON,      # Gewehr
	GRASS,       # Gras
	SADDLE,      # Sattel
	QUAD         # Quad
}

const ITEM_NAMES = {
	ItemType.WEAPON: "Gewehr",
	ItemType.GRASS: "Gras",
	ItemType.SADDLE: "Sattel",
	ItemType.QUAD: "Quad"
}

const ITEM_SPRITE_PATHS = {
	ItemType.WEAPON: "res://assets/Gewehr.png",
	ItemType.GRASS: "res://assets/Gras.png",
	ItemType.SADDLE: "res://assets/Sattel.png",
	ItemType.QUAD: "res://assets/Quad.png"
}
```

### Item Spawning (item_spawner.gd)
```gdscript
var ItemScene = preload("res://scenes/items/Item.tscn")
var spawn_timer: float = 0.0
const SPAWN_INTERVAL = 5.0  # Seconds between spawns
const MAX_ITEMS_ON_MAP = 10

func _process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL and get_child_count() < MAX_ITEMS_ON_MAP:
		_spawn_item()
		spawn_timer = 0.0

func _spawn_item() -> void:
	var item = ItemScene.instantiate()
	var item_type = Constants.ItemType.values()[randi() % Constants.ItemType.size()]
	item.set_item_type(item_type)
	item.global_position = _random_spawn_position()
	add_child(item)
```

### Item Collection (player.gd)
```gdscript
var inventory: Dictionary = {}  # { ItemType: count }

func add_item(item_type: int) -> void:
	if item_type not in inventory:
		inventory[item_type] = 0
	inventory[item_type] += 1
	item_collected.emit(item_type)
	print("Collected: %s (x%d)" % [Constants.ITEM_NAMES[item_type], inventory[item_type]])

func has_item(item_type: int, count: int = 1) -> bool:
	return inventory.get(item_type, 0) >= count

func use_items(items: Dictionary) -> bool:
	for item_type: int in items:
		if not has_item(item_type, items[item_type]):
			return false
	
	# Consume items
	for item_type: int in items:
		inventory[item_type] -= items[item_type]
	
	return true
```

---

## 🎯 Inventory System

### Item Storage Pattern
```gdscript
# Simple counting model
var inventory: Dictionary = {
	Constants.ItemType.WEAPON: 0,    # 0 or 1
	Constants.ItemType.GRASS: 0,     # 0 or more
	Constants.ItemType.SADDLE: 0,    # 0 or 1
	Constants.ItemType.QUAD: 0       # 0 or 1
}

# Safe getters
func has_gun() -> bool:
	return inventory.get(Constants.ItemType.WEAPON, 0) > 0

func can_ride_brontosaurus() -> bool:
	return has_item(Constants.ItemType.GRASS) and has_item(Constants.ItemType.SADDLE)

func can_ride_quad() -> bool:
	return has_item(Constants.ItemType.QUAD)
```

---

## 🚗 Vehicle System

### Mount Logic (player.gd)
```gdscript
var is_mounted: bool = false
var current_mount: CharacterBody2D = null

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("mount"):
		if can_ride_brontosaurus():
			_mount_brontosaurus()
		elif is_mounted:
			_unmount()

func _mount_brontosaurus() -> void:
	is_mounted = true
	current_mount = nearby_brontosaurus
	
	# Make player a child of brontosaurus
	get_parent().remove_child(self)
	current_mount.add_child(self)
	global_position = current_mount.global_position
	
	# Use items
	use_items({
		Constants.ItemType.GRASS: 1,
		Constants.ItemType.SADDLE: 1
	})

func _unmount() -> void:
	is_mounted = false
	var parent = current_mount.get_parent()
	current_mount.remove_child(self)
	parent.add_child(self)
	current_mount = null
```

### Quad/Lore Vehicle (vehicles/lore.gd)
```gdscript
class_name Lore
extends CharacterBody2D

const SPEED_NORMAL = 150.0
const SPEED_QUAD = 300.0

var speed: float = SPEED_NORMAL
var player_inside: bool = false

func _process(delta: float) -> void:
	if player_inside:
		speed = SPEED_QUAD
	else:
		speed = SPEED_NORMAL
	
	# Movement logic
	velocity = Vector2.ZERO
	velocity = move_and_slide(velocity)
```

---

## ⚔️ Combat System

### Bullet System (bullet.gd)
```gdscript
class_name Bullet
extends Area2D

var velocity: Vector2 = Vector2.ZERO
const SPEED = 400.0
const LIFETIME = 5.0
var lifetime_remaining: float = LIFETIME

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	global_position += velocity * delta
	lifetime_remaining -= delta
	if lifetime_remaining <= 0:
		queue_free()

func _on_area_entered(area: Node2D) -> void:
	if area is CharacterBody2D and area.name == "TRex":
		area.take_damage(Constants.PLAYER_DAMAGE)
		queue_free()
```

### Shooting (player.gd)
```gdscript
var has_gun: bool = false
var gun_cooldown: float = 0.0
const GUN_COOLDOWN_MAX = 0.5

func _process(delta: float) -> void:
	if gun_cooldown > 0:
		gun_cooldown -= delta
	
	if Input.is_action_just_pressed("ui_accept") and has_gun:
		_shoot()

func _shoot() -> void:
	if gun_cooldown > 0:
		return
	
	var bullet = BulletScene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position + last_direction * 20
	bullet.velocity = last_direction * bullet.SPEED
	
	gun_cooldown = GUN_COOLDOWN_MAX
```

---

## 💚 Health & Damage System

### Health Signals
```gdscript
signal health_changed(hp: int, max_hp: int)
signal died

func take_damage(amount: int) -> void:
	hp = clampi(hp - amount, 0, max_hp)
	health_changed.emit(hp, max_hp)
	
	if hp <= 0:
		died.emit()
		_die()
```

### HUD Health Display (hud.gd)
```gdscript
@onready var player_health_bar = $PlayerHealthBar
@onready var enemy_health_bar = $EnemyHealthBar

func _ready() -> void:
	player.health_changed.connect(_on_player_health_changed)
	enemy.health_changed.connect(_on_enemy_health_changed)

func _on_player_health_changed(hp: int, max_hp: int) -> void:
	var health_percent = float(hp) / float(max_hp)
	player_health_bar.value = health_percent

func _on_enemy_health_changed(hp: int, max_hp: int) -> void:
	var health_percent = float(hp) / float(max_hp)
	enemy_health_bar.value = health_percent
```

---

## 🎪 Game Over & Restart

### Main Game Loop (main.gd)
```gdscript
func _ready() -> void:
	player.died.connect(_on_player_died)
	game_state = "playing"

func _process(delta: float) -> void:
	if game_state == "game_over":
		if Input.is_action_just_pressed("ui_accept"):  # Press 'R' or Space
			restart_game()

func _on_player_died() -> void:
	game_state = "game_over"
	get_tree().paused = true
	show_game_over_screen()

func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
```

---

## 🔗 System Integration Patterns

### Signal Flow Chart
```
Player (take_damage) 
  ↓ Emit: health_changed
  ↓
HUD (update health bar)

TRex (take_damage)
  ↓ Emit: health_changed, enemy_died
  ↓
HUD (update enemy health bar)
Main (end game if enemy dies)

Item (collected)
  ↓ Emit: item_collected
  ↓
Player (add_item)
  ↓
HUD (update inventory display)
```

### Inter-System Communication
| Source | Event | Target | Action |
|--------|-------|--------|--------|
| Item | `item_collected` | Player | Add to inventory |
| Player | `item_collected` | HUD | Update display |
| TRex | `health_changed` | HUD | Update health bar |
| Player | `died` | Main | Start game over |
| Main | `restart` | Scene | Reload scene |

---

## 🎲 Difficulty & Spawning

### Adaptive Spawning
```gdscript
# In item_spawner.gd - spawn rarer items as player gets stronger
func _get_spawn_weights() -> Dictionary:
	var player_hp_percent = float(player.hp) / float(player.max_hp)
	
	if player_hp_percent < 0.3:  # Struggling
		return {
			Constants.ItemType.GRASS: 0.5,
			Constants.ItemType.WEAPON: 0.3,
			Constants.ItemType.SADDLE: 0.15,
			Constants.ItemType.QUAD: 0.05
		}
	elif player_hp_percent < 0.7:  # Normal
		return {
			Constants.ItemType.GRASS: 0.3,
			Constants.ItemType.WEAPON: 0.3,
			Constants.ItemType.SADDLE: 0.2,
			Constants.ItemType.QUAD: 0.2
		}
	else:  # Strong
		return {
			Constants.ItemType.GRASS: 0.2,
			Constants.ItemType.WEAPON: 0.2,
			Constants.ItemType.SADDLE: 0.3,
			Constants.ItemType.QUAD: 0.3
		}
```

---

## 🎯 When to Use This Skill

- Working on `main.gd` main game loop
- Adding new items or mechanics
- Implementing new vehicles
- Fixing inventory/combat bugs
- Refactoring game architecture
