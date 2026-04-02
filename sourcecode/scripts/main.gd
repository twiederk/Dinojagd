extends Node2D

var Constants = preload("res://scripts/constants.gd")

@onready var player = $Player
@onready var item_spawner = $ItemSpawner
@onready var hud = $HUD
@onready var t_rex = $TRex
@onready var brontosaurus = $Brontosaurus
@onready var lore = $Lore
@onready var map_borders: MapBorders = $MapBorders
@onready var erdboden_ebene: TileMapLayer = $ErdbodenEbene


func _ready() -> void:
	if not OS.has_feature("editor"):
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN	
		
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
	
	if lore and player:
		lore.player_nearby.connect(_on_lore_player_nearby)
		lore.player_left.connect(_on_lore_player_left)
	
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
	if lore and lore.has_node("Camera2D"):
		lore.get_node("Camera2D").set_limit(SIDE_LEFT, int(west_limit))
		lore.get_node("Camera2D").set_limit(SIDE_RIGHT, int(east_limit))
		lore.get_node("Camera2D").set_limit(SIDE_TOP, int(north_limit))
		lore.get_node("Camera2D").set_limit(SIDE_BOTTOM, int(south_limit))


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


func _on_lore_player_nearby(lore_ref: CharacterBody2D) -> void:
	if player:
		player.set_nearby_lore(lore_ref)


func _on_lore_player_left() -> void:
	if player:
		player.clear_nearby_lore()
