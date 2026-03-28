extends Area2D

var Constants = preload("res://scripts/constants.gd")

# Bullet Properties
var speed: float = Constants.BULLET_SPEED
var damage: int = Constants.BULLET_DAMAGE
var direction: Vector2 = Vector2.RIGHT

# References
@onready var visible_notifier = $VisibleOnScreenNotifier2D

func _ready() -> void:
	# Zur "bullets" Gruppe hinzufügen für Erkennung
	add_to_group("bullets")
	
	# Signal verbinden wenn Bullet den Bildschirm verlässt
	if visible_notifier:
		visible_notifier.screen_exited.connect(_on_screen_exited)
	
	# Body/Area entered Signal für Kollisionserkennung
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	# Bewegung in Schussrichtung
	position += direction * speed * delta

func _on_screen_exited() -> void:
	"""Bullet löschen wenn außerhalb des Bildschirms."""
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	"""Kollision mit CharacterBody2D (z.B. T-Rex)."""
	if body.has_method("take_damage") and not body.is_in_group("player"):
		body.take_damage(damage)
		if Constants.DEBUG_MODE:
			print("🔫 Bullet hit %s for %d damage!" % [body.name, damage])
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	"""Kollision mit Area2D (z.B. Enemy DamageArea)."""
	# Ignoriere Items
	if area.is_in_group("items"):
		return
	
	# Prüfe ob das Parent Schaden nehmen kann
	var parent = area.get_parent()
	if parent and parent.has_method("take_damage") and not parent.is_in_group("player"):
		parent.take_damage(damage)
		if Constants.DEBUG_MODE:
			print("🔫 Bullet hit %s for %d damage!" % [parent.name, damage])
		queue_free()

func set_direction(dir: Vector2) -> void:
	"""Setzt die Flugrichtung der Kugel."""
	direction = dir.normalized() if dir.length() > 0 else Vector2.RIGHT
	# Optional: Sprite rotieren in Flugrichtung
	rotation = direction.angle()
