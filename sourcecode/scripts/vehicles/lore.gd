class_name Lore
extends CharacterBody2D


# Schienen Tile Atlas-Koordinaten (x, y)
const RAIL_TILES_HORIZONTAL = [Vector2i(20, 0), Vector2i(20, 2)]
const RAIL_TILES_VERTICAL = [Vector2i(19, 1), Vector2i(21, 1)]
const RAIL_TILES_CURVES = [Vector2i(19, 0), Vector2i(21, 0), Vector2i(19, 2), Vector2i(21, 2)]

# Lore Konstanten
const LORE_SPRITE_HORIZONTAL = "res://assets/Lore_horizontal.png"
const LORE_SPRITE_VERTICAL = "res://assets/Lore_vertical.png"
const LORE_SPEED = 150.0
const LORE_RETURN_SPEED = 200.0  # Schneller zurückfahren

# States
enum State { IDLE, WAITING_FOR_DIRECTION, MOVING, RETURNING }
var current_state: State = State.IDLE

# Rider
var rider: CharacterBody2D = null

# Position & Movement
var start_position: Vector2 = Vector2.ZERO
var current_direction: Vector2 = Vector2.ZERO
var tile_map: TileMapLayer = null
var last_curve_tile: Vector2i = Vector2i(-999, -999)  # Letzte verarbeitete Kurve
var last_debug_tile: Vector2i = Vector2i(-999, -999)  # Für Debug-Ausgabe

# References
@onready var sprite = $Sprite2D
@onready var interaction_area = $InteractionArea
@onready var collision_shape = $CollisionShape2D
@onready var camera = $Camera2D

# Signals
signal player_nearby(lore: CharacterBody2D)
signal player_left


func _ready() -> void:
	add_to_group("vehicles")
	add_to_group("lore")
	
	start_position = global_position
	
	# Sprite laden (Standard: horizontal)
	if sprite:
		sprite.texture = load(LORE_SPRITE_HORIZONTAL)
	
	# Signals verbinden
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)
	
	# TileMapLayer finden
	await get_tree().process_frame
	_find_tilemap()
	
	# Initiale Sprite-Richtung basierend auf Schiene
	_update_sprite_for_current_tile()
	
	print("🚃 Lore erschienen bei %s" % global_position)


func _find_tilemap() -> void:
	var main = get_tree().root.find_child("Main", true, false)
	if main:
		tile_map = main.find_child("SchienenEbene", true, false)
		print("🚃 SchienenEbene gefunden!")
		print("⚠️ SchienenEbene nicht gefunden!")


func _physics_process(_delta: float) -> void:
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.WAITING_FOR_DIRECTION:
			_handle_direction_input()
		State.MOVING:
			_move_on_rails(LORE_SPEED)
		State.RETURNING:
			_return_to_start()
	
	if current_state in [State.MOVING, State.RETURNING]:
		move_and_slide()
		
		# Rider Position aktualisieren
		if rider:
			rider.global_position = global_position


func _handle_direction_input() -> void:
	var input_dir = Vector2.ZERO
	
	if Input.is_action_just_pressed("ui_move_up"):
		input_dir = Vector2.UP
	elif Input.is_action_just_pressed("ui_move_down"):
		input_dir = Vector2.DOWN
	elif Input.is_action_just_pressed("ui_move_left"):
		input_dir = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_move_right"):
		input_dir = Vector2.RIGHT
	
	if input_dir != Vector2.ZERO:
		# Prüfe ob die Richtung auf Schienen führt
		if _can_move_in_direction(input_dir):
			current_direction = input_dir
			current_state = State.MOVING
			_update_sprite_direction()
			print("🚃 Lore fährt los in Richtung: %s" % current_direction)
		else:
			print("⚠️ Keine Schienen in dieser Richtung!")


