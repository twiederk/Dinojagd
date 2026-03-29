extends Node2D

var Constants = preload("res://scripts/constants.gd")

# References
@onready var player = $Player
@onready var item_spawner = $ItemSpawner
@onready var hud = $HUD
@onready var t_rex = $TRex
@onready var brontosaurus = $Brontosaurus

func _ready() -> void:
	# Verbinde Player-Signal mit HUD
	if player and hud:
		player.item_collected.connect(_on_player_item_collected)
		player.health_changed.connect(_on_player_health_changed)
		player.player_died.connect(_on_player_died)
	
	# Verbinde T-Rex Signale
	if t_rex and player:
		t_rex.health_changed.connect(_on_trex_health_changed)
		t_rex.enemy_died.connect(_on_trex_died)
	
	# Verbinde Brontosaurus Signale (Phase 4)
	if brontosaurus and player:
		brontosaurus.player_nearby.connect(_on_brontosaurus_player_nearby)
		brontosaurus.player_left.connect(_on_brontosaurus_player_left)
		brontosaurus.brontosaurus_died.connect(_on_brontosaurus_died)
	
	# Initial Inventar anzeigen
	if hud and player:
		hud.update_inventory(player.get_inventory())
	
	print("✓ Main scene initialized with T-Rex and Brontosaurus")
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

func _on_player_health_changed(hp: int, max_hp: int) -> void:
	"""Wird aufgerufen wenn Player Schaden nimmt."""
	print("  → Player Health: %d/%d" % [hp, max_hp])

func _on_player_died() -> void:
	"""Wird aufgerufen wenn Player stirbt."""
	print("💀 GAME OVER - Player died!")
	# Später: GameOver-Szene anzeigen

func _on_trex_health_changed(hp: int, max_hp: int) -> void:
	"""Wird aufgerufen wenn T-Rex Schaden nimmt."""
	print("  → T-Rex Health: %d/%d" % [hp, max_hp])

func _on_trex_died() -> void:
	"""Wird aufgerufen wenn T-Rex stirbt."""
	print("🦖 T-Rex eliminated!")

# ==================== Brontosaurus Callbacks (Phase 4) ====================

func _on_brontosaurus_player_nearby(bronto: CharacterBody2D) -> void:
	"""Wird aufgerufen wenn Player in Brontosaurus-Reichweite kommt."""
	if player:
		player.set_nearby_brontosaurus(bronto)

func _on_brontosaurus_player_left() -> void:
	"""Wird aufgerufen wenn Player Brontosaurus-Reichweite verlässt."""
	if player:
		player.clear_nearby_brontosaurus()

func _on_brontosaurus_died() -> void:
	"""Wird aufgerufen wenn Brontosaurus stirbt."""
	print("🦕 Brontosaurus died!")
	if player:
		player.clear_nearby_brontosaurus()
