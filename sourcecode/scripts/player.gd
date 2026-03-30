extends CharacterBody2D

var Constants = preload("res://scripts/constants.gd")

# Physics
var speed: float = Constants.PLAYER_SPEED

# Inventar: Dict[ItemType, int]
var inventory: Dictionary = {}

# Health System
var hp: int = Constants.PLAYER_HP
var max_hp: int = Constants.PLAYER_MAX_HP
var damage_cooldown: float = 0.0
var is_alive: bool = true

# Gun System (Phase 3)
var has_gun: bool = false
var gun_cooldown_timer: float = 0.0
var last_direction: Vector2 = Vector2.RIGHT  # Standard-Richtung
var BulletScene = preload("res://scenes/bullets/Bullet.tscn")

# Mount/Vehicle System (Phase 4)
var is_mounted: bool = false
var current_mount: CharacterBody2D = null  # Brontosaurus Referenz
var is_on_quad: bool = false
var has_quad: bool = false
var nearby_brontosaurus: CharacterBody2D = null
var original_speed: float = 0.0

# References
@onready var sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var camera = $Camera2D
@onready var health_bar = $HealthBar

# Signals
signal item_collected(item_type: int, count: int)
signal health_changed(hp: int, max_hp: int)
signal player_died

func _ready() -> void:
	# Zur "player" Gruppe hinzufügen (für Detection durch Gegner)
	add_to_group("player")
	
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
		
	health_bar.max_value = max_hp
	health_bar.value = hp

func _physics_process(delta: float) -> void:
	# Update Cooldowns
	if damage_cooldown > 0:
		damage_cooldown -= delta
	if gun_cooldown_timer > 0:
		gun_cooldown_timer -= delta
	
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
		# Letzte Bewegungsrichtung speichern für Schuss
		last_direction = input_vector
	else:
		velocity = Vector2.ZERO
	
	# Bewegung anwenden
	move_and_slide()
	
	# Debug: Position anzeigen (optional)
	if Constants.DEBUG_MODE:
		#print("Player Position: %s, Velocity: %s" % [global_position, velocity])
		pass

func _input(event: InputEvent) -> void:
	# Leertaste zum Schießen (wenn Gewehr vorhanden und nicht auf Quad)
	if event.is_action_pressed("ui_accept"):
		if has_gun and gun_cooldown_timer <= 0 and not is_on_quad and not is_mounted:
			_fire_gun()
	
	# E-Taste: Mount/Dismount Brontosaurus
	if event.is_action_pressed("interact"):
		if is_mounted:
			_dismount_brontosaurus()
		elif nearby_brontosaurus and _can_mount() and not is_on_quad:
			_mount_brontosaurus(nearby_brontosaurus)
		elif nearby_brontosaurus and not _can_mount():
			if Constants.DEBUG_MODE:
				print("⚠️ Benötigt Gras und Sattel zum Reiten!")
	
	# Q-Taste: Quad Toggle
	if event.is_action_pressed("toggle_quad"):
		if has_quad and not is_mounted:
			_toggle_quad()

func _fire_gun() -> void:
	"""Feuert eine Kugel in die letzte Bewegungsrichtung."""
	gun_cooldown_timer = Constants.GUN_COOLDOWN
	
	# Bullet erstellen
	var bullet = BulletScene.instantiate()
	bullet.global_position = global_position
	bullet.set_direction(last_direction)
	
	# Bullet zur Hauptszene hinzufügen (nicht als Child vom Player)
	get_tree().root.get_child(0).add_child(bullet)
	
	if Constants.DEBUG_MODE:
		print("🔫 Player fired gun in direction: %s" % last_direction)

# ==================== Mount/Vehicle System (Phase 4) ====================

func _can_mount() -> bool:
	"""Prüft ob der Spieler Gras und Sattel hat."""
	return has_item(Constants.ItemType.GRASS) and has_item(Constants.ItemType.SADDLE)

