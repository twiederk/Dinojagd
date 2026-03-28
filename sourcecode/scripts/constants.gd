extends Node

# ItemType Enum - definiert alle sammelbaren Items
enum ItemType {
	GUN,      # Gewehr - Gewehr.png
	GRASS,    # Gras - Gras.png
	SADDLE,   # Sattel - Sattel.png
	QUAD      # Quad - Quad.png
}

# Item Metadaten - Sprite-Pfade und Properties
const ITEM_DATA = {
	ItemType.GUN: {
		"sprite_path": "res://assets/Gewehr.png",
		"display_name": "Gewehr",
		"collection_radius": 50.0
	},
	ItemType.GRASS: {
		"sprite_path": "res://assets/Gras.png",
		"display_name": "Gras",
		"collection_radius": 50.0
	},
	ItemType.SADDLE: {
		"sprite_path": "res://assets/Sattel.png",
		"display_name": "Sattel",
		"collection_radius": 50.0
	},
	ItemType.QUAD: {
		"sprite_path": "res://assets/Quad.png",
		"display_name": "Quad",
		"collection_radius": 50.0
	}
}

# Player Konstanten
const PLAYER_SPRITE_PATH = "res://assets/Spieler.png"
const PLAYER_SPEED = 200.0
const PLAYER_ACCELERATION = 500.0
const PLAYER_COLLECTION_RADIUS = 80.0

# Spawn & World Konstanten
const SPAWN_RADIUS = 400.0
const SPAWN_COUNT_PER_ITEM_TYPE = 1
const SPAWN_CHECK_INTERVAL = 30.0  # Sekunden bis neues Spawning
const MAX_DISTANCE_FROM_PLAYER = 1000.0  # Items werden entfernt wenn zu weit weg

# Screen & UI Konstanten
const SCREEN_WIDTH = 1280
const SCREEN_HEIGHT = 720

# Debug Flags
const DEBUG_MODE = true
const DRAW_COLLECTION_RADIUS = true
