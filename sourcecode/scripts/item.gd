extends Area2D

var Constants = preload("res://scripts/constants.gd")

# Export: Item-Typ wird im Editor gesetzt
@export var item_type: int = 0

# Sprite
@onready var sprite = $Sprite2D

# Animation
var bob_speed: float = 2.0
var bob_amount: float = 10.0
var starting_y: float = 0.0
var rotation_speed: float = 1.0
var elapsed_time: float = 0.0

# Signals
signal collected(item_type: int, position: Vector2)

func _ready() -> void:
	# Zu "items" Gruppe hinzufügen für schnelle Erkennung
	add_to_group("items")
	
	# Sprite laden basierend auf item_type
	_set_sprite_from_item_type()
	
	# Startposition speichern für bobbing animation
	starting_y = global_position.y
	
	if Constants.DEBUG_MODE:
		print("✓ Item spawned: %s at %s" % [Constants.ITEM_DATA[item_type]["display_name"], global_position])

func _set_sprite_from_item_type() -> void:
	"""Lädt die richtige Sprite basierend auf item_type."""
	if sprite and item_type in Constants.ITEM_DATA:
		var sprite_path = Constants.ITEM_DATA[item_type]["sprite_path"]
		sprite.texture = load(sprite_path)
		
		# Sprite-Größe anpassen (z.B. 32x32 als Standard)
		sprite.scale = Vector2(1.0, 1.0)

func _process(delta: float) -> void:
	# Animation: auf und ab bobben + rotieren
	elapsed_time += delta
	
	# Y-Position bobben
	global_position.y = starting_y + sin(elapsed_time * bob_speed) * bob_amount
	
	# Rotieren
	rotation += rotation_speed * delta

func _on_item_collected() -> void:
	"""Wird aufgerufen wenn Item gesammelt wird."""
	emit_signal("collected", item_type, global_position)
	queue_free()
