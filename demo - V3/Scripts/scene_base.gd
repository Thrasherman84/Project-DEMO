extends Node3D

var pause_menu
var cursor_visible := false
var is_paused := false

@export var debug_mode := false

@onready var deliver_route_manager := $"Delivery Routes"

var current_delivery_id = -1
var current_checkpoint_id = -1


func _ready():
	var delivery_routes = deliver_route_manager.get_children()
	for route in delivery_routes:
		route.connect("delivery_started", Callable( self, "_on_delivery_start"))
		route.connect("delivery_finished", Callable( self, "_on_delivery_finished"))
	
	$PauseMenu.connect( "state_change", Callable(self, "_on_pause_state_change"))

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # optional, to make sure it starts hidden
	$PauseMenu.hide()
	
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):  # Escape
		toggle_pause()

# -- -- --

func pauseTimer( state: bool ):
	if( current_delivery_id > -1 ):
		$HUD.pauseTimer( state )
		
func pauseScene():
	$PauseMenu.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func runScene():
	$PauseMenu.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func toggle_pause():
	is_paused = !is_paused
	
	pauseTimer( is_paused )
		
	if is_paused:
		pauseScene()
	else:
		runScene()
	
# -- -- --

		
func _on_pause_state_change( state: bool ):
	is_paused = state 
	if ( state ):
		pauseScene()
	else:
		runScene()
	
	pauseTimer( state )

# -- -- --

func _on_delivery_start( route_id: int ):
	if( debug_mode ):
		print("Started Delivery : ", route_id)
	current_delivery_id = route_id
	$HUD.startTimer()
func _on_delivery_finished( route_id: int ):
	if( debug_mode ):
		print("Finished Delivery : ", current_delivery_id)
	current_delivery_id = -1
	$HUD.stopTimer()
	
