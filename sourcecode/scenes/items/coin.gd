class_name Coin
extends Area2D

var Constants = preload("res://scripts/constants.gd")

# Item-Typ ist immer COIN
var item_type: int = Constants.ItemType.COIN

# Animation
var bob_speed: float = 2.0
var bob_amount: float = 10.0
var starting_y: float = 0.0
var elapsed_time: float = 0.0

# Signals
signal collected(item_type: int, position: Vector2)


func _ready() -> void:
	# Zu "items" Gruppe hinzufügen für schnelle Erkennung
	add_to_group("items")
	
	# Startposition speichern für bobbing animation
	starting_y = global_position.y
	
	if Constants.DEBUG_MODE:
		print("✓ Coin spawned at %s" % global_position)


func _process(delta: float) -> void:
	# Animation: auf und ab bobben
	elapsed_time += delta
	
	# Y-Position bobben
	global_position.y = starting_y + sin(elapsed_time * bob_speed) * bob_amount


func _on_item_collected() -> void:
	emit_signal("collected", item_type, global_position)
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	"""Wird aufgerufen wenn ein Body die Coin berührt."""
	if body.is_in_group("player"):
		_on_item_collected()
