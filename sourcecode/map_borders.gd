class_name MapBorders
extends Node2D

@onready var north_border = $NorthBorder
@onready var south_border = $SouthBorder
@onready var west_border = $WestBorder
@onready var east_border = $EastBorder


func set_borders(north_limit: float, south_limit: float, west_limit: float, east_limit: float) -> void:
	north_border.position = Vector2(0, north_limit)
	west_border.position = Vector2(west_limit, 0)
	south_border.position = Vector2(0, south_limit)
	east_border.position = Vector2(east_limit, 0)
