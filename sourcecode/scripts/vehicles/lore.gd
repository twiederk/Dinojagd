class_name Lore
extends CharacterBody2D

var Constants = preload("res://scripts/constants.gd")

# States
enum State { IDLE, WAITING_FOR_DIRECTION, MOVING, RETURNING }
var current_state: State = State.IDLE

# Rider
var rider: CharacterBody2D = null

# Position & Movement
var start_position: Vector2 = Vector2.ZERO
var current_direction: Vector2 = Vector2.ZERO
var tile_map: TileMapLayer = null

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
		sprite.texture = load(Constants.LORE_SPRITE_HORIZONTAL)
	
	# Signals verbinden
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)
	
	# TileMapLayer finden
	await get_tree().process_frame
	_find_tilemap()
	
	# Initiale Sprite-Richtung basierend auf Schiene
	_update_sprite_for_current_tile()
	
	if Constants.DEBUG_MODE:
		print("🚃 Lore erschienen bei %s" % global_position)


func _find_tilemap() -> void:
	"""Findet die SchienenEbene TileMapLayer."""
	var main = get_tree().root.find_child("Main", true, false)
	if main:
		tile_map = main.find_child("SchienenEbene", true, false)
		if tile_map and Constants.DEBUG_MODE:
			print("🚃 SchienenEbene gefunden!")
		elif Constants.DEBUG_MODE:
			print("⚠️ SchienenEbene nicht gefunden!")


func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.WAITING_FOR_DIRECTION:
			_handle_direction_input()
		State.MOVING:
			_move_on_rails(Constants.LORE_SPEED)
		State.RETURNING:
			_return_to_start()
	
	if current_state in [State.MOVING, State.RETURNING]:
		move_and_slide()
		
		# Rider Position aktualisieren
		if rider:
			rider.global_position = global_position


func _handle_direction_input() -> void:
	"""Wartet auf Richtungseingabe vom Spieler."""
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
			if Constants.DEBUG_MODE:
				print("🚃 Lore fährt los in Richtung: %s" % current_direction)
		elif Constants.DEBUG_MODE:
			print("⚠️ Keine Schienen in dieser Richtung!")


func _move_on_rails(speed: float) -> void:
	"""Bewegt die Lore entlang der Schienen."""
	velocity = current_direction * speed
	
	# Prüfe ob wir uns noch auf Schienen befinden
	var next_pos = global_position + current_direction * speed * get_physics_process_delta_time()
	
	# Wenn wir uns zu einer neuen Tile bewegen, prüfe die Richtung
	var current_tile = _get_tile_at_position(global_position)
	var next_tile = _get_tile_at_position(next_pos)
	
	if current_tile != next_tile:
		# Wir haben eine neue Tile erreicht
		_handle_tile_transition(next_tile)


func _handle_tile_transition(next_tile: Vector2i) -> void:
	"""Behandelt den Übergang zu einer neuen Tile."""
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
	"""Behandelt Kurven und ändert die Fahrtrichtung."""
	# Kurven-Mapping basierend auf Atlas-Koordinaten:
	# (19,0) = Kurve oben-links (kommt von rechts → geht nach unten, oder von unten → geht nach rechts)
	# (21,0) = Kurve oben-rechts (kommt von links → geht nach unten, oder von unten → geht nach links)
	# (19,2) = Kurve unten-links (kommt von rechts → geht nach oben, oder von oben → geht nach rechts)
	# (21,2) = Kurve unten-rechts (kommt von links → geht nach oben, oder von oben → geht nach links)
	
	var new_direction = current_direction
	
	match tile_data:
		Vector2i(19, 0):  # Kurve oben-links
			if current_direction == Vector2.RIGHT:
				new_direction = Vector2.DOWN
			elif current_direction == Vector2.UP:
				new_direction = Vector2.LEFT
		Vector2i(21, 0):  # Kurve oben-rechts
			if current_direction == Vector2.LEFT:
				new_direction = Vector2.DOWN
			elif current_direction == Vector2.UP:
				new_direction = Vector2.RIGHT
		Vector2i(19, 2):  # Kurve unten-links
			if current_direction == Vector2.RIGHT:
				new_direction = Vector2.UP
			elif current_direction == Vector2.DOWN:
				new_direction = Vector2.LEFT
		Vector2i(21, 2):  # Kurve unten-rechts
			if current_direction == Vector2.LEFT:
				new_direction = Vector2.UP
			elif current_direction == Vector2.DOWN:
				new_direction = Vector2.RIGHT
	
	if new_direction != current_direction:
		current_direction = new_direction
		if Constants.DEBUG_MODE:
			print("🚃 Kurve! Neue Richtung: %s" % current_direction)


