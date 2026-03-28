extends CanvasLayer

var Constants = preload("res://scripts/constants.gd")

# References
@onready var background = $Control/Background
@onready var health_bar = $Control/HealthBar
@onready var container = $Control

# Parent (der Character den wir tracken)
var parent_entity: Node2D = null

# Health Tracking
var current_hp: int = 100
var max_hp: int = 100

func _ready() -> void:
	# Parent ist der CharacterBody2D (T-Rex, Player, etc)
	parent_entity = get_parent()
	
	# Initial Setup
	_setup_healthbar()
	
	if Constants.DEBUG_MODE:
		print("✓ HealthBar initialized for %s" % parent_entity.name)

func _setup_healthbar() -> void:
	"""Initialisiert die HealthBar UI-Elemente."""
	if not background or not health_bar or not container:
		push_error("HealthBar: Missing UI elements!")
		return
	
	# Größe setzen
	container.custom_minimum_size = Vector2(Constants.HEALTHBAR_WIDTH, Constants.HEALTHBAR_HEIGHT)
	background.custom_minimum_size = Vector2(Constants.HEALTHBAR_WIDTH, Constants.HEALTHBAR_HEIGHT)
	health_bar.custom_minimum_size = Vector2(Constants.HEALTHBAR_WIDTH, Constants.HEALTHBAR_HEIGHT)
	
	# Position: oben über dem Character
	container.position.y = Constants.HEALTHBAR_OFFSET_Y
	
	# Farben
	background.color = Color.DARK_GRAY  # Dunkelgrauer Hintergrund
	health_bar.color = Color.GREEN  # Grüner Lebensbalken

func _process(delta: float) -> void:
	# Folge dem Parent (relativ zur Kamera ist nicht nötig, CanvasLayer kümmert sich darum)
	# Die HealthBar ist ein Child, also folgt sie automatisch
	pass

func update_health(hp: int, max_h: int) -> void:
	"""Aktualisiert die HealthBar Anzeige."""
	current_hp = hp
	max_hp = max_h
	
	if not health_bar:
		return
	
	# Berechne Prozentsatz
	var health_percent = float(current_hp) / float(max_hp)
	
	# Setze Health Bar Breite
	var new_width = Constants.HEALTHBAR_WIDTH * health_percent
	health_bar.custom_minimum_size.x = new_width
	
	# Farbe je nach HP: Grün → Gelb → Rot
	if health_percent > 0.5:
		health_bar.color = Color.GREEN
	elif health_percent > 0.25:
		health_bar.color = Color.YELLOW
	else:
		health_bar.color = Color.RED
	
	if Constants.DEBUG_MODE and hp != max_h:
		print("  → HealthBar updated: %d/%d (%.0f%%)" % [hp, max_h, health_percent * 100])

func show_damage_indicator(amount: int) -> void:
	"""Optional: Zeige Damage-Nummer kurz an."""
	# Kann später erweitert werden mit floating Damage-Text
	pass
