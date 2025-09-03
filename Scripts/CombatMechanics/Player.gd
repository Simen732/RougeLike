extends CharacterBody2D
@onready var progress_bar = $ProgressBar
@onready var animated_sprite = $AnimatedSprite2D2
@onready var animation_player = $AnimationPlayer

# Animation mapping for different card types
var card_animations = {
	"SingleSlash": "SingleSlash",
	"DoubleSlash": "DoubleSlash",
	# Add more mappings here as you create new card types
	# "HealCard": "Heal",
	# "ShieldCard": "Block", 
}

@export var max_health = 100
@export var speed = 12  # Player speed for turn order
var current_health = max_health	

func _physics_process(delta):
	pass
	
func _ready():
	progress_bar.value = progress_bar.max_value
	current_health = max_health
	# Register with Global for animation triggers
	Global.register_player(self)
	print("Player: Registered with turn manager")

# Play animation based on card type
func play_card_animation(card_type: String, animation_data: Dictionary = {}):
	if card_type in card_animations:
		var animation_name = card_animations[card_type]
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.play(animation_name)
			print("Player: Playing animation '", animation_name, "' for card type '", card_type, "'")
			
			# Wait for animation to complete, then return to idle
			var animation_length = get_animation_length(animation_name)
			await get_tree().create_timer(animation_length).timeout
			animated_sprite.play("Idle")
		else:
			print("Player: Animation '", animation_name, "' not found for card type '", card_type, "'")
	else:
		print("Player: No animation mapping found for card type '", card_type, "'")

# Get the length of an animation in seconds
func get_animation_length(animation_name: String) -> float:
	if animated_sprite.sprite_frames.has_animation(animation_name):
		var sprite_frames = animated_sprite.sprite_frames
		var frame_count = sprite_frames.get_frame_count(animation_name)
		var speed = sprite_frames.get_animation_speed(animation_name)
		return frame_count / speed
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
	print("Game frozen due to player death")
	
	# Disable card interactions by setting a global flag
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

# Example method to temporarily double speed
func double_speed_for_turn():
	modify_speed(2.0)
	print("Player: Speed doubled to ", speed, " for this fight!")
