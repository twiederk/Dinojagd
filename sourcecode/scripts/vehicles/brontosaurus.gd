extends CharacterBody2D

var Constants = preload("res://scripts/constants.gd")

# States
enum State { WANDERING, MOUNTED, IDLE }
var current_state: State = State.WANDERING

# Stats
var hp: int = Constants.BRONTOSAURUS_HP
var max_hp: int = Constants.BRONTOSAURUS_MAX_HP
var damage: int = Constants.BRONTOSAURUS_DAMAGE
var speed: float = Constants.BRONTOSAURUS_SPEED
var mount_speed: float = Constants.BRONTOSAURUS_MOUNT_SPEED

# Mount System
var rider: CharacterBody2D = null  # Referenz zum Player

# Wander System
var start_position: Vector2 = Vector2.ZERO
var wander_target: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0

# Cooldowns
var damage_cooldown: float = 0.0

# References
@onready var sprite = $Sprite2D
@onready var interaction_area = $InteractionArea
@onready var damage_area = $DamageArea
@onready var healthbar = $HealthBar
@onready var camera = $Camera2D

# Signals
signal health_changed(hp: int, max_hp: int)
signal brontosaurus_died
signal player_nearby(bronto: CharacterBody2D)
signal player_left

func _ready() -> void:
	# Startposition speichern
	start_position = global_position
	wander_target = _get_random_wander_target()
	
	# Sprite laden
	if sprite:
		sprite.texture = load(Constants.BRONTOSAURUS_SPRITE_PATH)
	
	# Signals verbinden
	if interaction_area:
		interaction_area.area_entered.connect(_on_interaction_area_entered)
		interaction_area.area_exited.connect(_on_interaction_area_exited)
	
	if damage_area:
		damage_area.body_entered.connect(_on_damage_area_body_entered)
	
	# HealthBar initialisieren
	if healthbar:
		healthbar.update_health(hp, max_hp)
		health_changed.connect(healthbar.update_health)
	
	if Constants.DEBUG_MODE:
		print("✓ Brontosaurus spawned at %s" % global_position)

func _physics_process(delta: float) -> void:
	# Update Cooldowns
	if damage_cooldown > 0:
		damage_cooldown -= delta
	
	# Update Movement based on state
	match current_state:
		State.WANDERING:
			_wander_movement(delta)
		State.MOUNTED:
			_mounted_movement(delta)
		State.IDLE:
			velocity = Vector2.ZERO
	
	# Apply movement
	move_and_slide()

func _input(event: InputEvent) -> void:
	# E-Taste zum Absteigen wenn gemounted
	if event.is_action_pressed("interact") and current_state == State.MOUNTED:
		if rider:
			# Informiere den Player dass er abgestiegen ist
			rider.is_mounted = false
			rider.current_mount = null
			dismount()
			if Constants.DEBUG_MODE:
				print("🦕 Dismount via E-Taste")

func _wander_movement(delta: float) -> void:
	"""Zufälliges Wandern wenn nicht gemounted."""
	wander_timer -= delta
	
	if wander_timer <= 0:
		wander_target = _get_random_wander_target()
		wander_timer = Constants.BRONTOSAURUS_WANDER_INTERVAL
	
	var distance_to_target = global_position.distance_to(wander_target)
	if distance_to_target > 10.0:
		var direction = (wander_target - global_position).normalized()
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

func _mounted_movement(_delta: float) -> void:
	"""Bewegung wenn Player reitet - gesteuert durch Player Input."""
	if not rider:
		return
	
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("ui_move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_move_right"):
		input_vector.x += 1
	
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		velocity = input_vector * mount_speed
	else:
		velocity = Vector2.ZERO

