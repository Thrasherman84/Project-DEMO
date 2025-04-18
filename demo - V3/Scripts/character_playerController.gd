extends CharacterBody3D

@onready var pivot := $Pivot
@onready var spring_arm := $Pivot/SpringArm3D

@export var animation_tree := AnimationTree

@onready var main_scene := get_tree().root.get_child(0)

# Apply constant offset to pivot de-coupled position
@export var pivot_offset := Vector3(0.0, 1.7, 0.0)  # Default offset (y=1.7 places pivot at head level)

const SPEED = 5.0
const SPEED_RUN = 10.0

@export var jump_velocity := 4
@export var mouse_sensitivity := 0.005
const GRAVITY = -9.8
@export var tilt_limit := deg_to_rad(75)

var is_paused := false
var pitch := 0.0
var rotation_speed := 5.0  # Adjust this to make the character turn faster/slower
var is_jumping = false
var is_running = false
var jump_in_progress = false

var is_on_skateboard = false 
var is_pushing = false 
var is_falling = false
var is_dashing = false 
#var is_starting_jump = false 
var is_on_floor_var = false 
var is_idle = false 
var double_jump_enabled = true
var skatePlayback : AnimationNodeStateMachinePlayback
var walkPlayback : AnimationNodeStateMachinePlayback
var input_vec : Vector2

var can_dash = true 


func _ready():
	# Decouple the pivot from inheriting the character’s rotation.
	# This makes the pivot (and thus the camera) independent.
	pivot.top_level = true
	animation_tree.active = true
	
	skatePlayback = $Char_FemaleA_01/AnimationTree.get("parameters/SkateStateMachine/playback")
	walkPlayback = $Char_FemaleA_01/AnimationTree.get("parameters/StateMachine/playback")
	#%AnimationTree
	main_scene.connect( "paused_state", Callable( self, "_on_paused_state") )
	%PauseMenu.connect( "state_change", Callable(self, "_on_paused_state"))
	
	print("animation_tree :" , animation_tree)
	print("$Char_FemaleA_01/AnimationTree" , $Char_FemaleA_01/AnimationTree)
	#print("animation_tree.get" , animation_tree.get("parameters/StateMachine/playback"))

# For movement -to- BlendSpace2D blend_position vec2
#   X axis = left/right (-1 to 1)
#   Y axis = forward/backward (-1 to 1)
#   (0,0) = idle

func update_animation_parameters():

	if (velocity == Vector3.ZERO):
		animation_tree["parameters/StateMachine/conditions/is_idle"] = true
		animation_tree["parameters/StateMachine/conditions/is_moving"] = false
	else:
		animation_tree["parameters/StateMachine/conditions/is_idle"] = false
		animation_tree["parameters/StateMachine/conditions/is_moving"] = true
		
	# User Input
	var input_vec = Input.get_vector("Left", "Right", "Forward", "Backward")
	

	var speed_factor = 1.0 if is_running else 0.5
	if input_vec.length() > 0:
		animation_tree["parameters/StateMachine/movementBlender/blend_position"] = input_vec * speed_factor 
	else:
		animation_tree["parameters/StateMachine/movementBlender/blend_position"] = Vector2.ZERO 


	if Input.is_action_just_pressed("Jump"):
		animation_tree["parameters/StateMachine/conditions/is_jumping"] = true
		await is_on_floor()
	else:
		animation_tree["parameters/StateMachine/conditions/is_jumping"] = false

		
	# If hit
	var gotHit = false
	if gotHit:
		animation_tree["parameters/StateMachine/conditions/is_jumping"] = false
	###

func update_skate_blend_parameters():
	animation_tree["parameters/SkatingBlend/blend_amount"] = 1.0 if is_on_skateboard else 0.0

func update_skating_animation_parameters():
	#print("update_skating_animation_parameters")
		
	if is_dashing:
		animation_tree["parameters/SkateStateMachine/conditions/is_dashing"] = true 
		animation_tree["parameters/SkateStateMachine/conditions/is_idle"] = false # is_on_floor_var and not is_pushing
		animation_tree["parameters/SkateStateMachine/conditions/is_pushing"] = false
		animation_tree["parameters/SkateStateMachine/conditions/is_jumping"] = false
		animation_tree["parameters/SkateStateMachine/conditions/is_falling"] = false
	else:
		animation_tree["parameters/SkateStateMachine/conditions/is_dashing"] = false 
		animation_tree["parameters/SkateStateMachine/conditions/is_idle"] = is_idle # is_on_floor_var and not is_pushing
		animation_tree["parameters/SkateStateMachine/conditions/is_pushing"] = is_pushing
		animation_tree["parameters/SkateStateMachine/conditions/is_jumping"] = jump_in_progress
		animation_tree["parameters/SkateStateMachine/conditions/is_falling"] = is_falling
	
	
	



