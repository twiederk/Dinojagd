# Claude Code Customization Files

This directory contains Claude Code configurations for the **Dinojagd** project.

## 📁 Structure

```
.claude/
├── settings.json              # Global Claude Code settings
├── settings.local.json        # Local overrides (not versioned)
├── skills/
│   ├── godot-conventions/     # GDScript & Godot best practices
│   │   └── SKILL.md
│   ├── enemy-design/          # Enemy AI & balance design
│   │   └── SKILL.md
│   └── game-systems/          # Core game architecture
│       └── SKILL.md
├── agents/
│   ├── code-review.md         # Code quality reviewer
│   └── bug-hunter.md          # Debugging & performance analyzer
└── commands/
    └── test-enemy.md          # Test new enemy functionality
```

## 🚀 Quick Start

### 1. Enable in VS Code
These configurations are **automatically discovered** by Claude Code. No setup needed!

### 2. Use Skills (Type `/` in chat)
```
/godot-conventions   → Understand GDScript patterns
/enemy-design        → Design & balance enemies
/game-systems        → Work on game architecture
```

### 3. Invoke Agents (In chat)
```
@code-review-agent Review this script
@bug-hunter-agent   Why is the T-Rex lagging?
```

### 4. Run Commands (In chat)
```
/test-enemy Goblin   → Validate new enemy
```

---

## 📚 Skills Overview

| Skill | Purpose | Use When |
|-------|---------|----------|
| **godot-conventions** | GDScript style guide & patterns | Writing new scripts, code review |
| **enemy-design** | Enemy AI, balance, behavior design | Adding enemies, tweaking difficulty |
| **game-systems** | Game loop, inventory, combat | Working on core mechanics |

---

## 🤖 Agents Overview

| Agent | Purpose | Invoke With |
|-------|---------|------------|
| **code-review** | Check script quality & conventions | `@code-review-agent Review X` |
| **bug-hunter** | Debug issues & find bottlenecks | `@bug-hunter-agent Why does X happen?` |

---

## ⌨️ Commands Overview

| Command | Purpose |
|---------|---------|
| **test-enemy** | Validate & test new enemy script |

---

## 🔧 Customization

### To modify settings:
Edit `settings.json` for project-wide behavior:
- Language: GDScript
- Engine: Godot 4.6
- Style guide: Dinojagd conventions

### To modify local settings:
Create `settings.local.json` (not versioned) for personal preferences.

### To add new skills:
Create a folder in `skills/`:
```
skills/my-new-skill/
  └── SKILL.md
```

---

## 📖 Learning More

- **GDScript Guide**: See `godot-conventions/SKILL.md`
- **Enemy System**: See `enemy-design/SKILL.md`
- **Game Architecture**: See `game-systems/SKILL.md`

---

## ❓ Troubleshooting

**Skills not showing up?**
- Ensure you're in the correct workspace folder
- Skills are loaded automatically

**Agents not responding?**
- Use `@agent-name` with the exact agent name
- Check VS Code Extensions: Copilot Chat should be enabled

**Commands not working?**
- Type `/` to see available commands
- Verify command file is in `.claude/commands/`

---

## 📝 Notes

- This folder is **project-scoped** — customizations only apply to Dinojagd
- Add `.claude/settings.local.json` to `.gitignore` for personal settings
- Skills can be version-controlled and shared with team

---

**Happy coding! 🎮**

