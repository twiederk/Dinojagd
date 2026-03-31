class_name TRex
extends CharacterBody2D

var Constants = preload("res://scripts/constants.gd")

var hp: int = Constants.T_REX_HP
var max_hp: int = Constants.T_REX_MAX_HP
var damage: int = Constants.T_REX_DAMAGE
var speed: float = Constants.T_REX_SPEED
var chase_speed: float = Constants.T_REX_CHASE_SPEED


@onready var sprite = $Sprite2D
@onready var detection_area = $DetectionArea
@onready var damage_area = $DamageArea
@onready var healthbar = $HealthBar


var target_player: CharacterBody2D = null
var ai_mode: String = "PATROL"  # PATROL, CHASE, IDLE, RETURN
var start_position: Vector2 = Vector2.ZERO


var damage_cooldown: float = 0.0

signal health_changed(hp: int, max_hp: int)
signal enemy_died


func _ready() -> void:
	add_to_group("enemies")
	
	start_position = global_position
	
	if sprite:
		sprite.texture = load(Constants.T_REX_SPRITE_PATH)
	
	target_player = get_tree().root.find_child("Player", true, false)
	
	if detection_area:
		detection_area.area_entered.connect(_on_detection_entered)
		detection_area.area_exited.connect(_on_detection_exited)
	
	if damage_area:
		damage_area.area_entered.connect(_on_damage_area_entered)
	
	if healthbar:
		healthbar.max_value = max_hp
		healthbar.value = hp
	
	if Constants.DEBUG_MODE:
		print("✓ T-Rex spawned at %s" % global_position)


func _physics_process(delta: float) -> void:
	if damage_cooldown > 0:
		damage_cooldown -= delta
	
	_update_ai_movement()
	
	move_and_slide()

	
func _update_ai_movement() -> void:
	if ai_mode == "CHASE" and target_player:
		var direction = (target_player.global_position - global_position).normalized()
		velocity = direction * chase_speed
	elif ai_mode == "RETURN":
		# Zurück zur Startposition
		var distance_to_start = global_position.distance_to(start_position)
		if distance_to_start > 5.0:  # 5 Pixel Toleranz
			var direction = (start_position - global_position).normalized()
			velocity = direction * speed
		else:
			# An Startposition angekommen
			ai_mode = "PATROL"
			velocity = Vector2.ZERO
	elif ai_mode == "PATROL":
		velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO


func _on_detection_entered(area: Area2D) -> void:
	print("Player detected in T-Rex detection area!")
	var is_player = area.is_in_group("player") or (area.get_parent() and area.get_parent().is_in_group("player"))
	if is_player:
		ai_mode = "CHASE"
		if Constants.DEBUG_MODE:
			print("  → T-Rex detected Player! Chase mode activated")


func _on_detection_exited(area: Area2D) -> void:
	var is_player = area.is_in_group("player") or (area.get_parent() and area.get_parent().is_in_group("player"))
	if is_player:
		ai_mode = "RETURN"
		if Constants.DEBUG_MODE:
			print("  → Player lost! Returning to start position: %s" % start_position)


func _on_damage_area_entered(area: Area2D) -> void:
	# Prüfe ob Bullet getroffen hat
	if area.is_in_group("bullets"):
		if area.has_method("damage"):
			take_damage(area.damage)
		else:
			take_damage(Constants.BULLET_DAMAGE)
		area.queue_free()
		if Constants.DEBUG_MODE:
			print("  → T-Rex hit by bullet!")
		return
	
	# Prüfe ob Brontosaurus berührt wird (wenn Spieler drauf sitzt)
	var parent = area.get_parent()
	if parent and parent.is_in_group("vehicles") and parent.has_method("is_mounted") and parent.is_mounted() and damage_cooldown <= 0:
		# Schaden auf Brontosaurus zufügen wenn Spieler drauf sitzt
		if parent.has_method("take_damage"):
			parent.take_damage(damage)
			damage_cooldown = Constants.T_REX_DAMAGE_COOLDOWN
			
			if Constants.DEBUG_MODE:
				print("  → T-Rex dealt %d damage to Brontosaurus!" % damage)
		return
	
	# Prüfe ob Player berührt
	print("Player detected in T-Rex DAMAGE area!")
	var is_player = area.is_in_group("player") or (area.get_parent() and area.get_parent().is_in_group("player"))
	if is_player and damage_cooldown <= 0:
		# Schaden auf Player zufügen
		if area.get_parent().has_method("take_damage"):
			area.get_parent().take_damage(damage)
			damage_cooldown = Constants.T_REX_DAMAGE_COOLDOWN
			
			if Constants.DEBUG_MODE:
				print("  → T-Rex dealt %d damage to Player!" % damage)


func take_damage(amount: int) -> void:
	hp -= amount
	healthbar.value = hp
	emit_signal("health_changed", hp, max_hp)
	
	if Constants.DEBUG_MODE:
		print("🦖 T-Rex takes %d damage! HP: %d/%d" % [amount, hp, max_hp])
	
	if hp <= 0:
		_die()


func _die() -> void:
	emit_signal("enemy_died")
	
	if Constants.DEBUG_MODE:
		print("💀 T-Rex died!")
	
	queue_free()
