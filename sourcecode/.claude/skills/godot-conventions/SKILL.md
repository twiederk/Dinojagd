# Godot 4.6 & GDScript Conventions

**Use when:** writing new scripts, refactoring, or reviewing game code for Dinojagd.

---

## 📋 Naming Conventions

| Element | Pattern | Example |
|---------|---------|---------|
| **Scripts** | `snake_case.gd` | `player.gd`, `t_rex.gd` |
| **Classes** | `PascalCase` | `class_name Player`, `class_name TRex` |
| **Functions** | `_snake_case` | `_ready()`, `_process()`, `_on_body_entered()` |
| **Variables** | `snake_case` | `var speed: float`, `var chase_target` |
| **Constants** | `UPPER_SNAKE_CASE` | `const MAX_HP = 100` |
| **Signals** | `snake_case` | `signal health_changed`, `signal enemy_died` |
| **Private vars** | `_snake_case` prefix | `var _internal_state` *(optional but recommended)* |

---

## 🏗️ Class Structure Pattern

**Every GDScript file MUST start with `class_name`.**

Always follow this structure for Dinojagd scripts:

```gdscript
class_name Player
extends CharacterBody2D

# 1. Imports & Preloads
var Constants = preload("res://scripts/constants.gd")
var BulletScene = preload("res://scenes/bullets/Bullet.tscn")

# 2. Constants (local)
const ACCELERATION = 300.0

# 3. Exported/Configurable Properties
@export var speed: float = 200.0

# 4. State Variables (non-exported)
var velocity: Vector2 = Vector2.ZERO
var is_alive: bool = true
var hp: int = Constants.PLAYER_HP

# 5. @onready References (scene nodes)
@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D

# 6. Signals
signal health_changed(hp: int, max_hp: int)
signal died


# 7. Lifecycle Methods
func _ready() -> void:
	add_to_group("players")


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	velocity = move_and_slide(velocity)


# 8. Input Handling
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		pass


# 9. Custom Methods (public)
func take_damage(amount: int) -> void:
	hp -= amount
	health_changed.emit(hp, max_hp)


# 10. Signal Handlers (_on_*)
func _on_detection_entered(body: Node2D) -> void:
	pass
```

**Important**: Always maintain **two blank lines** between function definitions for readability.

---

## 🎮 GDScript Best Practices für Dinojagd

### ✅ DO:

```gdscript
# 1. Use @onready for node references
@onready var sprite = $Sprite2D

# 2. Use preload() for Scripts & Scenes (avoid load)
var BulletScene = preload("res://scenes/bullets/Bullet.tscn")
var Constants = preload("res://scripts/constants.gd")

# 3. Type hints for all variables & returns
var speed: float = Constants.PLAYER_SPEED

func take_damage(amount: int) -> void:
	pass


# 4. Use constants for magic numbers
var hp: int = Constants.PLAYER_HP  # NOT: var hp: int = 100

# 5. Connect signals in _ready()
func _ready() -> void:
	detection_area.body_entered.connect(_on_body_entered)


# 6. Use _process() for input, _physics_process() for movement
func _process(delta: float) -> void:
	handle_input()  # Polling


func _physics_process(delta: float) -> void:
	velocity = move_and_slide(velocity)


# 7. Emit signals for state changes
signal health_changed(hp: int, max_hp: int)

func take_damage(amount: int) -> void:
	hp -= amount
	health_changed.emit(hp, max_hp)


# 8. Use groups for entity management
add_to_group("enemies")
get_tree().call_group("enemies", "stop_chasing")

# 9. Use _on_* naming for signal handlers
func _on_detection_entered(body: Node2D) -> void:
	pass
```

### ❌ DON'T:

```gdscript
# 1. Don't use load() in loops
for i in range(100):
	var bullet = load("res://scenes/bullets/Bullet.tscn").instantiate()  # SLOW!

# 2. Don't use magic numbers
var hp = 100  # Use Constants.PLAYER_HP instead

# 3. Don't forget type hints
var speed = 200.0  # Add : float

# 4. Don't call get_tree() every frame
var player = get_tree().root.find_child("Player", true, false)  # Do this in _ready()!

# 5. Don't use heavy logic in _process()
func _process(delta: float) -> void:
	var new_bullet = preload("res://scenes/bullets/Bullet.tscn").instantiate()  # Expensive!

# 6. Don't forget signal connections in _ready()
# This works but is not discoverable:
func some_function():
	detection_area.body_entered.connect(_on_body_entered)

# 7. Don't add function documentation using triple quotes
# This is NOT used in Dinojagd:
func take_damage(amount: int) -> void:
	"""Deals damage to the entity."""  # ❌ DON'T DO THIS
	hp -= amount
```

