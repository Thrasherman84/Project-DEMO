extends Control

@export var grenade_scene: PackedScene  # Assign your grenade scene in the inspector
@export var player_node_path: NodePath  # Path to the player for spawn position

@onready var throw_button = %ThrowButton  # Reference to your button
@onready var player = get_node(player_node_path) if player_node_path else null

func _ready():
	# Connect the button's pressed signal to our throw function
	throw_button.pressed.connect(_on_throw_button_pressed)

func _on_throw_button_pressed():
	# Determine spawn position (usually near the player)
	var spawn_position = Vector3.ZERO
	
	if player:
		spawn_position = player.global_transform.origin
		# Optional: Offset to spawn slightly in front of the player
		spawn_position += player.global_transform.basis.z * -1.0  # Adjust as needed
	
	# Create grenade instance
	var grenade = grenade_scene.instantiate()
	get_tree().root.add_child(grenade)
	grenade.global_transform.origin = spawn_position
	
	# Throw with default velocity or calculate based on player's facing direction
	var throw_direction = player.global_transform.basis.z * -10.0 if player else Vector3(0, 5, -10)
	grenade.throw(throw_direction)
