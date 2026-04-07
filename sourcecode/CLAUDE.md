# Dinojagd - Claude Code Optimierung

## 🎮 Projektübersicht

**Dinojagd** ist ein 2D Action-Adventure Spiel in Godot 4.6, bei dem der Spieler:
- Gegenstände sammelt (Gewehr, Gras, Sattel, Quad)
- Gegen einen T-Rex kämpft
- Ein Brontosaurus reiten und ein Quad fahren kann
- In einer offenen Welt überlebt

**Spielzustand**: Early Development (v1.3.0)
- ✅ Basis-Spieler & Bewegung
- ✅ T-Rex KI & Kampfsystem
- ✅ Item-Sammlung & Inventar
- ✅ Brontosaurus & Quad Fahrzeuge
- 🔄 Animation & Sound (In Progress)

---

## 📁 Projektstruktur

```
scripts/
  ├── constants.gd          # Zentrale Konstanten (Speed, HP, Damage)
  ├── main.gd               # Main Game Loop
  ├── player.gd             # Player Logik
  ├── bullet.gd             # Schuss-Logik
  ├── item.gd               # Item System
  ├── item_spawner.gd       # Item Spawning
  ├── hud.gd                # UI System
  ├── enemies/
  │   └── t_rex.gd          # T-Rex KI & Verhalten
  └── vehicles/
      ├── brontosaurus.gd   # Brontosaurus Fahrzeug
      └── lore.gd           # Lore (Quad) Fahrzeug

scenes/
  ├── main/
  │   └── Main.tscn         # Hauptszene
  ├── player/
  │   └── Player.tscn       # Player Node-Struktur
  ├── enemies/
  │   └── TRex.tscn         # T-Rex Node-Struktur
  ├── vehicles/
  │   ├── Brontosaurus.tscn # Brontosaurus Node
  │   └── Lore.tscn         # Quad/Lore Node
  ├── items/
  │   └── Item.tscn         # Item Pickup Node
  ├── bullets/
  │   └── Bullet.tscn       # Bullet Node
  └── ui/
      ├── HUD.tscn          # HUD Layout
      └── HealthBar.tscn    # HealthBar Widget

assets/
  ├── *.png                 # Grafiken (Sprites)
  ├── *.aseprite            # Aseprite Dateien
  └── IslandTileset.tres    # Tilemap Data
```

---

## 🛠️ Tech Stack

| Technologie | Version  | Usage |
|-------------|----------|-------|
| Godot       | 4.6      | Game Engine |
| GDScript    | 4.x      | Scripting Language |
| Aseprite    | -        | Sprite Creation |

---

## 🎯 Zentrale Systeme

### 1. **Konstanten System** (`constants.gd`)
Alle Game-Balance Werte sind zentralisiert (Speed, HP, Damage). Einfache Anpassungen ohne Script-Änderungen.

### 2. **Player System** (`player.gd`)
- Bewegung: WASD + Diagonale
- Waffen: Gewehr freischalten via Item
- Inventar: Dictionary-basiert
- Fahrzeuge: Brontosaurus (Mount) & Quad (Vehicle)

### 3. **Enemy KI** (`enemies/t_rex.gd`)
- States: PATROL → CHASE → RETURN
- Damage-Cooldown: Verhindert instant-kill
- Zielpriorität: Player > Brontosaurus > Lore

### 4. **Item System** (`item_spawner.gd`, `item.gd`)
- Spawning: Timer-basiert
- Pickup: Via Area2D Collision
- Inventar: Dictionary mit Item-Typen

### 5. **Fahrzeuge** (`vehicles/brontosaurus.gd`, `vehicles/lore.gd`)
- Brontosaurus: Mount (benötigt Gras + Sattel)
- Lore: Quad-Fahrzeug (schnell)

### 6. **Combat** (`bullet.gd`, `player.gd`)
- Bullets: Area2D Projectiles
- Damage Tracking: Via Signal `health_changed`
- Death System: GameOver bei HP ≤ 0

---

## 📊 Wichtige Signale

| Signal | Quelle | Listener |
|--------|--------|----------|
| `health_changed(hp, max_hp)` | Player/TRex | HUD |
| `enemy_died` | TRex | Main |
| `item_collected(type)` | Item | Player/HUD |

---

## ⚡ Häufige Entwicklungs-Aufgaben

- **Neue Enemy hinzufügen**: `enemies/` Ordner + KI-Script
- **Neue Items**: ItemType in `constants.gd` + Sprite
- **Balance-Änderungen**: `constants.gd` anpassen
- **Animation**: `AnimatedSprite2D` in Scenes erweitern
- **Sound**: SFX in `HUD.gd` oder Gegner-Scripts triggerbar

---

## 🔗 Claude Code Skills & Agents

Siehe `.claude/skills/` und `.claude/agents/` für spezialisierte Workflows:
- **godot-conventions**: GDScript & Godot Best Practices
- **enemy-design**: Enemy KI & Balance
- **game-systems**: Game Loop & Mechanics
- **code-review**: Quality Assurance
- **bug-hunter**: Performance & Debugging
