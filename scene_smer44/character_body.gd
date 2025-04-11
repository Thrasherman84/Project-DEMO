extends RigidBody3D

#when you add a colon, godot will keep a track of what kind of value the variable is holding 
#speed
var mouse_sensitivity := 0.002
var mouse_sensitivity_vertical := 0.0003 
#stores horizontal mouse input:
var twist_input := 0.0
#stover vertical mouse input:
var pitch_input := 0.0 
#TODO - actually, character must be directed to what direction he is moving 
var character_facing_lerp_factor = 5
var character_side_rotate_lerp_factor = 30

var jump_force = 500
var floors_contacts : int = 0
var double_jump_enabled = true
var dash_enabled = true
var ducking = false

var inertion_speed = 1200
var inertion_ducking_speed = inertion_speed * 10
var dash_speed = 50
var input : Vector3

var clamp_vertical_rotation_rad = 1.3

var horizontal_input : Vector2
var character_minimum_speed_for_facing_squared = 1


var normal_damp = 0.0
var ducking_damp = 10.0

@export var xbot: Node 
var atree : AnimationTree

func _ready() -> void:
	#set mouse to be invisible and centered:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	linear_damp = normal_damp
	atree = $"CharacterVisuals/X Bot/AnimationTree"
	atree.active = true
	#print(atree)
	


func _physics_process(delta: float) -> void:
	"""
	Here, some physics specific process will be updated in fixed frame rate, right?
	What should be put here?
	"""
	if ducking:
		apply_central_force(input  * inertion_ducking_speed * delta) 
	else:
		apply_central_force(input  * inertion_speed * delta) 
	

func _process(delta: float) -> void:
	"""
	We update all inputs ped normal frames, right?
	"""
	update_input_camera_rotation()
	update_input_duck()
	update_input_horizontal_relative_to_camera(delta)
	update_input_dash()
	update_input_jump()
	handle_ducking_lean(delta)
	update_input_exit()
	
# is called, if this event is not handled by another script:
func _unhandled_input(event: InputEvent) -> void:
	"""
		This is called, if event is not handled by another script.
		If it is mouse motion, assign mouse motion inputs
		for some reason, making them accumulators like 
		twist_input += - event.relative.x * mouse_sensitivity
		works wrong.
	"""
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = - event.relative.x * mouse_sensitivity
			pitch_input =  event.relative.y * mouse_sensitivity_vertical
			
func update_input_camera_rotation():
	$CameraPivot.global_rotation.y += twist_input
	$CameraPivot.global_rotation.x += pitch_input
	#$CameraPivot.global_rotation_degrees.x = clamp($CameraPivot.global_rotation_degrees.x, -80,80)
	# this are values in radians:
	$CameraPivot.global_rotation.x = clamp($CameraPivot.global_rotation.x , -clamp_vertical_rotation_rad,clamp_vertical_rotation_rad)
	twist_input = 0.0
	pitch_input = 0.0
	#causes wrong behaviour:
	#$CameraPivot.rotate_y(twist_input)
	#$CameraPivot.rotate_x(pitch_input)
	
func update_input_wasd_absolute(delta: float):	
	#like that, it adds absolute movement:
	horizontal_input = Input.get_vector("left", "right", "forward", "backward")
	input = Vector3.ZERO
	input.x = horizontal_input.x 
	input.z = horizontal_input.y 
		
	
	
func update_input_dash():
	'''
	Dash is happening without previous inertion: new speed is just set 
	'''
	if dash_enabled and Input.is_action_just_pressed("dash"):
		linear_velocity = input * dash_speed
		dash_enabled = false 
		$DashTimer.start()

func update_input_horizontal_relative_to_camera(delta: float):	
	#like that, it adds absolute movement:
	horizontal_input = Input.get_vector("right", "left",  "backward", "forward")	
	if floors_contacts > 0 and horizontal_input.length() > 0:
		input = Vector3.ZERO
		input.x = horizontal_input.x 
		input.z = horizontal_input.y 
			
		#rotate input by camera facing horizontally:
		input = input.rotated(Vector3.UP,$CameraPivot.global_rotation.y)
		#apply_central_force(input  * 1200 * delta)	
		#rotate character to facing by input:
		# this part is better in Unity since you can just assign"Forward" vector of a node there

		#this works not smoothly:
		#$CharacterVisuals.look_at($CharacterVisuals.global_position-input)
		face_character_by_speed(delta)
	