func _move_on_rails(speed: float) -> void:
	if not tile_map:
		velocity = Vector2.ZERO
		return
	
	# Aktuelles Tile prüfen
	var current_tile = _get_tile_at_position(global_position)
	var current_tile_data = tile_map.get_cell_atlas_coords(current_tile)
	
	# Debug: Zeige Tile-Info nur bei neuer Tile
	if current_tile != last_debug_tile:
		print("🚃 Tile: %s, Atlas: %s, IsRail: %s, IsCurve: %s, Dir: %s" % [current_tile, current_tile_data, _is_rail_tile(current_tile_data), _is_curve_tile(current_tile_data), current_direction])
		last_debug_tile = current_tile
	
	# Prüfe ob wir AKTUELL auf einer gültigen Schiene sind
	if not _is_rail_tile(current_tile_data):
		# Wir sind auf keiner Schiene mehr - Ende erreicht
		print("🚃 Keine Schiene unter der Lore! Atlas: %s" % current_tile_data)
		_end_of_rails()
		return
	
	# WICHTIG: Kurven-Behandlung ZUERST, bevor das nächste Tile geprüft wird!
	if _is_curve_tile(current_tile_data) and current_tile != last_curve_tile:
		# Kurve gefunden, die noch nicht verarbeitet wurde
		var old_direction = current_direction
		_handle_curve(current_tile_data, current_tile)
		last_curve_tile = current_tile
		
		if old_direction != current_direction:
			# Richtung hat sich geändert - Sprite aktualisieren
			_update_sprite_direction()
			# Lore zur Mittitte der Tile snappen nach Richtungswechsel
			_snap_to_tile_center(current_tile)
			print("🚃 Kurve verarbeitet! Neue Richtung: %s" % current_direction)
	
	# JETZT prüfen wir das nächste Tile in der (möglicherweise neuen) Richtung
	var next_frame_pos = global_position + current_direction * speed * get_physics_process_delta_time()
	var next_tile = _get_tile_at_position(next_frame_pos)
	
	# Nur prüfen wenn wir tatsächlich zu einer neuen Tile wechseln würden
	if next_tile != current_tile:
		var next_tile_data = tile_map.get_cell_atlas_coords(next_tile)
		
		# Prüfe ob das nächste Tile eine gültige Schiene ist
		if not _is_rail_tile(next_tile_data):
			# Nächstes Tile ist keine Schiene - Ende erreicht
			print("🚃 Nächstes Tile (%s) ist keine Schiene! Atlas: %s" % [next_tile, next_tile_data])
			_end_of_rails()
			return
	
	# Bewegung fortsetzen
	velocity = current_direction * speed


func _handle_tile_transition(next_tile: Vector2i) -> void:
	if not tile_map:
		return
	
	var tile_data = tile_map.get_cell_atlas_coords(next_tile)
	
	# Prüfe ob die nächste Tile eine Schiene ist
	if not _is_rail_tile(tile_data):
		# Ende der Schienen erreicht
		_end_of_rails()
		return
	
	# Prüfe ob es eine Kurve ist und passe Richtung an
	if _is_curve_tile(tile_data):
		_handle_curve(tile_data, next_tile)
	
	_update_sprite_direction()


func _handle_curve(tile_data: Vector2i, tile_pos: Vector2i) -> void:
	# Kurven-Mapping basierend auf Atlas-Koordinaten:
	# (19,0) = Kurve von unten nach rechts (verbindet Süden mit Osten)
	# (21,0) = Kurve von links nach unten (verbindet Westen mit Süden)
	# (19,2) = Kurve von oben nach rechts (verbindet Norden mit Osten)
	# (21,2) = Kurve von links nach oben (verbindet Westen mit Norden)
	
	var new_direction = current_direction
	
	match tile_data:
		Vector2i(19, 0):  # Kurve von unten nach rechts
			if current_direction == Vector2.UP:  # Kommt von unten
				new_direction = Vector2.RIGHT
			elif current_direction == Vector2.LEFT:  # Kommt von rechts
				new_direction = Vector2.DOWN
		Vector2i(21, 0):  # Kurve von links nach unten
			if current_direction == Vector2.RIGHT:  # Kommt von links
				new_direction = Vector2.DOWN
			elif current_direction == Vector2.UP:  # Kommt von unten
				new_direction = Vector2.LEFT
		Vector2i(19, 2):  # Kurve von oben nach rechts
			if current_direction == Vector2.DOWN:  # Kommt von oben
				new_direction = Vector2.RIGHT
			elif current_direction == Vector2.LEFT:  # Kommt von rechts
				new_direction = Vector2.UP
		Vector2i(21, 2):  # Kurve von links nach oben
			if current_direction == Vector2.RIGHT:  # Kommt von links
				new_direction = Vector2.UP
			elif current_direction == Vector2.DOWN:  # Kommt von oben
				new_direction = Vector2.LEFT
	
	if new_direction != current_direction:
		current_direction = new_direction
		print("🚃 Kurve! Neue Richtung: %s" % current_direction)


func _end_of_rails() -> void:
	velocity = Vector2.ZERO
	last_curve_tile = Vector2i(-999, -999)  # Reset für Rückfahrt
	last_debug_tile = Vector2i(-999, -999)  # Reset Debug
	
	if rider:
		print("🚃 Ende der Schienen erreicht! Spieler steigt aus.")
		dismount()
	
	# Lore fährt zurück zum Start
	current_state = State.RETURNING
	print("🚃 Lore fährt zurück zum Startpunkt...")


func _return_to_start() -> void:
	var distance = global_position.distance_to(start_position)
	
	if distance < 5.0:
		# Am Start angekommen
		global_position = start_position
		current_state = State.IDLE
		velocity = Vector2.ZERO
		_update_sprite_for_current_tile()
		print("🚃 Lore ist zurück am Start!")
		return
	
	# Richtung zum Start berechnen und auf Schienen fahren
	var dir_to_start = (start_position - global_position).normalized()
	
	# Bestimme die Hauptrichtung (horizontal oder vertikal)
	if abs(dir_to_start.x) > abs(dir_to_start.y):
		current_direction = Vector2.RIGHT if dir_to_start.x > 0 else Vector2.LEFT
	else:
		current_direction = Vector2.DOWN if dir_to_start.y > 0 else Vector2.UP
	
	_update_sprite_direction()
	_move_on_rails(LORE_RETURN_SPEED)


