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

# Enemy Enum & Stats
enum EnemyType {
	T_REX
}

# T-Rex Konstanten
const T_REX_SPRITE_PATH = "res://assets/T-Rex.png"
const T_REX_HP = 100
const T_REX_MAX_HP = 100
const T_REX_DAMAGE = 15
const T_REX_SPEED = 150.0
const T_REX_CHASE_SPEED = 180.0
const T_REX_DETECTION_RADIUS = 300.0
const T_REX_DAMAGE_RADIUS = 30.0
const T_REX_DAMAGE_COOLDOWN = 1.0  # Sekunden zwischen Damage Hits

# Player Health
const PLAYER_HP = 100
const PLAYER_MAX_HP = 100
const PLAYER_DAMAGE_COOLDOWN = 1.0

# HealthBar UI
const HEALTHBAR_WIDTH = 60
const HEALTHBAR_HEIGHT = 8
const HEALTHBAR_OFFSET_Y = -40  # Über dem Character

# Debug Flags
const DEBUG_MODE = true
const DRAW_COLLECTION_RADIUS = true
