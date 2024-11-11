# CardBase.gd
extends Sprite2D  # Set to Sprite2D for compatibility with your setup

@export var activation_threshold := 100  # How far to drag to activate
var is_dragging := false
var initial_position := Vector2.ZERO

func _ready():
	initial_position = position

func _input(event):
	# Check if the left mouse button is pressed on the card
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Check if the mouse is over the sprite
			if get_global_mouse_position().distance_to(global_position) < get_card_size().x / 2:
				# Start dragging when clicking on the card
				is_dragging = true
				
		else:
			# Stop dragging when releasing the mouse button
			is_dragging = false
			if position.y > initial_position.y - activation_threshold:
				position = initial_position

func _process(delta):
	if is_dragging:
		# Follow the mouse position, restricting horizontal movement
		var mouse_position = get_global_mouse_position()
		position.y = min(mouse_position.y, initial_position.y)
		position.x = initial_position.x

		# Check if the card has been dragged high enough to activate
		if position.y <= initial_position.y - activation_threshold:
			activate_card()

# Virtual function to allow child classes to implement specific activation logic
func activate_card():
	print("Card activated!")  # Default behavior; can be overridden in derived classes
	reset_position()

func reset_position():
	position = initial_position
	is_dragging = false

# Helper function to get the size of the card for Sprite2D
func get_card_size() -> Vector2:
	if texture:
		return texture.get_size()
	return Vector2.ZERO
