extends Node2D

var Constants = preload("res://scripts/constants.gd")

@onready var player = $Player
@onready var item_spawner = $ItemSpawner
@onready var hud = $HUD
@onready var t_rex = $TRex
@onready var brontosaurus = $Brontosaurus
@onready var map_borders: MapBorders = $MapBorders
@onready var erdboden_ebene: TileMapLayer = $ErdbodenEbene


func _ready() -> void:
	if player and hud:
		player.item_collected.connect(_on_player_item_collected)
		player.health_changed.connect(_on_player_health_changed)
		player.player_died.connect(_on_player_died)
	
	if t_rex and player:
		t_rex.health_changed.connect(_on_trex_health_changed)
		t_rex.enemy_died.connect(_on_trex_died)
	
	if brontosaurus and player:
		brontosaurus.player_nearby.connect(_on_brontosaurus_player_nearby)
		brontosaurus.player_left.connect(_on_brontosaurus_player_left)
		brontosaurus.brontosaurus_died.connect(_on_brontosaurus_died)
	
	# Alle Loren finden und Signals verbinden
	_connect_all_lores()
	
	if hud and player:
		hud.update_inventory(player.get_inventory())
	
	_setup_limits_and_borders()


func _setup_limits_and_borders() -> void:
	var tile_map_used_rect = erdboden_ebene.get_used_rect()
	var tile_size = erdboden_ebene.tile_set.tile_size
	var north_limit = tile_map_used_rect.position.y * tile_size.y
	var south_limit = (tile_map_used_rect.position.y + tile_map_used_rect.size.y) * tile_size.y
	var west_limit = tile_map_used_rect.position.x * tile_size.x
	var east_limit = (tile_map_used_rect.position.x + tile_map_used_rect.size.x) * tile_size.x
	
	map_borders.set_borders(north_limit, south_limit, west_limit, east_limit)
	player.set_camera_limits(north_limit, south_limit, west_limit, east_limit)
	brontosaurus.set_camera_limits(north_limit, south_limit, west_limit, east_limit)
	
	# Kamera-Limits für alle Loren setzen
	for lore_node in get_tree().get_nodes_in_group("lore"):
		if lore_node.has_node("Camera2D"):
			var cam = lore_node.get_node("Camera2D")
			cam.set_limit(SIDE_LEFT, int(west_limit))
			cam.set_limit(SIDE_RIGHT, int(east_limit))
			cam.set_limit(SIDE_TOP, int(north_limit))
			cam.set_limit(SIDE_BOTTOM, int(south_limit))


func _on_player_item_collected(item_type: int, count: int) -> void:
	if hud:
		hud.update_inventory(player.get_inventory())
	
	var item_name = Constants.ITEM_DATA[item_type]["display_name"]
	print("→ HUD updated: %s x%d" % [item_name, count])


func _on_player_health_changed(hp: int, max_hp: int) -> void:
	print("  → Player Health: %d/%d" % [hp, max_hp])


func _on_player_died() -> void:
	print("💀 GAME OVER - Player died!")


func _on_trex_health_changed(hp: int, max_hp: int) -> void:
	print("  → T-Rex Health: %d/%d" % [hp, max_hp])


func _on_trex_died() -> void:
	print("🦖 T-Rex eliminated!")


func _on_brontosaurus_player_nearby(bronto: CharacterBody2D) -> void:
	if player:
		player.set_nearby_brontosaurus(bronto)


func _on_brontosaurus_player_left() -> void:
	if player:
		player.clear_nearby_brontosaurus()


func _on_brontosaurus_died() -> void:
	print("🦕 Brontosaurus died!")
	if player:
		player.clear_nearby_brontosaurus()


func _connect_all_lores() -> void:
	"""Verbindet Signals aller Loren in der Szene."""
	for lore_node in get_tree().get_nodes_in_group("lore"):
		if player:
			lore_node.player_nearby.connect(_on_lore_player_nearby)
			lore_node.player_left.connect(_on_lore_player_left)
			if Constants.DEBUG_MODE:
				print("✓ Lore verbunden: %s" % lore_node.name)


func _on_lore_player_nearby(lore_ref: CharacterBody2D) -> void:
	if player:
		player.set_nearby_lore(lore_ref)


func _on_lore_player_left() -> void:
	if player:
		player.clear_nearby_lore()
