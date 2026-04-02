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
var entities_in_damage_area: Array = []  # Speichert Player/Brontosaurus im damage_area

signal health_changed(hp: int, max_hp: int)
signal enemy_died


func _ready() -> void:
	add_to_group("enemies")
	
	start_position = global_position
	
	if sprite:
		sprite.texture = load(Constants.T_REX_SPRITE_PATH)
	
	target_player = get_tree().root.find_child("Player", true, false)
	
	if detection_area:
		detection_area.body_entered.connect(_on_detection_entered)
		detection_area.body_exited.connect(_on_detection_exited)
	
	if damage_area:
		damage_area.body_entered.connect(_on_damage_area_entered)
		damage_area.body_exited.connect(_on_damage_area_exited)
		damage_area.area_entered.connect(_on_bullet_hit)
	
	if healthbar:
		healthbar.max_value = max_hp
		healthbar.value = hp
	
	if Constants.DEBUG_MODE:
		print("✓ T-Rex erschienen bei %s" % global_position)


func _physics_process(delta: float) -> void:
	if damage_cooldown > 0:
		damage_cooldown -= delta
	
	# Kontinuierlicher Schaden an Entities im damage_area
	_apply_continuous_damage()
	
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


func _on_detection_entered(body: Node2D) -> void:
	var is_player = body.is_in_group("player")
	if is_player:
		ai_mode = "CHASE"
		if Constants.DEBUG_MODE:
			print("  → T-Rex hat Spieler erkannt! Jagdmodus aktiviert")


func _on_detection_exited(body: Node2D) -> void:
	var is_player = body.is_in_group("player")
	if is_player:
		ai_mode = "RETURN"
		if Constants.DEBUG_MODE:
			print("  → Spieler verloren! Kehre zur Startposition zurück: %s" % start_position)


func _on_damage_area_entered(body: Node2D) -> void:
	# Prüfe ob Brontosaurus berührt wird (wenn Spieler drauf sitzt)
	if body.is_in_group("vehicles") and body.has_method("is_mounted") and body.is_mounted():
		# Zur Tracking-Liste hinzufügen
		if not entities_in_damage_area.has(body):
			entities_in_damage_area.append(body)
		
		# Sofort Schaden zufügen wenn Cooldown bereit
		if damage_cooldown <= 0 and body.has_method("take_damage"):
			body.take_damage(damage)
			damage_cooldown = Constants.T_REX_DAMAGE_COOLDOWN
			
			if Constants.DEBUG_MODE:
				print("  → T-Rex verursachte %d Schaden am Brontosaurus!" % damage)
		return
	
	# Prüfe ob Player berührt
	if body.is_in_group("player"):
		# Zur Tracking-Liste hinzufügen
		if not entities_in_damage_area.has(body):
			entities_in_damage_area.append(body)
		
		# Sofort Schaden zufügen wenn Cooldown bereit
		if damage_cooldown <= 0 and body.has_method("take_damage"):
			body.take_damage(damage)
			damage_cooldown = Constants.T_REX_DAMAGE_COOLDOWN
			
			if Constants.DEBUG_MODE:
				print("  → T-Rex verursachte %d Schaden am Spieler!" % damage)


func _on_damage_area_exited(body: Node2D) -> void:
	# Entity aus der Tracking-Liste entfernen
	if entities_in_damage_area.has(body):
		entities_in_damage_area.erase(body)
		
		if Constants.DEBUG_MODE:
			if body.is_in_group("player"):
				print("  → Spieler hat damage_area verlassen")
			elif body.is_in_group("vehicles"):
				print("  → Brontosaurus hat damage_area verlassen")


func _apply_continuous_damage() -> void:
	# Nur Schaden zufügen wenn Cooldown bereit und Entities vorhanden
	if damage_cooldown > 0 or entities_in_damage_area.is_empty():
		return
	
	# Kopie der Liste für sichere Iteration
	var entities_to_damage = entities_in_damage_area.duplicate()
	
	for entity in entities_to_damage:
		if not is_instance_valid(entity):
			entities_in_damage_area.erase(entity)
			continue
		
		# Brontosaurus: Nur Schaden wenn beritten
		if entity.is_in_group("vehicles"):
			if entity.has_method("is_mounted") and entity.is_mounted() and entity.has_method("take_damage"):
				entity.take_damage(damage)
				damage_cooldown = Constants.T_REX_DAMAGE_COOLDOWN
				
				if Constants.DEBUG_MODE:
					print("  → T-Rex verursachte %d kontinuierlichen Schaden am Brontosaurus!" % damage)
				return  # Ein Schaden pro Cooldown-Zyklus
		
		# Player
		if entity.is_in_group("player") and entity.has_method("take_damage"):
			entity.take_damage(damage)
			damage_cooldown = Constants.T_REX_DAMAGE_COOLDOWN
			
			if Constants.DEBUG_MODE:
				print("  → T-Rex verursachte %d kontinuierlichen Schaden am Spieler!" % damage)
			return  # Ein Schaden pro Cooldown-Zyklus


func _on_bullet_hit(area: Area2D) -> void:
	# Prüfe ob Bullet getroffen hat
	if area.is_in_group("bullets"):
		if area.has_method("damage"):
			take_damage(area.damage)
		else:
			take_damage(Constants.BULLET_DAMAGE)
		area.queue_free()
		if Constants.DEBUG_MODE:
			print("  → T-Rex wurde von Kugel getroffen!")


func take_damage(amount: int) -> void:
	hp -= amount
	healthbar.value = hp
	emit_signal("health_changed", hp, max_hp)
	
	if Constants.DEBUG_MODE:
		print("🦖 T-Rex erhält %d Schaden! HP: %d/%d" % [amount, hp, max_hp])
	
	if hp <= 0:
		_die()


func _die() -> void:
	emit_signal("enemy_died")
	
	if Constants.DEBUG_MODE:
		print("💀 T-Rex ist gestorben!")
	
	queue_free()
