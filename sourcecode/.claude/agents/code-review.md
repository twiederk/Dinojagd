---
name: code-review-agent
description: "Use when: performing code reviews, checking GDScript quality, validating against Dinojagd conventions, or assessing performance implications of scripts."
---

# Code Review Agent for Dinojagd

## When to Invoke

```
@Claude "Please review this enemy script"
@Claude "Check if this follows Dinojagd conventions"
```

---

## 🔍 Code Quality Checklist

### Structure
- [ ] Class structure follows standard pattern (imports → state → signals → lifecycle)
- [ ] All functions have type hints (`: Type` for variables, `-> ReturnType` for methods)
- [ ] `@onready` used for node references
- [ ] `preload()` used instead of `load()` for scenes/scripts

### Conventions
- [ ] Snake_case for functions and variables
- [ ] PascalCase for class names
- [ ] Proper use of Constants (no magic numbers)
- [ ] Signal handlers follow `_on_*` naming
- [ ] Comments explain **why**, not what

### Performance
- [ ] No heavy logic in `_process()`
- [ ] No `get_tree().root.find_child()` in loops
- [ ] Proper grouping (`add_to_group()` for bulk operations)
- [ ] Caching of node references in `_ready()`

### Game-Specific
- [ ] Damage cooldown implemented (prevents instant-kill)
- [ ] Proper collision detection
- [ ] Signals emitted for state changes
- [ ] Health checks before operations

---

## Review Template

```markdown
## ✅ Good Points
- [Point 1]
-[Point 2]

## ⚠️ Issues Found
1. **Issue**: Description
   **Fix**: Recommendation

2. **Issue**: Description
   **Fix**: Recommendation

## 🎯 Suggestions
- Suggestion 1
- Suggestion 2

## 📊 Performance Impact
- Estimated FPS impact: None / Low / Medium / High
- Memory concerns: None / Minor / Significant

## ✨ Overall Rating
**[⭐⭐⭐⭐⭐] Excellent / [⭐⭐⭐⭐] Good / [⭐⭐⭐] Fair / [⭐⭐] Needs Work**
```

---

## 🔬 Common Issues & Fixes

| Issue | Detection | Fix |
|-------|-----------|-----|
| Missing type hint | `var speed = 200` | Add `: float` |
| Magic number | `hp -= 10` | Use `Constants.DAMAGE_VALUE` |
| Slow find | `get_tree().root.find_child()` | Cache in `_ready()` |
| Frame drops | Heavy logic in `_process()` | Move to `_physics_process()` or use timers |
| Memory leak | Unconnected signals | Disconnect in `queue_free()` |

---

## 🎯 Performance Targets

For Dinojagd (2D game):
- **Target FPS**: 60 FPS on mid-range PC
- **Memory**: < 150 MB RAM
- **Frame time**: < 16.67ms