func _can_move_in_direction(direction: Vector2) -> bool:
	if not tile_map:
		return false
	
	var check_pos = global_position + direction * 32  # Eine Tile weiter
	var tile_coords = _get_tile_at_position(check_pos)
	var tile_data = tile_map.get_cell_atlas_coords(tile_coords)
	
	return _is_rail_tile(tile_data)


func _get_tile_at_position(pos: Vector2) -> Vector2i:
	if not tile_map:
		return Vector2i(-1, -1)
	return tile_map.local_to_map(tile_map.to_local(pos))


func _is_rail_tile(atlas_coords: Vector2i) -> bool:
	if atlas_coords == Vector2i(-1, -1):
		return false
	
	# Alle Schienen-Tiles prüfen
	for tile in RAIL_TILES_HORIZONTAL:
		if atlas_coords == tile:
			return true
	for tile in RAIL_TILES_VERTICAL:
		if atlas_coords == tile:
			return true
	for tile in RAIL_TILES_CURVES:
		if atlas_coords == tile:
			return true
	
	return false


func _is_curve_tile(atlas_coords: Vector2i) -> bool:
	for tile in RAIL_TILES_CURVES:
		if atlas_coords == tile:
			return true
	return false


func _is_horizontal_direction() -> bool:
	return current_direction == Vector2.LEFT or current_direction == Vector2.RIGHT


func _snap_to_tile_center(tile_coords: Vector2i) -> void:
	if not tile_map:
		return
	
	# Mittitte der Tile berechnen
	var tile_center = tile_map.map_to_local(tile_coords)
	
	# Nur senkrecht zur Fahrtrichtung ausrichten
	if _is_horizontal_direction():
		# Horizontal fahren: nur Y-Koordinate korrigieren
		global_position.y = tile_center.y
	else:
		# Vertikal fahren: nur X-Koordinate korrigieren
		global_position.x = tile_center.x


func _update_sprite_direction() -> void:
	if not sprite:
		return
	
	if _is_horizontal_direction():
		sprite.texture = load(LORE_SPRITE_HORIZONTAL)
	else:
		sprite.texture = load(LORE_SPRITE_VERTICAL)


func _update_sprite_for_current_tile() -> void:
	if not tile_map or not sprite:
		return
	
	var tile_coords = _get_tile_at_position(global_position)
	var atlas_coords = tile_map.get_cell_atlas_coords(tile_coords)
	
	# Horizontal tiles
	for tile in RAIL_TILES_HORIZONTAL:
		if atlas_coords == tile:
			sprite.texture = load(LORE_SPRITE_HORIZONTAL)
			return
	
	# Vertikal tiles oder Kurven → standard vertikal
	sprite.texture = load(LORE_SPRITE_VERTICAL)


# === Mount System ===

func mount(player: CharacterBody2D) -> void:
	rider = player
	current_state = State.WAITING_FOR_DIRECTION
	last_curve_tile = Vector2i(-999, -999)  # Reset für neue Fahrt
	last_debug_tile = Vector2i(-999, -999)  # Reset Debug
	
	# Player unsichtbar machen und Physik deaktivieren
	player.visible = false
	player.set_physics_process(false)
	player.set_process_input(false)
	
	# Player Position an Lore koppeln
	player.global_position = global_position
	
	# Kamera zur Lore wechseln
	if camera:
		camera.enabled = true
		camera.make_current()
	
	print("🚃 Spieler ist in der Lore! Wähle Richtung mit Pfeiltasten...")


func dismount() -> Vector2:
	if not rider:
		return global_position
	
	# Absteige-Position: neben der Lore
	var dismount_pos = global_position + Vector2(50, 0)
	
	# Player wieder aktivieren
	rider.visible = true
	rider.set_physics_process(true)
	rider.set_process_input(true)
	rider.global_position = dismount_pos
	
	# Kamera zurück zum Player wechseln
	if camera:
		camera.enabled = false
	if rider.has_node("Camera2D"):
		rider.get_node("Camera2D").make_current()
	
	# Player-Referenz zurücksetzen
	rider.is_in_lore = false
	rider.current_lore = null
	rider = null
	
	print("🚃 Spieler ist aus der Lore ausgestiegen bei %s" % dismount_pos)
	
	return dismount_pos


func is_mounted() -> bool:
	return rider != null


# === Interaction Events ===

func _on_interaction_area_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state == State.IDLE:
		emit_signal("player_nearby", self)
		print("🚃 Spieler in Reichweite - E zum Einsteigen drücken")


func _on_interaction_area_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		emit_signal("player_left")
