extends Node3D

var pause_menu
var cursor_visible := false
var is_paused := false  # <- this needs to be declared at the top, not inside functions

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # optional, to make sure it starts hidden
	$PauseMenu.hide()
	
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):  # Escape
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused  # Toggle the boolean
	$PauseMenu.show()
	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
