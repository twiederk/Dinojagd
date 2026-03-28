extends Node2D

var Constants = preload("res://scripts/constants.gd")

# References
@onready var player = $Player
@onready var item_spawner = $ItemSpawner
@onready var hud = $HUD

func _ready() -> void:
	# Verbinde Player-Signal mit HUD
	if player and hud:
		player.item_collected.connect(_on_player_item_collected)
	
	# Initial Inventar anzeigen
	if hud and player:
		hud.update_inventory(player.get_inventory())
	
	print("✓ Main scene initialized")
	print("  Items spawned: %d" % item_spawner.get_spawned_item_count())


func _process(delta: float) -> void:
	# Optional: Debug-Info anzeigen
	if Input.is_action_just_pressed("ui_select"):  # Space
		var count = item_spawner.get_spawned_item_count()
		print("Debug: %d Items in world" % count)


func _on_player_item_collected(item_type: int, count: int) -> void:
	"""Wird aufgerufen wenn der Spieler ein Item sammelt."""
	if hud:
		hud.update_inventory(player.get_inventory())
	
	var item_name = Constants.ITEM_DATA[item_type]["display_name"]
	print("→ HUD updated: %s x%d" % [item_name, count])
