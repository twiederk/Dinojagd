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

- **Phase 3**: Gewehr-Schießen (Leertaste), Bullets mit Damage, T-Rex töten
- **Phase 4**: Brontosaurus + Quad Fahrzeuge
- **Phase 5**: Endlos-Level, Score, Gameworld Expansion

---

# Plan: Phase 3 (Gewehr-Schießen mit Leertaste)

## TL;DR
Spieler kann nach Gewehr-Sammlung mit **Leertaste (Space)** in **Laufrichtung** schießen. Kugeln verursachen 10 HP Schaden und löschen sich automat. beim Bildschirmverlassen.

## Architektur Phase 3

**Neue Szenen:**
```
res://scenes/bullets/Bullet.tscn (CharacterBody2D)
```

## Components Phase 3

### 1. Bullet.tscn + bullet.gd
- CharacterBody2D mit Sprite2D, CollisionShape2D, VisibleOnScreenNotifier2D
- Properties: speed=500, damage=10, direction, lifetime tracking
- Funktionen: _ready() Signal verbinden, _physics_process() Movement, _on_screen_exited() queue_free

### 2. Player.gd erweitern
- Neue Properties: has_gun, gun_cooldown=0.3, gun_cooldown_timer, last_direction
- _input(): Space + has_gun + cooldown OK -> _fire_gun()
- _fire_gun(): Bullet spawn bei Player, direction=last_direction, Parent=Main
- _physics_process: cooldown updaten, last_direction speichern
- _on_item_entered: GUN -> has_gun=true

### 3. T-Rex.gd update
- _on_damage_area_entered erweitern: Bullet erkennen (area.name=="Bullet")
- take_damage(10), area.queue_free()
- Physics Layer: Enemies, Mask: World+Bullets

### 4. Constants.gd
- BULLET_SPEED=500, BULLET_DAMAGE=10, GUN_COOLDOWN=0.3

## Implementierungs-Order
1. Bullet.tscn + bullet.gd
2. Player.gd - has_gun, _fire_gun(), _input
3. T-Rex.gd - Bullet handling
4. Main.tscn - Physics Layer
5. Test

## Verification Phase 3
- [ ] Gun sammeln -> "Gun acquired"
- [ ] Space ohne Gun -> nichts
- [ ] Space mit Gun -> Kugel fliegt
- [ ] Richtung folgt Bewegung
- [ ] Kugel off-screen -> queue_free
- [ ] Treffer T-Rex -> 10 HP Schaden
- [ ] 10 Treffer -> T-Rex tot
- [ ] Cooldown 0.3s funktioniert
- [ ] Keine Memory Leaks

---

# Plan: Phase 4 (Brontosaurus + Quad Fahrzeuge)

## TL;DR
Spieler kann **Brontosaurus reiten** (wenn Gras + Sattel gesammelt) und **Quad fahren** (wenn Quad eingesammelt). Brontosaurus kann T-Rex durch Kollision Schaden zufügen. Quad gibt Speed-Boost. Beide Modi mit **E-Taste** / **Q-Taste** aktivieren/deaktivieren.

## Architektur Phase 4

**Neue Szenen:**
```
res://scenes/vehicles/
├── Brontosaurus.tscn (CharacterBody2D - reitbares Mount)
└── Quad.tscn (Node2D - wird an Player attached)

res://scripts/vehicles/
├── brontosaurus.gd (NPC-Bewegung + Mount-Logik)
└── quad.gd (Speed-Boost Logik)
```

## Gameplay-Konzept

### Brontosaurus (Mount)
- **Voraussetzung**: Player hat Gras UND Sattel im Inventar
- **Aktivierung**: Spieler nähert sich Brontosaurus + drückt **E-Taste**
- **Im Mount-Modus**:
  - Player-Sprite wird versteckt, Brontosaurus-Sprite bewegt sich
  - Bewegungsgeschwindigkeit: 180 (etwas langsamer als Player)
  - Brontosaurus kann T-Rex durch Kollision 25 HP Schaden zufügen
  - Brontosaurus hat eigene HP (150) - kann von T-Rex angegriffen werden
- **Absteigen**: **E-Taste** erneut drücken → Player spawnt neben Brontosaurus

