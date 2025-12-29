extends ScrollContainer
class_name ChatManager


@export var vbox : VBoxContainer
const MAX_MESSAGES = 10

# Bright colors for usernames
var username_colors = [
	Color.RED,
	Color.ORANGE,
	Color.YELLOW,
	Color.GREEN,
	Color.CYAN,
	Color.BLUE,
	Color.MAGENTA,
	Color.HOT_PINK,
	Color.LIME_GREEN,
	Color.AQUA,
	Color.GOLD,
	Color.CORAL,
]

func addMessage(username: String, message: String, color: Color = Color.WHITE):
	# Create message container
	var hbox = HBoxContainer.new()
	
	# Username label with color (random from array if default WHITE is passed)
	var username_label = Label.new()
	username_label.text = username + ":"
	if color == Color.WHITE:
		username_label.modulate = username_colors.pick_random()
	else:
		username_label.modulate = color
	hbox.add_child(username_label)
	
	# Message label
	var message_label = Label.new()
	message_label.text = message
	hbox.add_child(message_label)
	
	# Add to container
	vbox.add_child(hbox)
	
	# Cull old messages - remove immediately with free()
	while vbox.get_child_count() > MAX_MESSAGES:
		var old_msg = vbox.get_child(0)
		vbox.remove_child(old_msg)
		old_msg.free()
	
	# Auto-scroll to bottom
	await get_tree().process_frame
	scroll_vertical = int(vbox.size.y)

func clearAllMessages():
	while vbox.get_child_count() > 0:
		var old_msg = vbox.get_child(0)
		vbox.remove_child(old_msg)
		old_msg.free()
