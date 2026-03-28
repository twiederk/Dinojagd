extends CharacterBody2D

var Constants = preload("res://scripts/constants.gd")

# Stats
var hp: int = Constants.T_REX_HP
var max_hp: int = Constants.T_REX_MAX_HP
var damage: int = Constants.T_REX_DAMAGE
var speed: float = Constants.T_REX_SPEED
var chase_speed: float = Constants.T_REX_CHASE_SPEED

# References
@onready var sprite = $Sprite2D
@onready var detection_area = $DetectionArea
@onready var damage_area = $DamageArea
@onready var healthbar = $HealthBar

# AI State
var target_player: CharacterBody2D = null
var ai_mode: String = "PATROL"  # PATROL, CHASE, IDLE

# Cooldowns
var damage_cooldown: float = 0.0

# Signals
signal health_changed(hp: int, max_hp: int)
signal enemy_died

func _ready() -> void:
	# Sprite laden
	if sprite:
		sprite.texture = load(Constants.T_REX_SPRITE_PATH)
	
	# Player finden
	target_player = get_tree().root.find_child("Player", true, false)
	
	# Signals verbinden
	if detection_area:
		detection_area.area_entered.connect(_on_detection_entered)
		detection_area.area_exited.connect(_on_detection_exited)
	
	if damage_area:
		damage_area.area_entered.connect(_on_damage_area_entered)
	
	# HealthBar initialisieren
	if healthbar:
		healthbar.update_health(hp, max_hp)
		health_changed.connect(healthbar.update_health)
	
	if Constants.DEBUG_MODE:
		print("✓ T-Rex spawned at %s" % global_position)

func _physics_process(delta: float) -> void:
	# Update Cooldowns
	if damage_cooldown > 0:
		damage_cooldown -= delta
	
	# Update AI Movement
	_update_ai_movement()
	
	# Apply movement
	move_and_slide()
	
func _update_ai_movement() -> void:
	"""Update die Bewegung basierend auf AI-Mode."""
	if ai_mode == "CHASE" and target_player:
		var direction = (target_player.global_position - global_position).normalized()
		velocity = direction * chase_speed
	elif ai_mode == "PATROL":
		velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

func _on_detection_entered(area: Area2D) -> void:
	"""Wird aufgerufen wenn det Player endet die DetectionArea betritt."""
	print("Player detected in T-Rex detection area!")
	var is_player = area.is_in_group("player") or (area.get_parent() and area.get_parent().is_in_group("player"))
	if is_player:
		ai_mode = "CHASE"
		if Constants.DEBUG_MODE:
			print("  → T-Rex detected Player! Chase mode activated")

func _on_detection_exited(area: Area2D) -> void:
	"""Wird aufgerufen wenn der Player die DetectionArea verlässt."""
	var is_player = area.is_in_group("player") or (area.get_parent() and area.get_parent().is_in_group("player"))
	if is_player:
		ai_mode = "PATROL"
		if Constants.DEBUG_MODE:
			print("  → Player lost! Back to patrol")

func _on_damage_area_entered(area: Area2D) -> void:
	"""Wird aufgerufen wenn Player die DamageArea berührt."""
	if area.is_in_group("player") and damage_cooldown <= 0:
		# Schaden auf Player zufügen
		if area.has_method("take_damage"):
			area.take_damage(damage)
			damage_cooldown = Constants.T_REX_DAMAGE_COOLDOWN
			
			if Constants.DEBUG_MODE:
				print("  → T-Rex dealt %d damage to Player!" % damage)

func take_damage(amount: int) -> void:
	"""T-Rex nimmt Schaden."""
	hp -= amount
	emit_signal("health_changed", hp, max_hp)
	
	if Constants.DEBUG_MODE:
		print("🦖 T-Rex takes %d damage! HP: %d/%d" % [amount, hp, max_hp])
	
	# Wenn HP <= 0, sterben
	if hp <= 0:
		_die()

func _die() -> void:
	"""T-Rex stirbt."""
	emit_signal("enemy_died")
	
	if Constants.DEBUG_MODE:
		print("💀 T-Rex died!")
	
	queue_free()

func set_target(target_pos: Vector2) -> void:
	"""Setze manuelles Ziel (für Patrol)."""
	pass