func _end_of_rails() -> void:
	"""Ende der Schienen erreicht - Spieler steigt aus."""
	velocity = Vector2.ZERO
	
	if rider:
		if Constants.DEBUG_MODE:
			print("🚃 Ende der Schienen erreicht! Spieler steigt aus.")
		dismount()
	
	# Lore fährt zurück zum Start
	current_state = State.RETURNING
	if Constants.DEBUG_MODE:
		print("🚃 Lore fährt zurück zum Startpunkt...")


func _return_to_start() -> void:
	"""Lore fährt zurück zum Startpunkt."""
	var distance = global_position.distance_to(start_position)
	
	if distance < 5.0:
		# Am Start angekommen
		global_position = start_position
		current_state = State.IDLE
		velocity = Vector2.ZERO
		_update_sprite_for_current_tile()
		if Constants.DEBUG_MODE:
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
	_move_on_rails(Constants.LORE_RETURN_SPEED)


func _can_move_in_direction(direction: Vector2) -> bool:
	"""Prüft ob Schienen in der angegebenen Richtung existieren."""
	if not tile_map:
		return false
	
	var check_pos = global_position + direction * 32  # Eine Tile weiter
	var tile_coords = _get_tile_at_position(check_pos)
	var tile_data = tile_map.get_cell_atlas_coords(tile_coords)
	
	return _is_rail_tile(tile_data)


func _get_tile_at_position(pos: Vector2) -> Vector2i:
	"""Gibt die Tile-Koordinaten für eine Weltposition zurück."""
	if not tile_map:
		return Vector2i(-1, -1)
	return tile_map.local_to_map(tile_map.to_local(pos))


func _is_rail_tile(atlas_coords: Vector2i) -> bool:
	"""Prüft ob die Atlas-Koordinaten eine Schienen-Tile sind."""
	if atlas_coords == Vector2i(-1, -1):
		return false
	
	# Alle Schienen-Tiles prüfen
	for tile in Constants.RAIL_TILES_HORIZONTAL:
		if atlas_coords == tile:
			return true
	for tile in Constants.RAIL_TILES_VERTICAL:
		if atlas_coords == tile:
			return true
	for tile in Constants.RAIL_TILES_CURVES:
		if atlas_coords == tile:
			return true
	
	return false


func _is_curve_tile(atlas_coords: Vector2i) -> bool:
	"""Prüft ob die Atlas-Koordinaten eine Kurven-Tile sind."""
	for tile in Constants.RAIL_TILES_CURVES:
		if atlas_coords == tile:
			return true
	return false


func _is_horizontal_direction() -> bool:
	"""Prüft ob die aktuelle Richtung horizontal ist."""
	return current_direction == Vector2.LEFT or current_direction == Vector2.RIGHT


func _update_sprite_direction() -> void:
	"""Aktualisiert das Sprite basierend auf der Fahrtrichtung."""
	if not sprite:
		return
	
	if _is_horizontal_direction():
		sprite.texture = load(Constants.LORE_SPRITE_HORIZONTAL)
	else:
		sprite.texture = load(Constants.LORE_SPRITE_VERTICAL)


func _update_sprite_for_current_tile() -> void:
	"""Setzt das Sprite basierend auf der aktuellen Schienen-Tile."""
	if not tile_map or not sprite:
		return
	
	var tile_coords = _get_tile_at_position(global_position)
	var atlas_coords = tile_map.get_cell_atlas_coords(tile_coords)
	
	# Horizontal tiles
	for tile in Constants.RAIL_TILES_HORIZONTAL:
		if atlas_coords == tile:
			sprite.texture = load(Constants.LORE_SPRITE_HORIZONTAL)
			return
	
	# Vertikal tiles oder Kurven → standard vertikal
	sprite.texture = load(Constants.LORE_SPRITE_VERTICAL)


# === Mount System ===

func mount(player: CharacterBody2D) -> void:
	"""Spieler steigt in die Lore ein."""
	rider = player
	current_state = State.WAITING_FOR_DIRECTION
	
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
	
	if Constants.DEBUG_MODE:
		print("🚃 Spieler ist in der Lore! Wähle Richtung mit Pfeiltasten...")


func dismount() -> Vector2:
	"""Spieler steigt aus der Lore aus."""
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
	
	if Constants.DEBUG_MODE:
		print("🚃 Spieler ist aus der Lore ausgestiegen bei %s" % dismount_pos)
	
	return dismount_pos


func is_mounted() -> bool:
	"""Gibt zurück ob ein Spieler in der Lore sitzt."""
	return rider != null


# === Interaction Events ===

func _on_interaction_area_entered(body: Node2D) -> void:
	"""Spieler kommt in Interaktions-Reichweite."""
	if body.is_in_group("player") and current_state == State.IDLE:
		emit_signal("player_nearby", self)
		if Constants.DEBUG_MODE:
			print("🚃 Spieler in Reichweite - E zum Einsteigen drücken")


func _on_interaction_area_exited(body: Node2D) -> void:
	"""Spieler verlässt Interaktions-Reichweite."""
	if body.is_in_group("player"):
		emit_signal("player_left")