---

## 📐 Formatting & Code Style

### Line Spacing
- **Two blank lines** must separate function definitions
- No double blank lines within function bodies

```gdscript
func _ready() -> void:
	add_to_group("players")


func _process(delta: float) -> void:  # ✅ Two blank lines above
	handle_input()


func _physics_process(delta: float) -> void:  # ✅ Two blank lines above
	velocity = move_and_slide(velocity)
```

### Comment Documentation
- **DO NOT** use triple-quote docstrings (`"""..."""`) for functions
- Use inline comments for clarity instead
- Godot's documentation is maintained via code review, not code docs

```gdscript
# ❌ DON'T: Docstrings
func take_damage(amount: int) -> void:
	"""Damages the entity and updates health."""
	hp -= amount

# ✅ DO: Inline comments
func take_damage(amount: int) -> void:
	hp -= amount  # Reduce health
	health_changed.emit(hp, max_hp)  # Notify listeners
```

### File Header
Every GDScript file must start with `class_name`:

```gdscript
class_name Player  # ✅ ALWAYS first, no comments before it
extends CharacterBody2D

var Constants = preload("res://scripts/constants.gd")
# ... rest of file
```

---

## 💡 Dinojagd-Specific Patterns

### 1. Constants System
(See `scripts/constants.gd`)

All game values are centralized. When balancing:

```gdscript
# In constants.gd:
const PLAYER_HP = 100
const PLAYER_SPEED = 200.0
const T_REX_DAMAGE = 10

# In scripts:
var hp: int = Constants.PLAYER_HP  # NOT hard-coded
var damage: int = Constants.T_REX_DAMAGE
```

### 2. State Machines for AI
(See `enemies/t_rex.gd`)

Use string-based states for simplicity:

```gdscript
var ai_mode: String = "PATROL"  # PATROL, CHASE, IDLE, RETURN

func _physics_process(delta: float) -> void:
	match ai_mode:
		"PATROL":
			_patrol()
		"CHASE":
			_chase()
		"RETURN":
			_return_home()
```

### 3. Damage Cooldown Pattern
Prevent instant-death from rapid hits:

```gdscript
var damage_cooldown: float = 0.0
const DAMAGE_COOLDOWN_MAX = 0.5

func take_damage(amount: int) -> void:
	if damage_cooldown > 0:
		return  # Still in cooldown
	
	hp -= amount
	damage_cooldown = DAMAGE_COOLDOWN_MAX
	health_changed.emit(hp, max_hp)
	
	if hp <= 0:
		died.emit()

func _process(delta: float) -> void:
	if damage_cooldown > 0:
		damage_cooldown -= delta
```

### 4. Inventory System
(See `player.gd`)

```gdscript
var inventory: Dictionary = {}

func add_item(item_type: String) -> void:
	if item_type not in inventory:
		inventory[item_type] = 0
	inventory[item_type] += 1
	item_collected.emit(item_type)

func has_item(item_type: String, count: int = 1) -> bool:
	return inventory.get(item_type, 0) >= count

func use_item(item_type: String) -> void:
	if has_item(item_type):
		inventory[item_type] -= 1
		# Logic here
```

### 5. Entity Detection
Use multiple detection areas for different purposes:

```gdscript
@onready var detection_area = $DetectionArea  # For AI sight
@onready var damage_area = $DamageArea        # For melee damage
@onready var pickup_area = $PickupArea        # For items

func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_entered)
	damage_area.body_entered.connect(_on_damage_entered)
	pickup_area.area_entered.connect(_on_pickup_entered)
```

---

## 🔗 File Organization Rules

- **Scripts**: One class per file
- **Scenes**: One scene per prefab (e.g., `Player.tscn`, `TRex.tscn`)
- **Assets**: Organized by type in `assets/`
- **Resources**: `.tres` files in `assets/` (tilesets, themes, etc.)

---

## 🐛 Common Anti-Patterns to Avoid

| ❌ Anti-Pattern | ✅ Better Way |
|---------|-----------|
| `get_tree().root.find_child()` every frame | Store ref in `_ready()` |
| `load()` in loops | Use `preload()` before the loop |
| No type hints | Add explicit type hints |
| Hard-coded numbers | Use `Constants.PLAYER_HP` |
| Unconnected signals | Connect in `_ready()` |
| State without tracking | Use explicit `state: String` variable |
| No damage cooldown | Implement cooldown timer |

---

## 📚 Resources

- [Godot 4.6 Docs](https://docs.godotengine.org/en/stable/)
- [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
- [Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html)

---

## 🎯 When to Use This Skill

- Writing new enemy/player/item scripts
- Refactoring existing code
- Code reviews for consistency
- Understanding Dinojagd code patterns