func _mount_brontosaurus(bronto: CharacterBody2D) -> void:
	"""Spieler steigt auf den Brontosaurus."""
	if not bronto or is_mounted:
		return
	
	is_mounted = true
	current_mount = bronto
	bronto.mount(self)
	
	# Verbrauche Gras (Sattel bleibt)
	inventory[Constants.ItemType.GRASS] -= 1
	emit_signal("item_collected", Constants.ItemType.GRASS, inventory[Constants.ItemType.GRASS])
	
	if Constants.DEBUG_MODE:
		print("🦕 Mounted Brontosaurus! Gras verbraucht.")

func _dismount_brontosaurus() -> void:
	"""Spieler steigt vom Brontosaurus ab."""
	if not current_mount:
		return
	
	current_mount.dismount()
	is_mounted = false
	current_mount = null
	
	if Constants.DEBUG_MODE:
		print("🦕 Dismounted Brontosaurus!")

func _toggle_quad() -> void:
	"""Quad-Modus an/aus schalten."""
	is_on_quad = !is_on_quad
	
	if is_on_quad:
		original_speed = speed
		speed = Constants.QUAD_SPEED
		if sprite:
			sprite.texture = load(Constants.QUAD_SPRITE_PATH)
		if Constants.DEBUG_MODE:
			print("🏎️ Quad aktiviert! Speed: %d" % speed)
	else:
		speed = Constants.PLAYER_SPEED
		if sprite:
			sprite.texture = load(Constants.PLAYER_SPRITE_PATH)
		if Constants.DEBUG_MODE:
			print("🏎️ Quad deaktiviert! Speed: %d" % speed)

func set_nearby_brontosaurus(bronto: CharacterBody2D) -> void:
	"""Wird vom Brontosaurus aufgerufen wenn Player in Reichweite."""
	nearby_brontosaurus = bronto

func clear_nearby_brontosaurus() -> void:
	"""Wird vom Brontosaurus aufgerufen wenn Player außer Reichweite."""
	nearby_brontosaurus = null

func _on_item_entered(area: Area2D) -> void:
	"""Wird aufgerufen wenn ein Item die DetectionArea betritt."""
	if area.is_in_group("items"):
		var item_type = area.item_type
		
		# Item zum Inventar hinzufügen
		if item_type in inventory:
			inventory[item_type] += 1
			emit_signal("item_collected", item_type, inventory[item_type])
			
			# Prüfe ob Gewehr gesammelt wurde
			if item_type == Constants.ItemType.GUN:
				has_gun = true
				if Constants.DEBUG_MODE:
					print("🔫 Gun acquired! Press SPACE to shoot.")
			
			# Prüfe ob Quad gesammelt wurde
			if item_type == Constants.ItemType.QUAD:
				has_quad = true
				if Constants.DEBUG_MODE:
					print("🏎️ Quad acquired! Press Q to toggle.")
			
			# Item aus der Welt entfernen
			area.queue_free()
		
		if Constants.DEBUG_MODE:
			var display_name = Constants.ITEM_DATA[item_type]["display_name"]
			print("✓ Item collected: %s (Total: %d)" % [display_name, inventory[item_type]])

func take_damage(amount: int) -> void:
	"""Player nimmt Schaden."""
	if not is_alive or damage_cooldown > 0:
		return
	
	hp -= amount
	damage_cooldown = Constants.PLAYER_DAMAGE_COOLDOWN
	health_bar.value = hp
	emit_signal("health_changed", hp, max_hp)
	
	if Constants.DEBUG_MODE:
		print("💥 Player takes %d damage! HP: %d/%d" % [amount, hp, max_hp])
	
	# Wenn HP <= 0, sterben
	if hp <= 0:
		_player_die()

func _player_die() -> void:
	"""Player stirbt."""
	is_alive = false
	emit_signal("player_died")
	
	if Constants.DEBUG_MODE:
		print("💀 Player died! Game Over")
	
	# Optional: Später GameOver-Szene oder Respawn
	# Für jetzt: einfach erstarren
	velocity = Vector2.ZERO
	position = Vector2.ZERO
	hp = 100
	health_bar.value = hp
	

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
