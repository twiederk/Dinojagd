---
name: bug-hunter-agent
description: "Use when: debugging game logic issues, finding performance bottlenecks, investigating crashes, or analyzing unexpected behavior in Dinojagd."
---

# Bug Hunter Agent for Dinojagd

## When to Invoke

```
@Claude "Why is the T-Rex getting stuck in walls?"
@Claude "The game lags when items spawn"
@Claude "Player health doesn't update properly"
```

---

## 🐛 Debugging Workflow

### 1. Reproduce the Bug
- [ ] Clear steps to reproduce
- [ ] Screenshots/videos if visual
- [ ] Current behavior vs expected behavior
- [ ] When did it start? (recent change?)

### 2. Categorize
- **Logic Bug** (wrong behavior)
- **Performance Bug** (lag/crashes)
- **Physics Bug** (collision issues)
- **Signal Bug** (state not updating)

### 3. Find the Root Cause
- Check script logs/print statements
- Verify signal connections
- Review collision shapes
- Check node hierarchy

### 4. Test the Fix
- Reproduce original bug
- Apply fix
- Verify it's gone
- Check for side effects

---

## 🔴 Common Dinojagd Bugs

### Physics & Collision

**Bug**: Enemy stuck in wall
```gdscript
# Issue: CollisionShape2D too large or overlapping
# Fix: Adjust CollisionShape2D size in scene editor

# Also check for velocity getting stuck:
if not is_on_floor():
	velocity.y += gravity  # Must apply gravity every frame
```

**Bug**: Player falls through ground
```gdscript
# Issue: Not using move_and_slide()
velocity = move_and_slide(velocity)  # Not: position += velocity
```

### AI & Logic

**Bug**: T-Rex never chases
```gdscript
# Issue: Signal not connected or detection_area is Area2D when it should be CharacterBody2D
# Check:
if detection_area:
	detection_area.body_entered.connect(_on_detection_entered)  # Body not Area!

# Also check chase_target:
func _on_detection_entered(body: Node2D) -> void:
	if body is Player:  # Check type
		chase_target = body
		ai_mode = "CHASE"
```

**Bug**: Item spawning too fast
```gdscript
# Issue: spawn_timer not resetting or interval is 0
spawn_timer += delta
if spawn_timer >= SPAWN_INTERVAL:  # Check >= not >
	_spawn_item()
	spawn_timer = 0.0  # MUST RESET
```

### Inventory & Items

**Bug**: Inventory doesn't update
```gdscript
# Issue: add_item() not emitting signal
signal item_collected(item_type: int)

func add_item(item_type: int) -> void:
	inventory[item_type] += 1
	item_collected.emit(item_type)  # Must emit!
```

**Bug**: Can't mount Brontosaurus
```gdscript
# Issue: Missing item check or wrong enum
if inventory.get(Constants.ItemType.GRASS, 0) > 0 and \
   inventory.get(Constants.ItemType.SADDLE, 0) > 0:
	_mount_brontosaurus()
```

### Damage & Health

**Bug**: Player takes damage instantly multiple times
```gdscript
# Issue: No damage cooldown
var damage_cooldown: float = 0.0

func take_damage(amount: int) -> void:
	if damage_cooldown > 0:  # THIS CHECK IS ESSENTIAL
		return
	
	hp -= amount
	damage_cooldown = DAMAGE_COOLDOWN_MAX
	health_changed.emit(hp, max_hp)

func _process(delta: float) -> void:
	if damage_cooldown > 0:
		damage_cooldown -= delta
```

**Bug**: Health bar doesn't update
```gdscript
# Issue: Signal not connected or wrong parameters
signal health_changed(hp: int, max_hp: int)

# In HUD.gd:
func _ready() -> void:
	player.health_changed.connect(_on_player_health_changed)

func _on_player_health_changed(hp: int, max_hp: int) -> void:
	var percent = float(hp) / float(max_hp)
	health_bar.value = percent * 100  # Scale to 0-100
```

### Performance

**Bug**: Game lags during item spawning
```gdscript
# ❌ WRONG:
for i in range(100):
	var item = load("res://scenes/items/Item.tscn").instantiate()  # load() in loop!

# ✅ CORRECT:
var ItemScene = preload("res://scenes/items/Item.tscn")  # Preload once
for i in range(100):
	var item = ItemScene.instantiate()  # Fast!
```

**Bug**: Camera jittery
```gdscript
# Issue: Update position every frame instead of lerp
# ❌ WRONG:
camera.global_position = player.global_position

# ✅ CORRECT:
camera.global_position = camera.global_position.lerp(player.global_position, 0.1)
```

---

## 🔍 Debugging Tools

### Print Debug
```gdscript
print("AI Mode: ", ai_mode)
print("Chase target: ", chase_target)
print("Detection area children: ", detection_area.get_overlapping_bodies())
```

### Error Checking
```gdscript
if not detection_area:
	push_error("Missing DetectionArea child node!")
	return

if not player_ref:
	push_error("Could not find Player in scene!")
	return
```

### Performance Profiling
- **Godot Editor**: Debug → Monitor to watch FPS, memory, draw calls
- **Check**: FPS should be ~60, Memory < 200 MB

---

## ✅ Bug Report Template

```markdown
## Bug Title
[Clear, specific title]

## Reproduction Steps
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Environment
- Godot: 4.6
- Script: [script.gd]
- Frequency: [Always / Sometimes / Random]

## Suspected Cause
[If known]

## Evidence
- Print statements output
- Screenshots/videos
- Error console messages
```

---

## 🎯 When to Use

- Debugging unexpected gameplay behavior
- Investigating performance issues
- Finding memory leaks
- Understanding why signals don't work
- Optimizing slow scripts
