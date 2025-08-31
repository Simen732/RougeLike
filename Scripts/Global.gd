extends Node

var PlayerMaxHealth = 100
var MAX_HAND_SIZE = 7  # Maximum cards in hand

var card_types = {
	"DamageCard": preload("res://Scripts/DamagCard.gd"),
	# Add more card types here as you create them
}

# Track enemies in combat
var enemies_in_combat = []
var current_target = null

# Player reference for animations
var player_character = null

# Audio player for sound effects
var audio_player: AudioStreamPlayer
var master_volume: float = 1.0  # Add volume control

func _ready():
	# Create an audio player for sound effects
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.volume_db = linear_to_db(master_volume)
	print("Global: Audio system initialized")

# Register an enemy when it enters combat
func register_enemy(enemy):
	enemies_in_combat.append(enemy)
	# Set as current target if it's the first enemy
	if current_target == null:
		current_target = enemy

# Remove enemy from combat
func unregister_enemy(enemy):
	enemies_in_combat.erase(enemy)
	# If current target was this enemy, select a new target
	if current_target == enemy:
		current_target = enemies_in_combat[0] if enemies_in_combat.size() > 0 else null

# Register player for animations
func register_player(player):
	player_character = player
	print("Global: Player registered for animations")

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

