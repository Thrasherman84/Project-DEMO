extends Control

signal state_change

@export
var starting_scene : String

func _ready():
	pass

func _on_start_button_pressed() -> void:
	#get_tree().change_scene_to_packed(starting_scene)
	#get_tree().change_scene_to_file(starting_scene)
	state_change.emit( false )

func _on_quit_button_pressed():
	# Quit the game
	get_tree().quit()

func _on_options_button_pressed() -> void:
	print("Options clicked")