func _get_random_wander_target() -> Vector2:
	"""Generiert ein zufälliges Wanderziel in der Nähe der Startposition."""
	var random_offset = Vector2(
		randf_range(-Constants.BRONTOSAURUS_WANDER_RADIUS, Constants.BRONTOSAURUS_WANDER_RADIUS),
		randf_range(-Constants.BRONTOSAURUS_WANDER_RADIUS, Constants.BRONTOSAURUS_WANDER_RADIUS)
	)
	return start_position + random_offset

func mount(player: CharacterBody2D) -> void:
	"""Player steigt auf den Brontosaurus."""
	rider = player
	current_state = State.MOUNTED
	
	# Player unsichtbar machen und Physik deaktivieren
	player.visible = false
	player.set_physics_process(false)
	player.set_process_input(false)
	
	# Player Position an Brontosaurus koppeln
	player.global_position = global_position
	
	# Kamera zum Brontosaurus wechseln
	if camera:
		camera.enabled = true
		camera.make_current()
	
	if Constants.DEBUG_MODE:
		print("🦕 Player mounted Brontosaurus!")

func dismount() -> Vector2:
	"""Player steigt ab. Gibt die Absteige-Position zurück."""
	if not rider:
		return global_position
	
	var dismount_pos = global_position + Vector2(100, 0)
	
	# Player wieder aktivieren
	rider.visible = true
	rider.set_physics_process(true)
	rider.set_process_input(true)
	rider.global_position = dismount_pos
	
	# Kamera zurück zum Player wechseln
	if camera:
		camera.enabled = false
	if rider.has_node("Camera2D"):
		rider.get_node("Camera2D").make_current()
	
	rider = null
	current_state = State.WANDERING
	wander_timer = 0.0  # Sofort neues Wanderziel
	
	if Constants.DEBUG_MODE:
		print("🦕 Player dismounted Brontosaurus at %s" % dismount_pos)
	
	return dismount_pos

func _on_interaction_area_entered(area: Area2D) -> void:
	"""Player kommt in Interaktions-Reichweite."""
	var is_player = area.is_in_group("player") or (area.get_parent() and area.get_parent().is_in_group("player"))
	if is_player and current_state != State.MOUNTED:
		emit_signal("player_nearby", self)
		if Constants.DEBUG_MODE:
			print("🦕 Player nearby - Press E to mount (requires Grass + Saddle)")

func _on_interaction_area_exited(area: Area2D) -> void:
	"""Player verlässt Interaktions-Reichweite."""
	var is_player = area.is_in_group("player") or (area.get_parent() and area.get_parent().is_in_group("player"))
	if is_player:
		emit_signal("player_left")

func _on_damage_area_body_entered(body: Node2D) -> void:
	"""Kollision mit T-Rex - Schaden zufügen nur wenn geritten."""
	# Nur Schaden machen wenn der Spieler reitet
	if current_state != State.MOUNTED:
		return
	
	if body.is_in_group("enemies") and damage_cooldown <= 0:
		if body.has_method("take_damage"):
			body.take_damage(damage)
			damage_cooldown = Constants.BRONTOSAURUS_DAMAGE_COOLDOWN
			
			if Constants.DEBUG_MODE:
				print("🦕 Brontosaurus dealt %d damage to %s!" % [damage, body.name])

func take_damage(amount: int) -> void:
	"""Brontosaurus nimmt Schaden."""
	hp -= amount
	emit_signal("health_changed", hp, max_hp)
	
	if Constants.DEBUG_MODE:
		print("🦕 Brontosaurus takes %d damage! HP: %d/%d" % [amount, hp, max_hp])
	
	if hp <= 0:
		_die()

func _die() -> void:
	"""Brontosaurus stirbt."""
	# Wenn Player drauf sitzt, abwerfen
	if rider:
		dismount()
	
	emit_signal("brontosaurus_died")
	
	if Constants.DEBUG_MODE:
		print("💀 Brontosaurus died!")
	
	queue_free()

func is_mounted() -> bool:
	"""Prüft ob der Brontosaurus gerade geritten wird."""
	return current_state == State.MOUNTED
