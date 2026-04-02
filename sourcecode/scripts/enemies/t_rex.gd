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


var chase_target: CharacterBody2D = null  # Aktuelles Ziel (Player, Brontosaurus oder Lore)
var player_ref: CharacterBody2D = null  # Referenz zum Player
var brontosaurus_in_detection: CharacterBody2D = null  # Brontosaurus im detection_area
var lore_in_detection: CharacterBody2D = null  # Lore im detection_area
var player_in_detection: bool = false  # Ist der Player im detection_area?
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
	
	player_ref = get_tree().root.find_child("Player", true, false)
	
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
	
	# Chase-Target aktualisieren (Player auf Brontosaurus?)
	_update_chase_target()
	
	_update_ai_movement()
	
	move_and_slide()

	
func _update_chase_target() -> void:
	"""Bestimmt das aktuelle Verfolgungsziel basierend auf Mount-Status."""
	if ai_mode != "CHASE":
		return
	
	# Prüfe ob Player in einer Lore sitzt
	if player_ref and player_ref.is_in_lore and player_ref.current_lore:
		var lore = player_ref.current_lore
		# Wenn Lore im detection_area ist, verfolge sie
		if lore_in_detection == lore or _is_body_in_detection_area(lore):
			if chase_target != lore:
				chase_target = lore
				if Constants.DEBUG_MODE:
					print("  → T-Rex wechselt Ziel zu Lore (Spieler sitzt drin)!")
			return
	
	# Prüfe ob Player auf Brontosaurus sitzt
	if player_ref and player_ref.is_mounted and player_ref.current_mount:
		var mount = player_ref.current_mount
		# Wenn Brontosaurus im detection_area ist, verfolge ihn
		if brontosaurus_in_detection == mount or _is_body_in_detection_area(mount):
			if chase_target != mount:
				chase_target = mount
				if Constants.DEBUG_MODE:
					print("  → T-Rex wechselt Ziel zu Brontosaurus (Spieler reitet)!")
			return
	
	# Ansonsten verfolge den Player (wenn im detection_area)
	if player_in_detection and player_ref:
		if chase_target != player_ref:
			chase_target = player_ref
			if Constants.DEBUG_MODE:
				print("  → T-Rex wechselt Ziel zurück zum Spieler!")


func _is_body_in_detection_area(body: Node2D) -> bool:
	"""Prüft ob ein Body aktuell im detection_area ist."""
	if not detection_area:
		return false
	var overlapping = detection_area.get_overlapping_bodies()
	return body in overlapping


func _update_ai_movement() -> void:
	if ai_mode == "CHASE" and chase_target:
		var direction = (chase_target.global_position - global_position).normalized()
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
	# Player betritt detection_area
	if body.is_in_group("player"):
		player_in_detection = true
		# Nur verfolgen wenn Player NICHT auf Brontosaurus oder in Lore sitzt
		if not body.is_mounted and not body.is_in_lore:
			chase_target = body
			ai_mode = "CHASE"
			if Constants.DEBUG_MODE:
				print("  → T-Rex hat Spieler erkannt! Jagdmodus aktiviert")
		return
	
	# Lore betritt detection_area
	if body.is_in_group("lore") and body.has_method("is_mounted"):
		lore_in_detection = body
		# Nur verfolgen wenn Player drin sitzt
		if body.is_mounted():
			chase_target = body
			ai_mode = "CHASE"
			if Constants.DEBUG_MODE:
				print("  → T-Rex hat besetzte Lore erkannt! Jagdmodus aktiviert")
		return
	
	# Brontosaurus betritt detection_area
	if body.is_in_group("vehicles") and body.has_method("is_mounted"):
		brontosaurus_in_detection = body
		# Nur verfolgen wenn Player drauf sitzt
		if body.is_mounted():
			chase_target = body
			ai_mode = "CHASE"
			if Constants.DEBUG_MODE:
				print("  → T-Rex hat berittenen Brontosaurus erkannt! Jagdmodus aktiviert")


func _on_detection_exited(body: Node2D) -> void:
	# Player verlässt detection_area
	if body.is_in_group("player"):
		player_in_detection = false
		# Nur RETURN wenn Player das aktuelle Ziel war
		if chase_target == body:
			# Prüfe ob Lore noch da ist und besetzt wird
			if lore_in_detection and lore_in_detection.has_method("is_mounted") and lore_in_detection.is_mounted():
				chase_target = lore_in_detection
				if Constants.DEBUG_MODE:
					print("  → Spieler verloren, verfolge Lore weiter!")
			# Prüfe ob Brontosaurus noch da ist und beritten wird
			elif brontosaurus_in_detection and brontosaurus_in_detection.has_method("is_mounted") and brontosaurus_in_detection.is_mounted():
				chase_target = brontosaurus_in_detection
				if Constants.DEBUG_MODE:
					print("  → Spieler verloren, verfolge Brontosaurus weiter!")
			else:
				ai_mode = "RETURN"
				chase_target = null
				if Constants.DEBUG_MODE:
					print("  → Spieler verloren! Kehre zur Startposition zurück: %s" % start_position)
		return
	
	# Lore verlässt detection_area
	if body.is_in_group("lore"):
		if lore_in_detection == body:
			lore_in_detection = null
		# Nur RETURN wenn Lore das aktuelle Ziel war
		if chase_target == body:
			# Prüfe ob Player noch da ist (und nicht in Vehicle)
			if player_in_detection and player_ref and not player_ref.is_mounted and not player_ref.is_in_lore:
				chase_target = player_ref
				if Constants.DEBUG_MODE:
					print("  → Lore verloren, verfolge Spieler weiter!")
			else:
				ai_mode = "RETURN"
				chase_target = null
				if Constants.DEBUG_MODE:
					print("  → Lore verloren! Kehre zur Startposition zurück: %s" % start_position)
		return
	
	# Brontosaurus verlässt detection_area
	if body.is_in_group("vehicles"):
		if brontosaurus_in_detection == body:
			brontosaurus_in_detection = null
		# Nur RETURN wenn Brontosaurus das aktuelle Ziel war
		if chase_target == body:
			# Prüfe ob Player noch da ist (und nicht mounted)
			if player_in_detection and player_ref and not player_ref.is_mounted and not player_ref.is_in_lore:
				chase_target = player_ref
				if Constants.DEBUG_MODE:
					print("  → Brontosaurus verloren, verfolge Spieler weiter!")
			else:
				ai_mode = "RETURN"
				chase_target = null
				if Constants.DEBUG_MODE:
					print("  → Brontosaurus verloren! Kehre zur Startposition zurück: %s" % start_position)


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
