extends Node3D

signal delivery_started
signal delivery_finished

@export
var player : CharacterBody3D #RigidBody3D

@export
var route_id = 0

@export
var path_checkpoints : Array[Area3D]
var next_checkpoint
var current_checkpoint_id = 0

@export
var debug_mode = false
@export
var debug_material: StandardMaterial3D

var arrow = preload("res://Objects/Arrow.fbx")

func _ready() -> void:
	path_checkpoints[current_checkpoint_id].body_entered.connect(checkpointReached.bind())
	
	for i in path_checkpoints.size():
		if(i != path_checkpoints.size() - 1):
			var arrowInstance = arrow.instantiate()
			var currentPosition = path_checkpoints[i].global_position
			var nextPosition = path_checkpoints[i + 1].global_position
			var angle = (Vector2(nextPosition.x, nextPosition.z) - Vector2(currentPosition.x, currentPosition.z)).angle()
			
			arrowInstance.rotate(Vector3.DOWN, angle)
			
			arrowInstance.scale /= path_checkpoints[i].scale
			
			path_checkpoints[i].add_child(arrowInstance)
	
	for checkpoint in path_checkpoints:
		if(debug_mode == true):
			var debug_mesh = MeshInstance3D.new()
		
			debug_mesh.mesh = BoxMesh.new()
		
			debug_mesh.set_surface_override_material(0, debug_material)
		
			checkpoint.add_child(debug_mesh)

func checkpointReached(bodyEntered: Node3D):
	#print( "checkpoint" )
	if(bodyEntered == player):
		if ( current_checkpoint_id==0 ):
			delivery_started.emit( route_id )
		
		path_checkpoints[current_checkpoint_id].body_entered.disconnect(checkpointReached.bind())
		selectNextCheckpoint()

func selectNextCheckpoint():
	current_checkpoint_id += 1
	#print( current_checkpoint_id )
	if(current_checkpoint_id < path_checkpoints.size()):
		next_checkpoint = path_checkpoints[current_checkpoint_id]
		path_checkpoints[current_checkpoint_id].body_entered.connect(checkpointReached.bind())
	else:
		delivery_finished.emit( route_id )
		#print("delivery finished")
