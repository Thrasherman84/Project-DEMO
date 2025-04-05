extends CharacterBody3D

@onready var pivot := $Pivot
@onready var spring_arm := $Pivot/SpringArm3D
@onready var camera := $Pivot/SpringArm3D/Camera3D
@onready var character_mesh := $Woman/Skeleton3D/Woman/Woman  # Reference to MeshInstance3D
@onready var anim_player := $Woman/AnimationPlayer# Reference to AnimationPlayer
@onready var skeleton := $Woman/Skeleton3D  # Reference to Skeleton3D

const SPEED = 5.0
const JUMP_VELOCITY = 6
@export var mouse_sensitivity := 0.005
const GRAVITY = -9.8
@export var tilt_limit := deg_to_rad(75)

var pitch := 0.0
var rotation_speed := 5.0  # Adjust this to make the character turn faster/slower
var is_jumping = false

func _ready():
	# Decouple the pivot from inheriting the character’s rotation.
	# This makes the pivot (and thus the camera) independent.
	pivot.top_level = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Mouse controls only the pivot (camera) rotation.
		pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -tilt_limit, tilt_limit)
		spring_arm.rotation.x = pitch

func _physics_process(delta: float) -> void:
	# Update the pivot's global position to follow the character but preserve its own rotation.
	var current_basis = pivot.global_transform.basis
	pivot.global_transform = Transform3D(current_basis, global_transform.origin)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Get movement input (these actions should be defined only for movement)
	var input_vec = Input.get_vector("Left", "Right", "Forward", "Backward")
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
		
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY  # Apply upward force for jump
		is_jumping = true  # Mark that the character is now jumping

	move_and_slide()
