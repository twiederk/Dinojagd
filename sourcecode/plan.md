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
