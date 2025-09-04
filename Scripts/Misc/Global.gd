extends Node

var PlayerMaxHealth = 100
var MAX_HAND_SIZE = 7  # Maximum cards in hand

# Global references and configuration
var card_types = {
	"SingleSlash": preload("res://Scripts/Cards/SingleSlash.gd"),
	"DoubleSlash": preload("res://Scripts/Cards/DoubleSlash.gd")
}

# Damage number manager reference
var damage_number_manager: Node2D

# Track enemies in combat
var enemies_in_combat = []
var current_target = null
var registered_enemies = []

# Player reference for animations
var player_character = null

# Audio player for sound effects
var audio_player: AudioStreamPlayer
var master_volume: float = 1.0  # Add volume control

# Turn manager reference
var turn_manager: Node

# Spawn manager reference
var spawn_manager: Node

# Game state
var game_frozen: bool = false

func _ready():
	# Initialize turn manager first
	turn_manager = preload("res://Scripts/CombatMechanics/TurnManager.gd").new()
	add_child(turn_manager)
	print("Global: TurnManager initialized")
	
	# Initialize spawn manager
	spawn_manager = preload("res://Scripts/Misc/SpawnManager.gd").new()
	add_child(spawn_manager)
	print("Global: SpawnManager initialized")
	
	# Create an audio player for sound effects
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.volume_db = linear_to_db(master_volume)
	print("Global: Audio system initialized")
	
	# Create and setup damage number manager
	damage_number_manager = preload("res://Scripts/VisuelleGreier/DamageNumberManager.gd").new()
	add_child(damage_number_manager)
	print("Global: DamageNumberManager initialized")

# Register an enemy when it enters combat
func register_enemy(enemy):
	enemies_in_combat.append(enemy)
	registered_enemies.append(enemy)
	# Set as current target if it's the first enemy
	if current_target == null:
		current_target = enemy
	
	# Also register with turn manager
	if turn_manager:
		turn_manager.register_enemy(enemy)
		print("Global: Enemy registered with turn manager - ", enemy.name)

# Remove enemy from combat
func unregister_enemy(enemy):
	enemies_in_combat.erase(enemy)
	registered_enemies.erase(enemy)
	# If current target was this enemy, select a new target
	if current_target == enemy:
		if registered_enemies.size() > 0:
			current_target = registered_enemies[0]
		else:
			current_target = null
	
	# Also unregister from turn manager
	if turn_manager:
		turn_manager.unregister_enemy(enemy)
		print("Global: Enemy unregistered from turn manager - ", enemy.name)

# Register player for animations
func register_player(player):
	player_character = player
	print("Global: Player registered for animations")
	
	# Also register with turn manager
	if turn_manager:
		turn_manager.register_player(player)
		print("Global: Player registered with turn manager")

# Get the sound file path for a specific card type - automatically detect files
func get_sound_path_for_card_type(card_type: String) -> String:
	if card_type == "DamageCard":
		# Look for any audio file in the sound effects folder
		var dir = DirAccess.open("res://Sound effects/")
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				var lower_name = file_name.to_lower()
				if (lower_name.ends_with(".ogg") or lower_name.ends_with(".wav") or 
					lower_name.ends_with(".mp3") or lower_name.ends_with(".m4a")):
					var full_path = "res://Sound effects/" + file_name
					print("Global: Found sound file: ", full_path)
					return full_path
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			print("Global: Could not access Sound effects directory")
	
	return ""

# Play sound effect for specific card types
func play_card_sound_effect(card_type: String, sound_data: Dictionary = {}):
	var sound_path = get_sound_path_for_card_type(card_type)
	if sound_path != "":
		print("Global: Attempting to load sound: ", sound_path)
		var sound = load(sound_path)
		if sound:
			audio_player.stream = sound
			# Set volume if provided in sound_data
			if "sound_volume" in sound_data:
				audio_player.volume_db = linear_to_db(sound_data.sound_volume)
			audio_player.play()
			print("Global: Successfully playing sound effect for card type: ", card_type)
		else:
			print("Global: Failed to load sound effect: ", sound_path)
	else:
		print("Global: No sound effect file found for card type: ", card_type)

# Trigger player animation based on card type
func trigger_player_animation(card_type: String, animation_data: Dictionary = {}):
	if player_character and player_character.has_method("play_card_animation"):
		player_character.play_card_animation(card_type, animation_data)
		print("Global: Triggered player animation for card type: ", card_type)
	
	# Also play sound effect
	play_card_sound_effect(card_type, animation_data)

# Optional: Add volume control function
func set_sound_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	audio_player.volume_db = linear_to_db(master_volume)

# Convenience method to show damage numbers
func show_damage_number(damage: int, world_position: Vector2, color: Color = Color.RED):
	if damage_number_manager:
		damage_number_manager.show_damage(damage, world_position, color)

# Game state management
func set_game_frozen(frozen: bool):
	game_frozen = frozen
	print("Global: Game frozen state set to ", frozen)
	
	# Disable turn manager when frozen
	if turn_manager and frozen:
		turn_manager.set_process(false)
		turn_manager.set_physics_process(false)

func is_game_frozen() -> bool:
	return game_frozen

# Handle input for restart/quit when game is frozen
func _input(event):
	if game_frozen and event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			restart_game()
		elif event.keycode == KEY_ESCAPE:
			quit_game()

func restart_game():
	print("Global: Restarting game")
	game_frozen = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func quit_game():
	print("Global: Quitting game")
	get_tree().quit()

# Target management system
func set_current_target(target):
	# Ensure we have a valid target or clear if null
	if not target:
		clear_current_target()
		return
		
	# Clear previous target indicator if switching targets
	if current_target and current_target != target and is_instance_valid(current_target):
		if current_target.has_method("set_targeted"):
			current_target.set_targeted(false)
	
	# Set new target and show indicator
	current_target = target
	if current_target and current_target.has_method("set_targeted"):
		current_target.set_targeted(true)
	
	print("Global: Target set to ", target.name if target else "none")

func get_current_target():
	# Validate current target is still alive and valid
	if current_target:
		if not is_instance_valid(current_target) or (current_target.has_method("is_dead") and current_target.is_dead()):
			current_target = null
	return current_target

func clear_current_target():
	if current_target and is_instance_valid(current_target) and current_target.has_method("set_targeted"):
		current_target.set_targeted(false)
	current_target = null
