extends CharacterBody2D

# Physics
var speed: float = Constants.PLAYER_SPEED
var velocity: Vector2 = Vector2.ZERO

# Inventar: Dict[ItemType, int]
var inventory: Dictionary = {}

# References
@onready var sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var camera = $Camera2D

# Signals
signal item_collected(item_type: int, count: int)

func _ready() -> void:
	# Initiales Inventar initialisieren
	for item_type in Constants.ItemType.values():
		inventory[item_type] = 0
	
	# Sprite setzen
	if sprite:
		sprite.texture = load(Constants.PLAYER_SPRITE_PATH)
	
	# Camera Setup
	if camera:
		camera.make_current()

func _physics_process(delta: float) -> void:
	# Input-Vektor sammeln (WASD + Pfeiltasten)
	var input_vector = Vector2.ZERO
	
	# WASD Input
	if Input.is_action_pressed("ui_move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_move_right"):
		input_vector.x += 1
	
	# Input-Vektor normalisieren (diagonal = gleiche Speed wie vertikal/horizontal)
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		velocity = input_vector * speed
	else:
		velocity = Vector2.ZERO
	
	# Bewegung anwenden
	velocity = move_and_slide(velocity)
	
	# Debug: Position anzeigen (optional)
	if Constants.DEBUG_MODE:
		#print("Player Position: %s, Velocity: %s" % [global_position, velocity])
		pass

func _input(event: InputEvent) -> void:
	# E-Taste zum Sammeln von Items
	if event.is_action_pressed("collect_item"):
		_collect_nearby_items()

func _collect_nearby_items() -> void:
	"""Sammelt alle Items die sich in der Detection Area überlappen."""
	var overlapping_areas = detection_area.get_overlapping_areas()
	
	for area in overlapping_areas:
		# Prüfe ob Area ein Item ist (muss 'item_type' Export-Var haben)
		if area.is_in_group("items"):
			var item_type = area.item_type
			
			# Item zum Inventar hinzufügen
			if item_type in inventory:
				inventory[item_type] += 1
				emit_signal("item_collected", item_type, inventory[item_type])
				
				# Item aus der Welt entfernen
				area.queue_free()
			
			if Constants.DEBUG_MODE:
				var display_name = Constants.ITEM_DATA[item_type]["display_name"]
				print("✓ Item collected: %s (Total: %d)" % [display_name, inventory[item_type]])

func get_inventory() -> Dictionary:
	"""Gibt das aktuelle Inventar zurück."""
	return inventory.duplicate()

func has_item(item_type: int) -> bool:
	"""Prüft ob der Spieler ein bestimmtes Item hat."""
	return inventory.get(item_type, 0) > 0

func get_item_count(item_type: int) -> int:
	"""Gibt die Anzahl eines bestimmten Items zurück."""
	return inventory.get(item_type, 0)

# Debug: Zeichne Collection Radius in der Szene
func _draw() -> void:
	if Constants.DEBUG_MODE and Constants.DRAW_COLLECTION_RADIUS:
		draw_circle(Vector2.ZERO, Constants.PLAYER_COLLECTION_RADIUS, Color.YELLOW)
