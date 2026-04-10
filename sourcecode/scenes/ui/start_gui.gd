class_name StartGUI
extends CanvasLayer


func _init() ->  void:
	randomize()


func _ready() -> void:
	if not OS.has_feature("editor"):
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN	
