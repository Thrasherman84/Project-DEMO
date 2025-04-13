extends CharacterBody3D

@onready var pivot := $Pivot
@onready var spring_arm := $Pivot/SpringArm3D

@export var animation_tree := AnimationTree


# Apply constant offset to pivot de-coupled position
@export var pivot_offset := Vector3(0.0, 1.7, 0.0)  # Default offset (y=1.7 places pivot at head level)

const SPEED = 5.0
const SPEED_RUN = 10.0

@export var jump_velocity := 4
@export var mouse_sensitivity := 0.005
const GRAVITY = -9.8
@export var tilt_limit := deg_to_rad(75)

var pitch := 0.0
var rotation_speed := 5.0  # Adjust this to make the character turn faster/slower
var is_jumping = false
var is_running = false
var jump_in_progress = false

func _ready():
	# Decouple the pivot from inheriting the character’s rotation.
	# This makes the pivot (and thus the camera) independent.
	pivot.top_level = true
	animation_tree.active = true

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
		
	#if (is_running):
	#	animation_tree["parameters/walkRun/blend_position"] = 1.0
	#else:
	#	animation_tree["parameters/walkRun/blend_position"] = 0.0


	# Get normalized movement direction
	var input_vec = Input.get_vector("Left", "Right", "Forward", "Backward")
	

	# Option 1: Basic implementation
	animation_tree["parameters/StateMachine/movementBlender/blend_position"] = Vector2(input_vec.x, input_vec.y)

	# Option 2: Including running as intensity
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

func _process(delta):
	update_animation_parameters()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Mouse controls only the pivot (camera) rotation.
		pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -tilt_limit, tilt_limit)
		spring_arm.rotation.x = pitch

func _physics_process(delta: float) -> void:

	var current_basis = pivot.global_transform.basis

	# Apply pivot offset
	var offset_position = global_transform.origin + pivot_offset
	pivot.global_transform = Transform3D(current_basis, offset_position)
	



	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Get movement input (these actions should be defined only for movement)
	var input_vec = Input.get_vector("Left", "Right", "Forward", "Backward")

	# Check if running (Shift key)
	is_running = Input.is_action_pressed("Run")
	var current_speed = SPEED_RUN if is_running else SPEED

	# Use the pivot's yaw as the camera's horizontal orientation.
	var cam_yaw = pivot.rotation.y
	var move_dir = Vector3(input_vec.x, 0, input_vec.y).rotated(Vector3.UP, cam_yaw).normalized()
	

	# Move the character based on movement input.
	if move_dir.length() > 0:
		velocity.x = move_dir.x * current_speed
		velocity.z = move_dir.z * current_speed
		# Calculate the target rotation for the character to face move_dir.
		var target_yaw = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * rotation_speed)

	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not jump_in_progress:
		velocity.y = jump_velocity
				
	move_and_slide()
