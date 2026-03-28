# Plan: Dinojagd - Phase 1 (Player + Item Collection)

## TL;DR
Implementierung der Grundmechaniken: Spieler mit 2D-Bewegung (WASD / Pfeiltasten), Item-Sammlung durch einfaches berühren, Gegenstände (Gewehr, Gras, Sattel, Quad) in der offenen Spielwelt. Nach dieser Phase können wir T-Rex-KI und Kampf hinzufügen.

## Architektur-Grundlagen (Godot 4.x)

**Szenen-Struktur:**
```
res://scenes/
├── main/
│   └── Main.tscn (Node2D)
├── player/
│   └── Player.tscn (CharacterBody2D)
├── items/
│   ├── Item.tscn (Area2D - Base für alle Items)
│   ├── Gun.tscn (Instanz von Item)
│   ├── Grass.tscn (Instanz von Item)
│   ├── Saddle.tscn (Instanz von Item)
│   └── Quad.tscn (Instanz von Item)
└── ui/
    └── HUD.tscn (CanvasLayer)

res://scripts/
├── player.gd
├── item.gd
├── item_spawner.gd
├── hud.gd
└── constants.gd (ItemType Enum, Konstanten)
```

## Steps

### 1. Projektstruktur Setup
- Verzeichnisse erstellen: `res://scenes/{main,player,items,ui}/` und `res://scripts/`
- `constants.gd` erstellen mit:
  - `enum ItemType { GUN, GRASS, SADDLE, QUAD }`
  - Item-Eigenschaften (Sprite-Pfade, Sammél-Radius)
- Assets sind bereits vorhanden in `assets/`:
  - `Spieler.png` (Spieler-Grafik)
  - `Gwer.png` (Gewehr)
  - `Gras.png` (Gras)
  - `Sattel.png` (Sattel)
  - `Quad.png` (Quad)
- Sprites in constants.gd referenzieren: `res://assets/Spieler.png`, etc.

### 2. Player-Szene (Player.tscn + player.gd)
**Struktur:**
```
Player (CharacterBody2D)
├── AnimatedSprite2D (Spieler.png)
├── CollisionShape2D (CapsuleShape)
├── DetectionArea (Area2D für Item-Sammlung)
│   └── CollisionShape2D (CircleShape, radius ~50)
└── Camera2D (folgt Player)
```

**Script (player.gd):**
- Eigenschaften: `speed = 200`, `velocity`, `inventory = {}` (Dict mit ItemType: count)
- `_physics_process()`: WASD-Input → velocity.x/y, velocity normalisieren wenn > (200, 200), `move_and_slide()`
- `_input_event()`: E-Taste → `_collect_nearby_items()` (Area2D.get_overlapping_areas suchen)
- Signal `item_collected(item_type, count)` → HUD aktualisieren
- Inventar-Getter: `has_item(item_type: ItemType) -> bool`

### 3. Item-System (Item.tscn + item.gd)
**Struktur:**
```
Item (Area2D)
├── Sprite2D (wird dynamisch gesetzt)
└── CollisionShape2D (CircleShape2D)
```

**Script (item.gd):**
- Export-Variable: `@export var item_type: ItemType`
- `_ready()`: Sprite aus constants.gd laden basierend auf item_type (Pfade: `res://assets/Gwer.png`, `res://assets/Gras.png`, `res://assets/Sattel.png`, `res://assets/Quad.png`)
- Optional: langsam rotieren/bobben für visuellen Effect
- Signal `collected` (item_type, position) → Spawner kann reagieren (z.B. Timer reset)

### 4. Haupt-Szene (Main.tscn + main.gd)
**Struktur:**
```
Main (Node2D)
├── ColorRect (Hintergrund Grün/Braun)
├── Player (instanziert aus Player.tscn)
├── ItemSpawner (Node2D → script item_spawner.gd)
├── Viewport (optional für Kamera-Setup)
└── HUD (CanvasLayer)
    └── InventoryUI (Control)
```

**Script (main.gd):**
- `_ready()`: Verbinde Player.item_collected → `_on_player_collected()`
- `_on_player_collected(item_type, count)`: HUD.update_inventory() aufrufen

**Script (item_spawner.gd):**
- Eigenschaften: `item_scenes: Dictionary` (ItemType → .tscn Pfad), `spawn_count = 5` pro Typ, `spawn_radius = 400` (um Player)
- `_ready()`: Alle Items initial spawnen mit `spawn_random_items()`
- Timer > 30 Sekunden: Fehlende Items nachspawnen
- `spawn_random_items()`: 
  - Zufallspositionen in `spawn_radius` erzeugen
  - Item-Szene instanzieren, Position setzen, zu Main hinzufügen
  - Item.collected Signal → neues Item spawnen

