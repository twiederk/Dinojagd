extends Node2D

# Item-Szene preload
var item_scene = preload("res://scenes/items/Item.tscn")

# Spawn Parameter
var spawn_count_per_type: int = Constants.SPAWN_COUNT_PER_ITEM_TYPE
var spawn_radius: float = Constants.SPAWN_RADIUS
var check_interval: float = Constants.SPAWN_CHECK_INTERVAL

# Timer für Respawn
var spawn_timer: float = 0.0

# Referenz zum Player
var player: CharacterBody2D = null

# Alle gespawnten Items tracken
var spawned_items: Dictionary = {}  # ItemType -> Array[Item]

func _ready() -> void:
	# Player finden
	player = get_tree().root.find_child("Player", true, false)
	if not player:
		push_error("Player not found! Make sure Player is named 'Player'")
		return
	
	# Initial Items spawnen
	_spawn_initial_items()
	
	# Timer initialisieren
	spawn_timer = check_interval
	
	if Constants.DEBUG_MODE:
		print("✓ ItemSpawner initialized")

func _spawn_initial_items() -> void:
	"""Spawnt initial alle Items rund um den Player."""
	for item_type in Constants.ItemType.values():
		spawned_items[item_type] = []
		
		for i in range(spawn_count_per_type):
			_spawn_single_item(item_type)

func _spawn_single_item(item_type: int) -> void:
	"""Spawnt ein einzelnes Item im Spawn-Radius um den Player."""
	if not player:
		return
	
	# Zufällige Position im Spawn-Radius (um den Player herum)
	var angle = randf() * TAU  # 0 - 2π
	var distance = randf_range(100, spawn_radius)
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	
	# Item-Szene instanzieren
	var item = item_scene.instantiate()
	item.global_position = spawn_pos
	item.item_type = item_type
	
	# Als Child hinzufügen
	add_child(item)
	
	# In Liste tracken
	spawned_items[item_type].append(item)
	
	if Constants.DEBUG_MODE:
		var item_name = Constants.ITEM_DATA[item_type]["display_name"]
		print("  → Spawned %s at %s" % [item_name, spawn_pos])

func _process(delta: float) -> void:
	# Timer für Respawn-Check
	spawn_timer -= delta
	
	if spawn_timer <= 0:
		_check_and_respawn_items()
		spawn_timer = check_interval

func _check_and_respawn_items() -> void:
	"""Prüft ob Items fehlen und spawnt Ersatz."""
	if not player:
		return
	
	for item_type in Constants.ItemType.values():
		var count = spawned_items[item_type].size()
		
		# Entferne Items die zu weit weg sind
		for i in range(spawned_items[item_type].size() - 1, -1, -1):
			var item = spawned_items[item_type][i]
			if item and player:
				var distance = item.global_position.distance_to(player.global_position)
				if distance > Constants.MAX_DISTANCE_FROM_PLAYER:
					if item:
						item.queue_free()
					spawned_items[item_type].remove_at(i)
		
		# Items nachspawnen falls benötigt
		while spawned_items[item_type].size() < spawn_count_per_type:
			_spawn_single_item(item_type)

func get_spawned_item_count() -> int:
	"""Gibt die Gesamtzahl der aktuell gespawnten Items zurück."""
	var total = 0
	for item_array in spawned_items.values():
		total += item_array.size()
	return total
