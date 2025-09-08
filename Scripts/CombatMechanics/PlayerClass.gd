extends Resource
class_name PlayerClass

@export var player_class_name: String
@export var description: String
@export var icon: Texture2D

# Visual customization
@export var sprite_frames: SpriteFrames  # For AnimatedSprite2D
@export var sprite_texture: Texture2D    # For simple Sprite2D (alternative)
@export var sprite_scale: Vector2 = Vector2(1, 1)  # Custom scaling per class

# Base stats
@export var base_health: int = 100
@export var base_speed: int = 12

# Starting deck composition
@export var starting_cards: Dictionary = {}  # "CardType": count

# Class-specific abilities/modifiers
@export var special_abilities: Array = []
@export var passive_effects: Dictionary = {}  # "effect": value

func _init(p_name: String = "", p_desc: String = "", p_icon: Texture2D = null, p_health: int = 100, p_speed: int = 12):
	player_class_name = p_name
	description = p_desc
	icon = p_icon
	base_health = p_health
	base_speed = p_speed

func get_starting_deck() -> Dictionary:
	# Default deck if none specified
	if starting_cards.is_empty():
		return {
			"SingleSlash": 15,
			"DoubleSlash": 5
		}
	return starting_cards

func apply_to_player(player: Node):
	if player.has_method("set_max_health"):
		player.set_max_health(base_health)
	if player.has_method("set_speed"):
		player.set_speed(base_speed)
	
	# Set the current class for animations
	if player.has_method("set_character_class"):
		player.set_character_class(player_class_name)
	
	# Apply passive effects
	for effect in passive_effects:
		if player.has_method("apply_passive_effect"):
			player.apply_passive_effect(effect, passive_effects[effect])