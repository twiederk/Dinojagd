class_name VersionWidget
extends Control

@onready var version_label = $VersionLabel


func _ready():
	version_label.text = " Version: " + ProjectSettings.get_setting("application/config/version")
