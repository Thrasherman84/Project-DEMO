extends Label

@export var resource : ResourceInt

@export var displayLabel : Label

func _process(delta: float) -> void:
	displayLabel.text = str(resource.value)
