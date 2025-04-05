extends Control

func _ready():
	$PauseMenu.hide()
	pass
func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(("res://main_root.tscn"))

func _on_quit_button_pressed():
	get_tree().quit()


func _on_options_button_pressed() -> void:
	print("Options clicked")
