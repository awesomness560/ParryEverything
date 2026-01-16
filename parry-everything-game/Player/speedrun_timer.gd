extends Label

# Speedrun Timer Script for Godot 4
# Attach this to a Label node in your scene

var time_elapsed: float = 0.0
var is_running: bool = false
var is_paused: bool = false

# Optional: Set these in the inspector or via code
@export var start_on_ready: bool = false
@export var show_milliseconds: bool = true

func _ready():
	if start_on_ready:
		start_timer()
	update_display()

func _process(delta):
	if is_running and not is_paused:
		time_elapsed += delta
		update_display()

func start_timer():
	"""Start or resume the timer"""
	is_running = true
	is_paused = false

func stop_timer():
	"""Stop the timer completely"""
	is_running = false
	is_paused = false

func pause_timer():
	"""Pause the timer (can be resumed)"""
	is_paused = true

func resume_timer():
	"""Resume a paused timer"""
	if is_running:
		is_paused = false

func reset_timer():
	"""Reset the timer to 0"""
	time_elapsed = 0.0
	update_display()

func restart_timer():
	"""Reset and start the timer"""
	reset_timer()
	start_timer()

func get_time() -> float:
	"""Get the current elapsed time"""
	return time_elapsed

func update_display():
	"""Update the label text with formatted time"""
	var hours = int(time_elapsed) / 3600
	var minutes = (int(time_elapsed) % 3600) / 60
	var seconds = int(time_elapsed) % 60
	var milliseconds = int((time_elapsed - int(time_elapsed)) * 1000)
	
	if show_milliseconds:
		if hours > 0:
			text = "%02d:%02d:%02d.%03d" % [hours, minutes, seconds, milliseconds]
		else:
			text = "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
	else:
		if hours > 0:
			text = "%02d:%02d:%02d" % [hours, minutes, seconds]
		else:
			text = "%02d:%02d" % [minutes, seconds]

# Example signal connections you might use:
# Connect these to your game events
func _on_level_started():
	restart_timer()

func _on_level_completed():
	stop_timer()
	print("Final time: ", text)

func _on_checkpoint_reached():
	print("Checkpoint time: ", text)
