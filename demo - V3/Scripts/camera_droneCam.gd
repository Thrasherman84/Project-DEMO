extends Node3D

@onready var camera := $Camera3D  # Fixed to properly reference the Camera3D node

# Camera leading parameters
@export var lead_amount := 1.0  # How much the camera leads player movement
@export var lead_smoothing := 5.0  # How smoothly the camera catches up

# Camera aim parameters
@export var aim_offset := Vector3(0.0, 1.5, 0.0)  # Where camera points (e.g. above player)
@export var aim_smoothing := 3.0  # How smoothly aim adjusts

# Target positions
var lead_target := Vector3.ZERO
var current_lead := Vector3.ZERO

# Called when the node enters the scene tree
func _ready() -> void:
	# Initialize the camera aim
	set_aim_target(aim_offset)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Smoothly adjust camera leading
	if lead_amount > 0.0:
		current_lead = current_lead.lerp(lead_target, lead_smoothing * delta)
		position = current_lead

	# Update where the camera is pointing
	look_at(get_parent().global_position + aim_offset)

func move(delta: float) -> void:
	var movement = Input.get_vector("Forward","Backward","Left","Right")
	var direction = Vector3(movement.x, 0, movement.y).rotated(Vector3.UP, camera.rotation.y).normalized()
	
	# Update the lead target based on movement direction
	if direction.length() > 0.1:
		lead_target = direction * lead_amount
	else:
		lead_target = Vector3.ZERO

func set_aim_target(new_target: Vector3) -> void:
	aim_offset = new_target
