extends CanvasLayer

var Constants = preload("res://scripts/constants.gd")

# UI References
var inventory_labels: Dictionary = {}

@onready var inventory_container = $PanelContainer/VBoxContainer/InventoryGrid

func _ready() -> void:
	# Inventar-Labels finden/erstellen
	_setup_inventory_display()
	
	if Constants.DEBUG_MODE:
		print("✓ HUD initialized")

func _setup_inventory_display() -> void:
	"""Erstellt oder findet die Inventory-Label-Elemente."""
	# Labels für jedes Item-Type erstellen
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	
	for item_type in Constants.ItemType.values():
		var item_name = Constants.ITEM_DATA[item_type]["display_name"]
		
		# Container pro Item
		var item_container = VBoxContainer.new()
		
		# Label mit Item-Name und Count
		var label = Label.new()
		label.text = "%s: 0" % item_name
		label.add_theme_font_size_override("font_size", 16)
		
		item_container.add_child(label)
		hbox.add_child(item_container)
		
		# Speichern für später
		inventory_labels[item_type] = label
	
	# HBox zum Container hinzufügen
	if inventory_container:
		for child in inventory_container.get_children():
			child.queue_free()
		inventory_container.add_child(hbox)

func update_inventory(inventory: Dictionary) -> void:
	"""Aktualisiert die Anzeige des Inventars."""
	for item_type in Constants.ItemType.values():
		if item_type in inventory_labels:
			var count = inventory.get(item_type, 0)
			var item_name = Constants.ITEM_DATA[item_type]["display_name"]
			inventory_labels[item_type].text = "%s: %d" % [item_name, count]

func update_game_status(status: String) -> void:
	"""Aktualisiert die Spielstatus-Anzeige (optional)."""
	# Kann später für Game Over, Score, etc. verwendet werden
	pass