### 5. UI-System (HUD.tscn + hud.gd)
**Struktur:**
```
HUD (CanvasLayer)
└── PanelContainer (oben links)
    └── VBoxContainer
        ├── Label ("Inventar:") 
        └── HBoxContainer
            ├── Gun_Icon + Label (0)
            ├── Grass_Icon + Label (0)
            ├── Saddle_Icon + Label (0)
            └── Quad_Icon + Label (0)
```

**Script (hud.gd):**
- `update_inventory(inventory: Dictionary)`: Labels aktualisieren mit Item-Counts
- Optional: TextureRect für Icons aus assets/

### 6. Eingabe & Steuerung
- Input Map (Project Settings):
  - `ui_move_up` → W + Oben-Pfeil ↑
  - `ui_move_down` → S + Unten-Pfeil ↓
  - `ui_move_left` → A + Links-Pfeil ←
  - `ui_move_right` → D + Rechts-Pfeil →

## Implementorder (Empfehlungen)

1. **constants.gd** - schnell, foundation
2. **Player.tscn + player.gd** - Bewegung testen
3. **Item.tscn + item.gd** - eine Item-Instanz manual spawnen, testen
4. **Main.tscn + main.gd** - Szene aufbauen, Player als Child
5. **item_spawner.gd** - Items automatisch spawnen
6. **HUD.tscn + hud.gd** - UI verbinden, Inventar anzeigen

## Verification (Testplan)

- [ ] F5 starten → Player in Mitte des Bildschirms
- [ ] WASD → Player bewegt sich in alle Richtungen
- [ ] ~50px Sammel-Radius sichtbar (Debug-Draw bei E-Eingabe)
- [ ] E-Taste → Item im Radius wird eingesammelt und verschwindet
- [ ] HUD zeigt korrekte Zahl (z.B. Gun: 1, Grass: 2)
- [ ] Items respawnen nach ~30 Sekunden wenn gesammelt
- [ ] Mehrere Items gleichzeitig sichtbar (mind. 5 verschiedene)
- [ ] Kamera folgt Player aus der Nähe (nicht ruckelig)

## Decisions

- **Godot 4.x Features**: CharacterBody2D statt KinematicBody2D (3.x), `@export` statt `export()`
- **Phasierung**: Sammeln vor Kämpfen, weil Grundmechanik stabiler machen

## Nächster Schritt nach Phase 1

Sobald Player + Items läuft:
- **Phase 2**: T-Rex-KI (ChaseState mit Area2D detection, HealthBar)
- **Phase 3**: Gewehr-Schießen (Mouse-Input, Bullet prefab mit Damage)
- **Phase 4**: Brontosaurus (reiten wenn Grass + Saddle), Quad (fahren für Speed)

---

# Plan: Dinojagd - Phase 2 (T-Rex KI + HealthBar)

## TL;DR
Implementierung des Gegners: T-Rex mit Chase-KI (folgt Player wenn in Reichweite), HealthBar (grüne Lebensbalken), Collision-Schaden auf Player. T-Rex patrouilliert zufällig wenn Player nicht sichtbar, greift an wenn Player erkannt.

## Phase 2 Architektur

**Neue Szenen:**
```
res://scenes/enemies/
├── Enemy.tscn (CharacterBody2D - Base für Gegner)
├── TRex.tscn (Instanz von Enemy)
└── HealthBar.tscn (CanvasLayer - UI über Gegner)

res://scripts/enemies/
├── t_rex.gd (Gegner-Controller)
├── t_rex_ai.gd (Chase + Patrol KI)
└── healthbar.gd (UI Balken)
```

## Steps Phase 2

### 1. Erweitere constants.gd
- `enum EnemyType { T_REX }`
- T-Rex Sprite-Pfad: `res://assets/T-Rex.png`
- T-Rex Stats: `HP = 100`, `DAMAGE = 15`, `SPEED = 150`, `DETECTION_RADIUS = 300`
- Damage-Typen: `COLLISION`, `BULLET` (für Phase 3)

### 2. Enemy-System (T-Rex)

**Struktur: TRex.tscn**
```
TRex (CharacterBody2D)
├── Sprite2D (T-Rex.png)
├── CollisionShape2D (CapsuleShape)
├── DetectionArea (Area2D)
│   └── CollisionShape2D (CircleShape, radius 300)
├── DamageArea (Area2D für Collision mit Player)
│   └── CollisionShape2D (CircleShape, radius 30)
└── HealthBar (CanvasLayer als Child)
    └── Panel (mit grünem + rotem Balken)
```

