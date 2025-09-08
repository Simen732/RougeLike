extends CharacterBody2D
@onready var progress_bar = $ProgressBar
@onready var animated_sprite = $AnimatedSprite2D2
@onready var animation_player = $AnimationPlayer

# Animation mapping for different card types
var card_animations = {
	"SingleSlash": "SingleSlash",
	"DoubleSlash": "DoubleSlash",
	"HealCard": "Heal"
	# "PoisonCard": "Poison"  # TODO: Add poison animation
	# "ShieldCard": "Block", 
}

@export var max_health = 100
@export var speed = 12  # Player speed for turn order
var current_health = max_health
var current_class = "Warrior"  # Default class

func _physics_process(_delta):
	pass
	
func _ready():
	# Apply selected class first
	if Global.class_manager and Global.class_manager.get_selected_class():
		Global.class_manager.apply_class_to_player(self)
	
	progress_bar.value = progress_bar.max_value
	current_health = max_health
	# Register with Global for animation triggers
	Global.register_player(self)
	print("Player: Registered with turn manager")

# Play animation based on card type with class support
func play_card_animation(card_type: String, _animation_data: Dictionary = {}):
	if card_type in card_animations:
		var base_animation_name = card_animations[card_type]
		var class_animation_name = current_class + "_" + base_animation_name
		
		# Try class-specific animation first, fall back to base animation
		if animated_sprite.sprite_frames.has_animation(class_animation_name):
			animated_sprite.play(class_animation_name)
			print("Player: Playing class animation '", class_animation_name, "' for card type '", card_type, "'")
			
			var animation_length = get_animation_length(class_animation_name)
			await get_tree().create_timer(animation_length).timeout
			
			# Return to class-specific idle or default idle
			var idle_animation = current_class + "_Idle"
			if animated_sprite.sprite_frames.has_animation(idle_animation):
				animated_sprite.play(idle_animation)
			else:
				animated_sprite.play("Idle")
				
		elif animated_sprite.sprite_frames.has_animation(base_animation_name):
			# Fall back to base animation
			animated_sprite.play(base_animation_name)
			print("Player: Playing base animation '", base_animation_name, "' for card type '", card_type, "'")
			
			var animation_length = get_animation_length(base_animation_name)
			await get_tree().create_timer(animation_length).timeout
			animated_sprite.play("Idle")
		else:
			print("Player: Animation '", class_animation_name, "' or '", base_animation_name, "' not found")
	else:
		print("Player: No animation mapping found for card type '", card_type, "'")

# Set the character class for animations
func set_character_class(character_class: String):
	current_class = character_class
	print("Player: Set character class to ", character_class)
	
	# Apply class-specific scaling if available
	if Global.class_manager and Global.class_manager.get_selected_class():
		var selected_class = Global.class_manager.get_selected_class()
		if selected_class.sprite_scale != Vector2(1, 1):
			animated_sprite.scale = selected_class.sprite_scale
			print("Player: Applied scale ", selected_class.sprite_scale, " for class ", character_class)
	
	# Switch to class-specific idle animation if available
	var idle_animation = current_class + "_Idle"
	if animated_sprite.sprite_frames.has_animation(idle_animation):
		animated_sprite.play(idle_animation)
		print("Player: Switched to ", idle_animation)
	else:
		animated_sprite.play("Idle")
		print("Player: Using default Idle animation (", idle_animation, " not found)")

# Get the length of an animation in seconds
func get_animation_length(animation_name: String) -> float:
	if animated_sprite.sprite_frames.has_animation(animation_name):
		var sprite_frames = animated_sprite.sprite_frames
		var frame_count = sprite_frames.get_frame_count(animation_name)
		var anim_speed = sprite_frames.get_animation_speed(animation_name)
		return frame_count / anim_speed
	return 1.0  # Default duration if animation not found

func take_damage(damage_amount):
	progress_bar.value = current_health - damage_amount
	current_health -= damage_amount
	print("Player took ", damage_amount, " damage! Health: ", current_health, "/", max_health)
	
	# Visual feedback (optional - you can customize this)
	modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.15).timeout
	modulate = Color(1, 1, 1)
	
	# Check if player died
	if current_health <= 0:
		die()

func die():
	print("Player died!")
	# Handle player death (restart level, game over screen, etc.)
	current_health = 0
	animation_player.play("Death")
	animated_sprite.modulate = Color(1, 0.5, 0.5)
	animated_sprite.rotation = -1.5
	
	# Freeze the game
	freeze_game()

func freeze_game():
	print("FREEEEEEEZE (player dead)")
	
	if Global.has_method("set_game_frozen"):
		Global.set_game_frozen(true)
	
	# Create a timer that ignores pause mode for the game over screen
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.process_mode = Node.PROCESS_MODE_ALWAYS  # Continue running even when paused
	timer.timeout.connect(show_game_over_screen)
	timer.start()
	
	# Pause the scene tree to freeze all gameplay (do this after setting up timer)
	get_tree().paused = true

func show_game_over_screen():
	print("Showing game over screen")
	# You can implement a game over UI here
	# For now, just print a message and offer restart option
	print("GAME OVER - Press R to restart or ESC to quit")

func heal(heal_amount):
	current_health = min(current_health + heal_amount, max_health)
	progress_bar.value = current_health
	print("Player healed for ", heal_amount, "! Health: ", current_health, "/", max_health)

func get_health():
	return current_health

func get_max_health():
	return max_health

func is_alive():
	return current_health > 0

func get_speed():
	return speed

# Example method to modify speed dynamically
func modify_speed(modifier: float):
	speed = max(1, int(speed * modifier))  # Ensure speed doesn't go below 1
	print("Player: Speed changed to ", speed)

# Class application methods
func set_max_health(new_max_health: int):
	max_health = new_max_health
	current_health = max_health
	progress_bar.max_value = max_health
	progress_bar.value = current_health
	print("Player: Max health set to ", max_health)

func set_speed(new_speed: int):
	speed = new_speed
	print("Player: Speed set to ", speed)

func apply_passive_effect(effect_name: String, effect_value):
	print("Player: Applied passive effect ", effect_name, " with value ", effect_value)
	
	# Handle critical hit bonuses
	if effect_name == "crit_chance":
		Global.modify_crit_chance(effect_value)
	elif effect_name == "crit_multiplier":
		Global.modify_crit_multiplier(effect_value)
	# TODO: Implement other specific passive effects based on effect_name
	# Examples:
	# elif effect_name == "damage_bonus":
	#     damage_multiplier += effect_value
	# elif effect_name == "damage_reduction":
	#     damage_resistance += effect_value
