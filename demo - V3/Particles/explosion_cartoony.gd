extends Node3D

@onready var debris = $Debris
@onready var puff = $puff

func explode():
	debris.emitting = true
	puff.emitting = true
	
	# Add some sound --
	
	await get_tree().create_timer(2.0).timeout
	queue_free()
