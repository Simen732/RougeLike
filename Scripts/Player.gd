extends CharacterBody2D
@onready var progress_bar = $ProgressBar
@onready var animated_sprite = $AnimatedSprite2D2

# Animation mapping for different card types
var card_animations = {
	"DamageCard": "Attack",
	# Add more mappings here as you create new card types
	# "HealCard": "Heal",
	# "ShieldCard": "Block", 
}

func _physics_process(delta):
	pass
	
func _ready():
	progress_bar.value = progress_bar.max_value
	# Register with Global for animation triggers
	Global.register_player(self)

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
