extends Sprite2D 

@export var activation_threshold := 300 
@export var card_type_name := "BaseCard" 
@export var energy_cost := 1  # Energy required to play this card
var initial_position := Vector2.ZERO
var is_playable := true 
var is_discarded := false  # New variable to track if card is marked for discard
var mouse_over := false  
var position_initialized := false 
var drag_start_mouse_pos := Vector2.ZERO
var drag_start_card_pos := Vector2.ZERO
var is_dragging := false

signal card_activated(damage_amount: int)

func _ready():
	initial_position = position

func update_initial_position():
	initial_position = position
	position_initialized = true

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and Global.turn_manager.is_player_turn():
		if not is_playable or is_discarded:
			return
			
		if event.pressed:
			var distance = get_global_mouse_position().distance_to(global_position)
			var card_width = get_card_size().x
			
			if distance < card_width / 2: 
				is_dragging = true
				drag_start_mouse_pos = get_global_mouse_position()
				drag_start_card_pos = position
				modulate = Color(1.2, 1.2, 1.2) 
		else:
			if is_dragging:
				is_dragging = false
				if position.y <= initial_position.y - activation_threshold:
					activate_card()
				else:
					position = initial_position
					modulate = Color(1, 1, 1)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and Global.turn_manager.is_player_turn():
		if event.pressed:
			var distance = get_global_mouse_position().distance_to(global_position)
			var card_width = get_card_size().x
			
			if distance < card_width / 2:
				toggle_discard_state()

func _process(_delta):
	if !position_initialized and position != Vector2.ZERO:
		update_initial_position()
		
	if is_dragging:
		var mouse_delta = get_global_mouse_position() - drag_start_mouse_pos
		position.x = initial_position.x
		position.y = drag_start_card_pos.y + mouse_delta.y
		
		if position.y <= initial_position.y - activation_threshold:
			modulate = Color(1.2, 1.2, 0.8)
		else:
			modulate = Color(1.1, 1.1, 1.1)

func toggle_discard_state():
	is_discarded = !is_discarded
	update_visual_state()
	print("Card ", card_type_name, " discard state: ", is_discarded)

func update_visual_state():
	if is_discarded:
		# Visual feedback for discarded cards (orange tint)
		modulate = Color(1.0, 0.7, 0.3, 0.8)  # Orange with slight transparency
	elif not is_playable:
		# Visual feedback for used cards (gray)
		modulate = Color(0.5, 0.5, 0.5)
	else:
		# Normal card appearance
		modulate = Color(1, 1, 1)

func activate_card():
	if Global.is_game_frozen():
		return
	
	# Check if player has enough energy
	if not Global.can_afford_card(energy_cost):
		# Flash red to indicate not enough energy
		modulate = Color(1.5, 0.5, 0.5)
		await get_tree().create_timer(0.2).timeout
		update_visual_state()  # Return to proper visual state
		reset_position()
		return
	
	# Spend the energy
	if not Global.spend_energy(energy_cost):
		reset_position()
		return
	
	# Update energy display
	var main_scene = get_tree().current_scene
	if main_scene.has_method("update_energy_display"):
		main_scene.update_energy_display()
	
	Global.trigger_player_animation(card_type_name, get_animation_data())
	
	# Always call apply_effect_to_target, let the card decide if it needs a target
	apply_effect_to_target(Global.current_target)
	reset_position()
	
	is_playable = false
	update_visual_state()  # Update visual state instead of direct modulate

func get_animation_data() -> Dictionary:
	return {}

func apply_effect_to_target(_target):
	pass

func reset_position():
	position = initial_position
	is_dragging = false
	update_visual_state()  # Use proper visual state instead of forcing white

func get_card_size() -> Vector2:
	if texture:
		if region_enabled:
			return region_rect.size * scale
		else:
			return texture.get_size() * scale
	return Vector2(100, 150) * scale

func is_card_playable() -> bool:
	return is_playable and not is_discarded  # Card is not playable if discarded
