extends Control

@onready var icon_texture = $IconTexture
@onready var border = $Border
@onready var background = $Background

var entity_reference = null

func setup_icon(entity: Node, texture: Texture2D = null, is_current: bool = false):
	entity_reference = entity
	
	# Set the icon texture
	if texture:
		icon_texture.texture = texture
	else:
		# Use default textures based on entity type
		set_default_texture(entity)
	
	# Style the icon based on whether it's the current turn
	if is_current:
		set_current_turn_style()
	else:
		set_normal_style()
	
	# Add entity name as tooltip
	if entity:
		tooltip_text = entity.name
	else:
		tooltip_text = "Unknown"

func set_default_texture(entity: Node):
	# Set background color directly based on entity type
	if entity.name.to_lower().contains("player") or entity.name.to_lower().contains("characterbody2d"):
		# White background for player
		background.color = Color.WHITE
		print("TurnIcon: Set player icon to white for ", entity.name)
	else:
		# Black background for enemies  
		background.color = Color.BLACK
		print("TurnIcon: Set enemy icon to black for ", entity.name)
	
	# Make the icon texture transparent or remove it since we're using background color
	icon_texture.modulate = Color.TRANSPARENT

func set_current_turn_style():
	# Highlight the current turn with yellow border but keep entity background color
	border.color = Color.YELLOW
	# Keep the existing background color (white for player, black for enemy)
	# Just add a slight yellow tint
	var current_bg = background.color
	if current_bg == Color.WHITE:
		background.color = Color(1.0, 1.0, 0.8)  # Slightly yellow-tinted white
	else:
		background.color = Color(0.3, 0.3, 0.0)  # Slightly yellow-tinted black
	
	# Optional: Add pulsing effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate:a", 0.7, 0.5)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func set_normal_style():
	# Normal styling for upcoming turns
	border.color = Color.WHITE
	# Don't override the background color here - keep the entity-specific color
	modulate.a = 1.0  # Remove any transparency effects

func _ready():
	# Set default size
	custom_minimum_size = Vector2(48, 48)
	size = Vector2(48, 48)