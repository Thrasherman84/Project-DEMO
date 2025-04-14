extends CharacterBody3D

@onready var pivot := $Pivot
@onready var spring_arm := $Pivot/SpringArm3D
@onready var camera := $Pivot/SpringArm3D/Camera3D
@onready var character_mesh := $xBot_idle/Skeleton3D/Beta_Joints  # Reference to MeshInstance3D
@onready var anim_player := $xBot_idle/AnimationPlayer  # Reference to AnimationPlayer
@onready var skeleton := $xBot_idle/Skeleton3D  # Reference to Skeleton3D
@onready var animation_tree : AnimationTree = $Char_FemaleA_01/AnimationTree # %AnimationTree
#%GeneralSkeleton

const SPEED = 5.0
const JUMP_VELOCITY = 4
@export var mouse_sensitivity := 0.005
const GRAVITY = -9.8
@export var tilt_limit := deg_to_rad(75)

var input_vec

var pitch := 0.0
var rotation_speed := 5.0  # Adjust this to make the character turn faster/slower
var is_jumping = false
var is_running = false
#var jump_in_progress = false


var is_on_skateboard = false 
var is_pushing = false 
var is_falling = false
var is_dashing = false 
var is_starting_jump = false 
var is_on_floor_var = false 
var is_idle = false 
var double_jump_enabled = true
var playback : AnimationNodeStateMachinePlayback
 



func _ready():
	# Decouple the pivot from inheriting the character’s rotation.
	# This makes the pivot (and thus the camera) independent.
	print("Player ready")
	pivot.top_level = true
	print("animation_tree : ", animation_tree)
	print("animation_tree ref : ", %AnimationTree)
	print("GeneralSkeleton ref : ", %GeneralSkeleton)
	print("Char_FemaleA_01 ref : ", $Char_FemaleA_01)
	print("Char_FemaleA_01 ref : ", $Char_FemaleA_01/AnimationTree)
	
	playback = animation_tree.get("parameters/SkateStateMachine/playback")
	
	update_skate_blend_parameters()
	animation_tree.active = true

func update_animation_parameters():
	#print("update_animation_parameters")
	if (velocity == Vector3.ZERO):
		animation_tree["parameters/StateMachine/conditions/is_idle"] = true
		animation_tree["parameters/StateMachine/conditions/is_moving"] = false
	else:
		animation_tree["parameters/StateMachine/conditions/is_idle"] = false
		animation_tree["parameters/StateMachine/conditions/is_moving"] = true
		
	if Input.is_action_just_pressed("Jump"):
		animation_tree["parameters/StateMachine/conditions/is_jumping"] = true
		await is_on_floor()
	else:
		animation_tree["parameters/StateMachine/conditions/is_jumping"] = false
		
		
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
		animation_tree["parameters/SkateStateMachine/conditions/is_jumping"] = is_starting_jump
		animation_tree["parameters/SkateStateMachine/conditions/is_falling"] = is_falling
	
		

func update_skate_blend_parameters():
	animation_tree["parameters/SkatingBlend/blend_amount"] = 1.0 if is_on_skateboard else 0.0
	#print("Toggle is_on_skateboard :" , is_on_skateboard)
	#"parameters/SkatingBlend/blend_amount"

func _process(delta):
	#update_skate_blend_parameters()
	
	if is_on_skateboard:
		update_skating_animation_parameters()
	else:
		update_animation_parameters()
	
	print("is_starting_jump: " , playback.get_current_node())			
	is_starting_jump = false 

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Mouse controls only the pivot (camera) rotation.
		pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -tilt_limit, tilt_limit)
		spring_arm.rotation.x = pitch

func _physics_process(delta: float) -> void:
	is_on_floor_var = is_on_floor()
	if is_on_floor_var:
		double_jump_enabled = true 
	
	
	is_falling = not is_on_floor_var and velocity.y  <= -2
	
	
	var current_basis = pivot.global_transform.basis
	pivot.global_transform = Transform3D(current_basis, global_transform.origin)
	# Apply gravity
	if not is_on_floor_var:
		velocity.y += GRAVITY * delta

	# Get movement input (these actions should be defined only for movement)
	input_vec = Input.get_vector("Left", "Right", "Forward", "Backward")
	
	is_pushing = is_on_floor_var and input_vec.length() > 0 
	is_idle = is_on_floor_var and not is_pushing
	
	#print("is_pushing: " , is_pushing)
	
	#if character is grounded + skating + toggle pressed -> transition to not skating 
	# if character is grounded + not skating + pushing -> transition to skating 
	#if character is grounded + skating + velocity is too low -> transition to not skating 
	if Input.is_action_just_pressed("ToggleSkateboard"):
		print("ToggleSkateboard pressed:")
		if is_on_skateboard:
			if is_on_floor_var:
				is_on_skateboard = false 
				update_skate_blend_parameters()
				
		else:
			if is_on_floor_var and   is_pushing:
				is_on_skateboard = true
				update_skate_blend_parameters()
	else:
		if is_on_skateboard:
			if is_on_floor_var and velocity.length()  < 0.5:
				is_on_skateboard = false 
				update_skate_blend_parameters()
				
		
		
			
	
	# Use the pivot's yaw as the camera's horizontal orientation.
	var cam_yaw = pivot.rotation.y
	var move_dir = Vector3(input_vec.x, 0, input_vec.y).rotated(Vector3.UP, cam_yaw).normalized()
	
	# Move the character based on movement input.
	if move_dir.length() > 0:
		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED
		# Calculate the target rotation for the character to face move_dir.
		var target_yaw = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * rotation_speed)

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	if Input.is_action_just_pressed("Jump") and not is_starting_jump:
		if is_on_floor_var:			
			#double_jump_enabled
			print("Jump pressed:")		
			is_starting_jump = true 
			is_pushing = false 
			is_idle = false 
			velocity.y = JUMP_VELOCITY
		else: 
			if double_jump_enabled:
				print("Double jump pressed:")	
				playback.start("skateboard_jumping_up", true) # if second argument reset = true, will start from begin.
				is_starting_jump = true 
				is_pushing = false 
				is_idle = false 				
				velocity.y += JUMP_VELOCITY
				double_jump_enabled = false 
	
	if Input.is_action_just_pressed("Run"):
		if	is_on_skateboard:
			is_dashing = true 
			is_starting_jump = false
			is_pushing = false 
			is_idle = false 
			$DashAnimationTimer.start()
			
			
				
				
	
	
	move_and_slide()


func _on_dash_animation_timer_timeout() -> void:
	is_dashing = false 
