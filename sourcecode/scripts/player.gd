extends CharacterBody2D

var Constants = preload("res://scripts/constants.gd")

# Physics
var speed: float = Constants.PLAYER_SPEED

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
	
	# Verbinde DetectionArea mit Auto-Sammeln
	if detection_area:
		detection_area.area_entered.connect(_on_item_entered)

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
	move_and_slide()
	
	# Debug: Position anzeigen (optional)
	if Constants.DEBUG_MODE:
		#print("Player Position: %s, Velocity: %s" % [global_position, velocity])
		pass

func _input(event: InputEvent) -> void:
	# E-Taste entfernt - Items sammeln automatisch per Berührung
	pass

func _on_item_entered(area: Area2D) -> void:
	"""Wird aufgerufen wenn ein Item die DetectionArea betritt."""
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

func _collect_nearby_items() -> void:
	"""Deprecated - Items sammeln automatisch per Berührung."""
	pass

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
