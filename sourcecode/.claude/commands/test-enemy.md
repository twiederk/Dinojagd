---
name: test-new-enemy
description: "Quick command to validate and test a newly created enemy script in Dinojagd. Checks basic functionality and provides debug output."
slots:
  enemy_name:
    description: "Name of the enemy class (e.g., 'Goblin', 'Flyer')"
---

# Test New Enemy Command

## Usage

```
/test-new-enemy Goblin
```

## What It Does

1. ✅ **Syntax Check**: Validates GDScript syntax
2. 🔍 **Structure Check**: Verifies enemy follows Dinojagd pattern
3. ⚙️ **Runtime Test**: Instantiates enemy in test scene
4. 📊 **Output Report**: Shows health, speed, damage values
5. 🐛 **Debug Hints**: Identifies common mistakes

## Checklist for New Enemy

Create your enemy script first:

```gdscript
class_name MyEnemy  # Change this!
extends CharacterBody2D

var Constants = preload("res://scripts/constants.gd")

# 1. Add constants for your enemy
const MY_ENEMY_HP = 50
const MY_ENEMY_SPEED = 100.0
const MY_ENEMY_DAMAGE = 10
const MY_ENEMY_SPRITE = "res://assets/MyEnemy.png"

# 2. Setup stats
var hp: int = MY_ENEMY_HP
var max_hp: int = MY_ENEMY_HP
var damage: int = MY_ENEMY_DAMAGE
var speed: float = MY_ENEMY_SPEED

# 3. AI state
var ai_mode: String = "PATROL"

# 4. Signals
signal health_changed(hp: int, max_hp: int)
signal enemy_died

# 5. Ready
func _ready() -> void:
	add_to_group("enemies")

# 6. Physics
func _physics_process(delta: float) -> void:
	velocity = move_and_slide(velocity)

# 7. Damage
func take_damage(amount: int) -> void:
	hp -= amount
	health_changed.emit(hp, max_hp)
	if hp <= 0:
		die()

func die() -> void:
	enemy_died.emit()
	queue_free()
```

Then run: `/test-new-enemy MyEnemy`

## Output Example

```
=== Enemy Test Report: MyEnemy ===

✅ Syntax Valid
✅ Class name matches file
✅ Extends CharacterBody2D

📊 Stats:
  - HP: 50/50
  - Speed: 100.0
  - Damage: 10
  - AI Mode: PATROL

⚠️ Warnings:
  - No sprite loaded (check MY_ENEMY_SPRITE path)

✅ Ready to test in Main.tscn!
```

## Next Steps

1. Create `scenes/enemies/MyEnemy.tscn` with:
   - Root: CharacterBody2D (named `MyEnemy`)
   - Children: Sprite2D, CollisionShape2D, DetectionArea, DamageArea
   - Attach script to root

2. Add to `constants.gd`:
   ```gdscript
   const MY_ENEMY_HP = 50
   const MY_ENEMY_SPEED = 100.0
   const MY_ENEMY_DAMAGE = 10
   const MY_ENEMY_SPRITE_PATH = "res://assets/MyEnemy.png"
   ```

3. Instance in `Main.tscn` and test!

## Debug Tips

- Check enemy position updates in Game view
- Verify collision shapes are visible (Debug → Visible Collision Shapes)
- Print AI state: `print("AI: ", ai_mode)`
- Check signal connections: Inspector → Node → Signals

