class_name TradingMenu
extends Control

# Referenzen zu den Buttons
@onready var kaufen_sniper_10_button = $CenterContainer/VBoxContainer/HBoxContainer/Kaufen
@onready var kaufen_sniper_24_button = $CenterContainer/VBoxContainer/HBoxContainer2/Kaufen

# Referenz zum Player
var player: Player = null

func _ready() -> void:
	# Player finden
	player = get_tree().root.find_child("Player", true, false)
	
	if not player:
		push_error("Trading Menu: Player not found!")
		return
	
	# Button-Signals verbinden
	kaufen_sniper_10_button.pressed.connect(_on_kaufen_sniper_10_pressed)
	kaufen_sniper_24_button.pressed.connect(_on_kaufen_sniper_24_pressed)
	
	# Menu initial verstecken
	visible = false


func _on_kaufen_sniper_10_pressed() -> void:
	"""Kauft Sniper 10 wenn Spieler genug Coins hat."""
	if player:
		var success = player.buy_sniper_10()
		
		if success:
			print("✅ Sniper 10 gekauft!")
			kaufen_sniper_10_button.disabled = true
			kaufen_sniper_10_button.text = "✓ Besitzt"
		else: 
			print("❌ Kauf fehlgeschlagen: Nicht genug Coins oder bereits besitzt")


func _on_kaufen_sniper_24_pressed() -> void:
	"""Kauft Sniper 24 wenn Spieler genug Coins hat."""
	if player:
		var success = player.buy_sniper_24()
		
		if success:
			print("✅ Sniper 24 gekauft!")
			kaufen_sniper_24_button.disabled = true
			kaufen_sniper_24_button.text = "✓ Besitzt"
		else:
			print("❌ Kauf fehlgeschlagen: Nicht genug Coins oder bereits besitzt")


func show_trading_menu() -> void:
	"""Zeigt das Trading-Menü an und gibt dem Button den Focus."""
	visible = true
	# Gib dem ersten Button den Focus
	kaufen_sniper_10_button.grab_focus()


func hide_trading_menu() -> void:
	"""Versteckt das Trading-Menü."""
	visible = false
