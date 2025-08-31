# CardBase.gd
extends Sprite2D  # Set to Sprite2D for compatibility with your setup

@export var activation_threshold := 300  # How far to drag to activate
@export var card_type_name := "BaseCard"  # Override this in child classes
var is_dragging := false
var initial_position := Vector2.ZERO
var is_playable := true  # Can this card be played
var mouse_over := false  # Track if mouse is over the card
var position_initialized := false  # Flag to check if position is properly initialized
var drag_start_mouse_pos := Vector2.ZERO  # Mouse position when drag started
var drag_start_card_pos := Vector2.ZERO  # Card position when drag started

signal card_activated(damage_amount: int)

func _ready():
	# Set initial position, but this might be before arrangement in the hand
	initial_position = position
	print("Card initialized at position: ", initial_position)
	# We'll update this position again after arrangement

# Function to update the initial position after card arrangement
func update_initial_position():
	initial_position = position
	position_initialized = true
	print("Card initial position updated to: ", initial_position)

func _input(event):
	# Only process input if the card is playable
	if not is_playable:
		return
	
	# Check if the left mouse button is pressed on the card
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Check if the mouse is over the sprite with a more generous hit area
			var distance = get_global_mouse_position().distance_to(global_position)
			var card_width = get_card_size().x
			print("Mouse distance to card: ", distance, " card width: ", card_width)
			
			if distance < card_width / 2:  # More generous hit detection
				print("Card clicked: Starting drag")
				is_dragging = true
				# Store the starting positions when drag begins
				drag_start_mouse_pos = get_global_mouse_position()
				drag_start_card_pos = position
				# Visual feedback
				modulate = Color(1.2, 1.2, 1.2)  # Slight highlight
		else:
			# Stop dragging when releasing the mouse button
			if is_dragging:
				is_dragging = false
				if position.y <= initial_position.y - activation_threshold:
					# Card has been dragged high enough to activate
					print("Card released above threshold: Activating")
					activate_card()
				else:
					# Card wasn't dragged far enough, return to initial position
					print("Card released below threshold: Returning to position")
					position = initial_position
					modulate = Color(1, 1, 1)  # Reset color

func _process(delta):
	# Ensure initial position is properly set - fallback in case update_initial_position wasn't called
	if !position_initialized and position != Vector2.ZERO:
		update_initial_position()
		
	if is_dragging:
		# Calculate how much the mouse has moved since drag started
		var mouse_delta = get_global_mouse_position() - drag_start_mouse_pos
		
		# Apply only the Y movement to the card's position, keep X fixed
		position.x = initial_position.x
		position.y = drag_start_card_pos.y + mouse_delta.y
		
		print("Dragging card: Mouse delta Y: ", mouse_delta.y, " Card Y: ", position.y, " Initial Y: ", initial_position.y)
		
		# Visual feedback - make card glow when it's above the activation threshold
		if position.y <= initial_position.y - activation_threshold:
			modulate = Color(1.2, 1.2, 0.8)  # Slight glow
		else:
			modulate = Color(1.1, 1.1, 1.1)  # Normal drag highlight

## Virtual function to allow child classes to implement specific activation logic
func activate_card():
	print("Card activated!")  # Default behavior; can be overridden in derived classes
	
	# Trigger player animation based on card type
	Global.trigger_player_animation(card_type_name, get_animation_data())
	
	# If there's a current target, apply the card effect to it
	if Global.current_target != null:
		apply_effect_to_target(Global.current_target)
	reset_position()
	
	# Make the card unplayable after use (remove from hand later)
	is_playable = false
	modulate = Color(0.5, 0.5, 0.5)  # Dim the card to indicate it's been used

# Virtual function for providing animation data to the player
func get_animation_data() -> Dictionary:
	return {}  # Override in child classes if needed

# Virtual function for card effects
func apply_effect_to_target(target):
	pass  # Override in child classes

func reset_position():
	position = initial_position
	is_dragging = false
	modulate = Color(1, 1, 1)  # Reset color

# Helper function to get the size of the card for Sprite2D
func get_card_size() -> Vector2:
	if texture:
		if region_enabled:
			# If using a region, return the region size
			return region_rect.size * scale
		else:
			# Otherwise return the texture size
			return texture.get_size() * scale
	return Vector2(100, 150) * scale  # Default size if no texture

# Check if this card is still playable
func is_card_playable() -> bool:
	return is_playable