func _process(delta):
	if( is_paused ):
		return
		
	if is_on_skateboard:
		update_skating_animation_parameters()
	else:
		update_animation_parameters()
		
	#print("current skateboard node: " , skatePlayback.get_current_node())		

func _unhandled_input(event: InputEvent) -> void:
	if( is_paused ):
		return
	if event is InputEventMouseMotion:
		# Mouse controls only the pivot (camera) rotation.
		pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -tilt_limit, tilt_limit)
		spring_arm.rotation.x = pitch

func _physics_process(delta: float) -> void:
	if( is_paused ):
		return

	var current_basis = pivot.global_transform.basis
	

	# Apply pivot offset
	var offset_position = global_transform.origin + pivot_offset
	pivot.global_transform = Transform3D(current_basis, offset_position)
	
	is_on_floor_var = is_on_floor()
	if is_on_floor_var:
		double_jump_enabled = true 
	
	is_falling = not is_on_floor_var and velocity.y  <= -2
	#if is_on_floor_var or is_falling:
	#	jump_in_progress = false 
	
	
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Get movement input (these actions should be defined only for movement)
	input_vec = Input.get_vector("Left", "Right", "Forward", "Backward")

	# Check if running (Shift key)
	is_running = Input.is_action_pressed("Run")
	var current_speed = SPEED_RUN if is_running else SPEED
	
	is_pushing = is_on_floor_var and input_vec.length() > 0 
	is_idle = is_on_floor_var and not is_pushing
	
	#print("is_pushing: " , is_pushing)		
	
	# Use the pivot's yaw as the camera's horizontal orientation.
	var cam_yaw = pivot.rotation.y
	var move_dir = Vector3(input_vec.x, 0, input_vec.y).rotated(Vector3.UP, cam_yaw).normalized()
	

	# Move the character based on movement input.
	if move_dir.length() > 0:
		if is_on_skateboard:
			velocity.x += move_dir.x * 0.3
			velocity.z += move_dir.z * 0.3
		else:
			velocity.x = move_dir.x * current_speed
			velocity.z = move_dir.z * current_speed
		# Calculate the target rotation for the character to face move_dir.
		var target_yaw = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * rotation_speed)

			
	else:
		if is_on_skateboard:
			pass 
		else:
			
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)
		
	if is_on_skateboard:
		# always slowly decelerate, if on skateboard:
		velocity.x *= 0.985
		velocity.z *= 0.985
		
		
	if Input.is_action_just_pressed("ToggleSkateboard"):
		#print("ToggleSkateboard pressed:")
		if is_on_floor_var:
			print("Skateboard toggled:")
			is_on_skateboard = not is_on_skateboard
			update_skate_blend_parameters()
		
	
	jump_in_progress = false 
	if Input.is_action_just_pressed("Jump") and not jump_in_progress:		
		if is_on_floor_var:
			jump_in_progress = true 		
			velocity.y += jump_velocity
		else:
			if double_jump_enabled:
				jump_in_progress = true 
				velocity.y += jump_velocity
				double_jump_enabled = false 
				if is_on_skateboard:
					skatePlayback.start("skateboard_jumping_up", true)
				else:
					walkPlayback.start("jump", true)
	if jump_in_progress:
		is_pushing = false 
		is_idle = false 	
		
					
					
	if Input.is_action_just_pressed("Run"):
		if	can_dash and is_on_skateboard:
			
			velocity.x = move_dir.x * SPEED_RUN*2
			velocity.z = move_dir.z * SPEED_RUN*2
						
			can_dash = false 
			is_dashing = true 
			jump_in_progress = false
			#is_starting_jump = false
			is_pushing = false 
			is_idle = false 
			$DashAnimationTimer.start()			
			$DashCalldownTimer.start()
				
					
					
				
				
	move_and_slide()


func _on_paused_state( state:bool ):
	is_paused = state
	if( is_paused ):
		animation_tree.active = false
		#animation_player.pause()
		#animation_player.playback_speed = 0.0
	else:
		animation_tree.active = true
		#animation_player.play()
		#animation_player.playback_speed = 1.0
		


func _on_dash_animation_timer_timeout() -> void:
	is_dashing = false 


func _on_dash_calldown_timer_timeout() -> void:
	can_dash = true 
