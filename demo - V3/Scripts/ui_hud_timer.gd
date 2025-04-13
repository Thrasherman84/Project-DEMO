extends Label

var time_elapsed := 0.0
var is_running := false

func _process(delta):
	if is_running:
		time_elapsed += delta
		self.text = format_time(time_elapsed)

func format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	var millis = int((seconds - int(seconds)) * 100)
	return "%02d:%02d.%02d" % [mins, secs, millis]

func start():
	is_running = true
	#time_elapsed = 0.0

func pause( state: bool ):
	is_running = !state

func stop():
	is_running = false
	# Keep the time on screen
	# Optional: reset here if needed
	# time_elapsed = 0