func face_character_by_input(delta:float):
	"""
	Use that if you want to face character by input( means after rotating input by camera forward look)
	"""
	var input_rotation = atan2(input.x,input.z)
	smooth_rotate_horizontally($CharacterVisuals,input_rotation,character_facing_lerp_factor*delta )
	
func face_character_by_speed(delta:float):
	"""
	But actually here you would like to face character forward by his current absolute speed:
	"""
	if linear_velocity.length_squared() > character_minimum_speed_for_facing_squared:
		var input_rotation = atan2(linear_velocity.x,linear_velocity.z)
		smooth_rotate_horizontally($CharacterVisuals,input_rotation,character_facing_lerp_factor*delta )	
	
		
		
func smooth_rotate_horizontally(node,new_rotation_y,amount):
	# just lerp, will rotate backwards for some angles:
	
	node.rotation.y = lerp_angle(node.rotation.y,new_rotation_y,amount)
	
func smooth_rotate_sideways(node,new_rotation_z,amount):
	# just lerp, will rotate backwards for some angles:	
	node.rotation.z = lerp_angle(node.rotation.z,new_rotation_z,amount)
	
	
func update_input_jump():
	if Input.is_action_just_pressed("jump"):
		if floors_contacts > 0:
			apply_central_force(Vector3.UP  * jump_force)	
		elif double_jump_enabled:
			double_jump_enabled = false 
			apply_central_force(Vector3.UP  * jump_force)	
			

func update_input_duck():
	#print("update_input_duck: linear_damp = " , linear_damp)
	if Input.is_action_just_pressed("duck"):
		ducking = true 
		linear_damp = ducking_damp
		
	if Input.is_action_just_released("duck"):
		ducking = false 		
		linear_damp = normal_damp
		#print("update_input_duck: linear_damp = " , linear_damp)
		
func handle_ducking_lean(delta:float):
	var sideways_lerp_factor = clamp(character_side_rotate_lerp_factor*delta ,0,1)
	if ducking:
		if  horizontal_input.length()  > 0 :			
			#clip speed, rotate and slide:
			#TODO - currently, i gonna rotate only character visuals.
			var lean_direction = -horizontal_input.x 
			smooth_rotate_sideways($CharacterVisuals, lean_direction,sideways_lerp_factor)
			#as well as rotate current linear velocity really fast:
			#this just setting linear velocity like that does not work:
			
			#linear_velocity = linear_velocity.rotated(Vector3.UP, horizontal_input.x  * delta* 50)
			return 
	smooth_rotate_sideways($CharacterVisuals, 0,sideways_lerp_factor)
	
			
			

		

		

func update_input_exit():
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	



# i guess this will support contacts with multiple floors.
#you may jump if floors_contacts > 0
func _on_body_entered(body: Node) -> void:
	#print("_on_body_entered: body:", body)
	if body.is_in_group("Floor"):
		
		floors_contacts+=1
		double_jump_enabled = true 
		#print("_on_body_entered: floor contacts increased:", floors_contacts)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Floor"):
		floors_contacts-=1
		


func _on_dash_timer_timeout() -> void:
	#print("_on_dash_timer_timeout:")
	dash_enabled = true
	
	
	
	
	
	"""
from 
https://gist.github.com/NovemberDev/6d78a07c9274ee25a6e9c16c9aad1fb9

# These helper functions smoothly look at any object in 2D space.
# To avoid wrong rotations over +180 degrees, lerp_angle is used.
# Everything happens in global space, so the rotations should be applied properly.

func look_at_position(source: Node2D, target: Vector2, delta: float):
	var direction = target - source.global_position
	return lerp_angle(source.global_rotation, direction.angle(), delta)

func look_at_node(source: Node2D, target: Node2D, delta: float):
	var direction = target.global_position - source.global_position
	return lerp_angle(source.global_rotation, direction.angle(), delta)

"""
	
