extends SpringArm3D

@onready var camera := Camera3D

const JUMP_VELOCITY = 4.5

# Called every frame. 'delta' is the elapsed time since the previous frame.
func move(delta: float) -> void:
	var movement = Input.get_vector("Forward","Backward","Left","Right")
	var direction = Vector3(movement.x, 0, movement.y).rotated(Vector3.UP, camera.rotation.y).normalized()
