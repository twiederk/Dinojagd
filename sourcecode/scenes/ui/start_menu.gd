class_name StartMenu
extends Control

@onready var start_button = $CenterContainer/VBoxContainer/StartButton


func _ready():
	start_button.grab_focus()


func _on_start_game_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


func _on_quit_button_pressed():
	get_tree().quit()