### Quad (Fahrzeug)
- **Voraussetzung**: Player hat Quad im Inventar (einmalig einsammeln)
- **Aktivierung**: **Q-Taste** drücken (Toggle on/off)
- **Im Quad-Modus**:
  - Player-Sprite wechselt zu Quad-Sprite
  - Bewegungsgeschwindigkeit: 400 (doppelt so schnell)
  - Kann NICHT schießen während auf Quad
  - Quad nimmt keinen Schaden von T-Rex (zu schnell)
- **Absteigen**: **Q-Taste** erneut drücken

## Components Phase 4

### 1. constants.gd erweitern
```gdscript
# Brontosaurus Konstanten
const BRONTOSAURUS_SPRITE_PATH = "res://assets/Brontosaurus.png"
const BRONTOSAURUS_HP = 150
const BRONTOSAURUS_MAX_HP = 150
const BRONTOSAURUS_SPEED = 120.0          # Wander-Speed
const BRONTOSAURUS_MOUNT_SPEED = 180.0    # Reiten-Speed
const BRONTOSAURUS_DAMAGE = 25            # Schaden gegen T-Rex
const BRONTOSAURUS_DAMAGE_COOLDOWN = 1.5

# Quad Konstanten
const QUAD_SPRITE_PATH = "res://assets/Quad.png"
const QUAD_SPEED = 400.0                  # Doppelte Player-Speed
```

### 2. Brontosaurus.tscn + brontosaurus.gd

**Szenen-Struktur:**
```
Brontosaurus (CharacterBody2D)
├── Sprite2D (Brontosaurus.png, scale 2x)
├── CollisionShape2D (CapsuleShape größer als Player)
├── InteractionArea (Area2D - für E-Taste Interaktion)
│   └── CollisionShape2D (CircleShape, radius 100)
├── DamageArea (Area2D - für T-Rex Kollision)
│   └── CollisionShape2D (CapsuleShape)
└── HealthBar (wie T-Rex)
```

**Script (brontosaurus.gd):**
```gdscript
# States
enum State { WANDERING, MOUNTED, IDLE }
var current_state: State = State.WANDERING

# Properties
var hp: int = BRONTOSAURUS_HP
var rider: CharacterBody2D = null  # Referenz zum Player
var wander_target: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0

# Funktionen
func _physics_process(delta):
    match current_state:
        State.WANDERING: _wander_movement(delta)
        State.MOUNTED: _mounted_movement(delta)
        State.IDLE: pass

func mount(player: CharacterBody2D):
    rider = player
    current_state = State.MOUNTED
    player.visible = false
    player.set_physics_process(false)

func dismount() -> Vector2:
    var dismount_pos = global_position + Vector2(80, 0)
    rider.visible = true
    rider.set_physics_process(true)
    rider.global_position = dismount_pos
    rider = null
    current_state = State.WANDERING
    return dismount_pos

func _on_damage_area_entered(body):
    if body is T-Rex: body.take_damage(BRONTOSAURUS_DAMAGE)
```

### 3. Player.gd erweitern

**Neue Properties:**
```gdscript
# Mount/Vehicle System
var is_mounted: bool = false
var current_mount: CharacterBody2D = null  # Brontosaurus Referenz
var is_on_quad: bool = false
var has_quad: bool = false
var nearby_brontosaurus: CharacterBody2D = null
```

**Neue Funktionen:**
```gdscript
func _input(event):
    # E-Taste: Mount/Dismount Brontosaurus
    if event.is_action_pressed("interact"):  # E-Taste
        if is_mounted:
            _dismount_brontosaurus()
        elif nearby_brontosaurus and _can_mount():
            _mount_brontosaurus(nearby_brontosaurus)
    
    # Q-Taste: Quad Toggle
    if event.is_action_pressed("toggle_quad"):  # Q-Taste
        if has_quad:
            _toggle_quad()

func _can_mount() -> bool:
    return has_item(ItemType.GRASS) and has_item(ItemType.SADDLE)

func _mount_brontosaurus(bronto: CharacterBody2D):
    is_mounted = true
    current_mount = bronto
    bronto.mount(self)
    # Verbrauche Gras (Sattel bleibt)
    inventory[ItemType.GRASS] -= 1

func _dismount_brontosaurus():
    if current_mount:
        current_mount.dismount()
        is_mounted = false
        current_mount = null

func _toggle_quad():
    is_on_quad = !is_on_quad
    if is_on_quad:
        speed = Constants.QUAD_SPEED
        sprite.texture = load(Constants.QUAD_SPRITE_PATH)
    else:
        speed = Constants.PLAYER_SPEED
        sprite.texture = load(Constants.PLAYER_SPRITE_PATH)

func _on_brontosaurus_nearby(bronto):
    nearby_brontosaurus = bronto
    if _can_mount():
        # UI Hint: "E zum Aufsteigen"

func _on_brontosaurus_left():
    nearby_brontosaurus = null
```

