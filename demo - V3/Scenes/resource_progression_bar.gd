extends ProgressBar

@export var resourceCurrent : ResourceFloat
@export var resourceMax : ResourceFloat

@export var progressBarRange : Range

func _process(delta: float) -> void:
	progressBarRange.value = resourceCurrent.value / resourceMax.value * 100
