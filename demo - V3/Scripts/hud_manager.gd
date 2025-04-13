extends Control

var time_elapsed := 0.0
var is_running := false

@onready var timerLabel := $"HUD Layout/DeliveryTimer"

func _process(delta):
	if is_running:
		startTimer()

func format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	var millis = int((seconds - int(seconds)) * 100)
	return "%02d:%02d:%02d" % [mins, secs, millis]

func startTimer():
	is_running = true
	timerLabel.start()

func pauseTimer( state: bool ):
	timerLabel.pause(is_running)
	is_running = !state

func stopTimer():
	is_running = false
	timerLabel.stop()
	# Keep the time on screen
	# Optional: reset here if needed
	# time_elapsed = 0