**Script (t_rex.gd):**
- Properties: `hp = 100`, `max_hp = 100`, `damage = 15`, `speed = 150`
- `_ready()`: Sprite laden, Detection-Signale verbinden, HealthBar initialisieren
- `_physics_process()`: Bewegung via AI, move_and_slide()
- `take_damage(amount: int)`: HP reduzieren, HealthBar update, bei 0 HP sterben
- `_on_player_entered()` / `_on_player_exited()`: Detection
- Signal: `health_changed(hp, max_hp)` → HealthBar abonniert

**Script (t_rex_ai.gd):**
- Mode: `PATROL`, `CHASE`, `IDLE`
- `_process_ai()`: 
  - PATROL: zufällige Ziele ansteuern, um Player bewegen
  - CHASE: Player direktional ansteuern (einfache Path-Finding)
  - IDLE: Warten bis Detection
- `set_target(target_pos: Vector2)`: Richtung zum Ziel berechnen
- Geschwindigkeit: 150 im Patrol, 180 im Chase

### 3. HealthBar-System

**Struktur: HealthBar.tscn**
```
HealthBar (CanvasLayer)
└── Control
    ├── ColorRect (background - dunkelgrau)
    ├── ColorRect (green - HP)
    └── Label (optional - HP Nummer)
```

**Script (healthbar.gd):**
- `update_health(current_hp: int, max_hp: int)`: Green-Bar Breite setzen
- Positution: über T-Rex Kopf (Offset +20px Y)
- Größe: 60px breit x 8px hoch
- `_process()`: Folge T-Rex Position (relative zu Kamera)

### 4. Schadens-System

**Collision mit Player:**
- Wenn Player und T-Rex-DamageArea kollidieren → Player.take_damage(15)
- T-Rex kümmert sich nicht um Schaden von Player (noch, bis Phase 3)
- Cooldown: 1 Sekunde zwischen Damage-Ticks

**Integrationspunkte:**
- DamageArea Signal `area_entered` mit Player verbinden
- Player braucht `take_damage(amount: int)` Funktion
- Player HealthBar (später in Phase 3 + Phase 4)

### 5. Integration in Main

**main.gd erweitern:**
- T-Rex als Child spawnen
- Signals verbinden: Player ↔ T-Rex
- Optional: T-Rex Respawn bei Spieler-Tod

**Main.tscn:**
```
Main (Node2D)
├── WorldBackground
├── Player
├── ItemSpawner
├── TRex (neue instanzierte Szene)
└── HUD
```

## Implementorder Phase 2

1. **constants.gd erweitern** - T-Rex Stats + Enum
2. **HealthBar.tscn + healthbar.gd** - unabhängig testbar
3. **Enemy.tscn Basis-Setup** - Struktur + Collision
4. **t_rex.gd** - Health + Damage-Logik
5. **t_rex_ai.gd** - Chase + Patrol KI
6. **Player.tscn erweitern** - `take_damage()` Funktion + HealthBar
7. **Main.tscn + main.gd** - T-Rex einbinden + Signals
8. **Test + Balance** - HP, Speed, Damage abgleichen

## Verification Phase 2

- [ ] F5 starten → T-Rex sichtbar auf Wiese
- [ ] Player nah → T-Rex DetectionArea auslösen (Debug-Log)
- [ ] T-Rex folgt Player wenn in 300px Reichweite
- [ ] Player berührt T-Rex → Player nimmt Schaden (15 HP)
- [ ] HealthBar über T-Rex zeigt HP (grüner Balken)
- [ ] T-Rex HealthBar folgt mit Kamera
- [ ] Player stirbt bei 0 HP → Game Over
- [ ] T-Rex patrouilliert zufällig wenn Player weit weg
- [ ] Mehrere Chase-Zyklen ohne Fehler

## Decisions Phase 2

- **SimpleAI statt komplexe Pathfinding**: Detection + direktes Ansteuern reicht für Gameplay
- **HealthBar als CanvasLayer-Child**: Folgt automatisch mit Kamera
- **1s Damage-Cooldown**: Verhindert zu schnellen Overkill
- **T-Rex stirbt nicht in Phase 2**: Wird in Phase 3 mit Gewehr-Bullets möglich

## Assets verwenden

- **T-Rex.png** liegt bereits in `assets/` vor
- Sprite-Skalierung: 2x wie Player/Items

---

## Roadmap nach Phase 2

- **Phase 3**: Gewehr-Schießen (Maus-Klick), Bullets mit Damage, T-Rex töten
- **Phase 4**: Brontosaurus + Quad Fahrzeuge
- **Phase 5**: Endlos-Level, Score, Gameworld Expansion
