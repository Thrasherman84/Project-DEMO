extends CharacterBody3D

@onready var pivot := $Pivot
@onready var spring_arm := $Pivot/SpringArm3D
@onready var camera := $Pivot/SpringArm3D/Camera3D
@onready var character_mesh := $xBot_idle/Skeleton3D/Beta_Joints  # Reference to MeshInstance3D
@onready var anim_player := $xBot_idle/AnimationPlayer  # Reference to AnimationPlayer
@onready var skeleton := $xBot_idle/Skeleton3D  # Reference to Skeleton3D

const SPEED = 5.0
const JUMP_VELOCITY = 4
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
		if is_on_floor() and not is_jumping:
			anim_player.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		if not is_jumping:
			anim_player.play("mixamo_com")
		
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not jump_in_progress:
		jump_in_progress = true
		is_jumping = true
		anim_player.play("jump")
		await get_tree().create_timer(0.6).timeout
		velocity.y = JUMP_VELOCITY

		# Wait until the character is back on the floor
		await get_tree().create_timer(0.1).timeout # Wait for a short period before checking is_on_floor()

		# Now we wait until the character is on the floor
		while not is_on_floor():
			await get_tree().create_timer(0.1).timeout

		# Once on the floor, reset jumping and check movement for next animation
		is_jumping = false
		jump_in_progress = false
		
		if move_dir.length() > 0:
			anim_player.play("run")
		else:
			anim_player.play("mixamo_com")
				
	move_and_slide()
