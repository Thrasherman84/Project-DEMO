extends Node3D

signal delivery_finished

@export
var player : CharacterBody3D #RigidBody3D

@export
var path_checkpoints : Array[Area3D]
var next_checkpoint
var current_checkpoint_id = 0

@export
var debug_mode = false
@export
var debug_material: StandardMaterial3D

func _ready() -> void:
	path_checkpoints[current_checkpoint_id].body_entered.connect(checkpointReached.bind())
	
	if(debug_mode == true):
		for checkpoint in path_checkpoints:
			var debug_mesh = MeshInstance3D.new()
			
			debug_mesh.mesh = BoxMesh.new()
			
			debug_mesh.set_surface_override_material(0, debug_material)
			
			checkpoint.add_child(debug_mesh)

func checkpointReached(bodyEntered: Node3D):
	#print( "checkpoint" )
	if(bodyEntered == player):
		path_checkpoints[current_checkpoint_id].body_entered.disconnect(checkpointReached.bind())
		selectNextCheckpoint()

func selectNextCheckpoint():
	current_checkpoint_id += 1
	#print( current_checkpoint_id )
	if(current_checkpoint_id < path_checkpoints.size()):
		next_checkpoint = path_checkpoints[current_checkpoint_id]
		path_checkpoints[current_checkpoint_id].body_entered.connect(checkpointReached.bind())
	else:
		delivery_finished.emit()
		#print("delivery finished")