### 4. Input Map erweitern (project.godot)
- `interact` → E-Taste (Brontosaurus mount/dismount)
- `toggle_quad` → Q-Taste (Quad an/aus)

### 5. Main.tscn erweitern
```
Main (Node2D)
├── WorldBackground
├── Player
├── ItemSpawner
├── TRex
├── Brontosaurus (neue Instanz)
└── HUD
```

### 6. HUD.gd erweitern
- Anzeige: "E: Aufsteigen" wenn Brontosaurus in Reichweite + Gras+Sattel vorhanden
- Anzeige: "Q: Quad" wenn Quad im Inventar
- Brontosaurus HP-Bar wenn gemounted

## Implementierungs-Order Phase 4

1. **constants.gd** - Brontosaurus + Quad Konstanten
2. **Input Map** - E und Q Tasten konfigurieren
3. **Brontosaurus.tscn + brontosaurus.gd** - NPC mit Wander-KI
4. **Player.gd** - Mount-System (is_mounted, nearby detection)
5. **Brontosaurus mount()** - Player aufsteigen lassen
6. **Brontosaurus Kampf** - T-Rex Schaden bei Kollision
7. **Quad-System** - Speed-Toggle im Player
8. **HUD Updates** - Interaktions-Hinweise
9. **Main.tscn** - Brontosaurus spawnen
10. **Test & Balance**

## Verification Phase 4

### Brontosaurus Tests
- [ ] Brontosaurus spawnt und wandert zufällig
- [ ] Brontosaurus hat HealthBar (150 HP)
- [ ] Ohne Gras+Sattel: E-Taste zeigt Hinweis "Benötigt Gras und Sattel"
- [ ] Mit Gras+Sattel: E-Taste → Player steigt auf
- [ ] Im Mount: Player-Sprite versteckt
- [ ] Im Mount: Bewegung mit WASD steuert Brontosaurus
- [ ] Im Mount: E-Taste → Absteigen neben Brontosaurus
- [ ] Brontosaurus kollidiert mit T-Rex → 25 HP Schaden
- [ ] Brontosaurus kann sterben (HP = 0)
- [ ] Nach Brontosaurus-Tod: Player automatisch abgeworfen

### Quad Tests
- [ ] Quad einsammeln → "Quad acquired"
- [ ] Q ohne Quad → nichts
- [ ] Q mit Quad → Sprite wechselt zu Quad
- [ ] Auf Quad: Speed = 400 (merklich schneller)
- [ ] Auf Quad: Space zum Schießen deaktiviert
- [ ] Q erneut → zurück zu Player-Sprite + normale Speed
- [ ] Quad bleibt im Inventar (unbegrenzt nutzbar)

### Integrations-Tests
- [ ] Kann nicht auf Quad UND Brontosaurus gleichzeitig
- [ ] Quad-Modus deaktiviert "E zum Aufsteigen"
- [ ] T-Rex ignoriert Quad-Spieler (optional: zu schnell)
- [ ] HUD zeigt korrekten Status

## Decisions Phase 4

- **E-Taste für Mount**: Konsistent mit anderen Spielen (Interaktion)
- **Q-Taste für Quad**: Separater Keybind, da Fahrzeug-Toggle häufig
- **Gras wird verbraucht**: Balancing - Mount ist mächtig, kostet Resource
- **Sattel bleibt**: Einmal gefunden, immer nutzbar
- **Quad = Immunität gegen T-Rex**: Reward für Item-Findung
- **Brontosaurus wandert**: Macht Welt lebendiger, Player muss ihn finden
- **Brontosaurus kann sterben**: Strategische Komponente

## Assets Phase 4

- **Brontosaurus.png** ✓ vorhanden in `assets/`
- **Quad.png** ✓ vorhanden in `assets/`
- Sprite-Skalierung: 2x wie andere Entities

---

## Roadmap nach Phase 4

- **Phase 5**: Endlos-Level, Score-System, mehr T-Rex Spawns, Difficulty Scaling

