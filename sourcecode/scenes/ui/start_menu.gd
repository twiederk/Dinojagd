class_name StartMenu
extends Control

@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var load_button = $CenterContainer/VBoxContainer/LoadButton


func _ready():
	start_button.grab_focus()


func _on_start_game_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


func _on_quit_button_pressed():
	get_tree().quit()
