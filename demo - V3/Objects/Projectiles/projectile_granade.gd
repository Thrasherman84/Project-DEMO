extends Node3D

@export var explosion_scene: PackedScene = null
@export var fuse_time: float = 3.0  # Time till explosion in seconds

@onready var grenade_mesh: Node3D = $GrenadeMesh 
@onready var fuse_timer: Timer = $FuseTimer

signal explosion_finished

func _ready():
	# Setup timer
	if not has_node("FuseTimer"):
		fuse_timer = Timer.new()
		fuse_timer.name = "FuseTimer"
		add_child(fuse_timer)
	else:
		fuse_time = fuse_timer.wait_time

	fuse_timer.wait_time = fuse_time
	fuse_timer.one_shot = true
	fuse_timer.timeout.connect(_on_fuse_timer_timeout)

func throw(initial_velocity: Vector3 = Vector3.ZERO):
	if has_node("RigidBody3D"):
		$RigidBody3D.apply_impulse(initial_velocity)

	fuse_timer.start()

func _on_fuse_timer_timeout():
	# Hide the grenade itself
	grenade_mesh.visible = false

	# Create explosion instance
	var explosion_instance = explosion_scene.instantiate()
	get_parent().add_child(explosion_instance)
	explosion_instance.global_transform.origin = global_transform.origin

	# pop!
	explosion_instance.explode()

	await get_tree().create_timer(2.0).timeout
	queue_free()

	explosion_finished.emit()
