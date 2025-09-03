extends Control

@onready var icon_texture = $IconTexture
@onready var border = $Border
@onready var background = $Background

var entity_reference = null
var original_background_color = Color.WHITE  # Store the entity's original color

func setup_icon(entity: Node, texture: Texture2D = null, is_current: bool = false):
	entity_reference = entity
	
	# IMPORTANT: Set entity-specific colors FIRST
	set_default_texture(entity)
	
	# Set the icon texture
	if texture:
		icon_texture.texture = texture
	
	# Style the icon based on whether it's the current turn
	# This must come AFTER set_default_texture to preserve colors
	if is_current:
		set_current_turn_style()
	else:
		set_normal_style()
		# DON'T call set_default_texture again - it was already called above
	
	# Add entity name as tooltip
	if entity:
		tooltip_text = entity.name
	else:
		tooltip_text = "Unknown"

func set_normal_style():
	# Normal styling for upcoming turns - DON'T override border color
	modulate.a = 1.0  # Remove any transparency effects
	
	# Use the stored original entity-specific border color
	border.color = original_background_color  # Use stored color for border

func set_default_texture(entity: Node):
	# Set border color directly based on entity type (border is what shows the box color)
	var is_player = false
	
	# Multiple ways to detect if this is a player
	if (entity.name.to_lower().contains("player") or 
		entity.name.to_lower().contains("characterbody2d") or
		(entity.get_script() and entity.get_script().resource_path.contains("Player.gd")) or
		entity is CharacterBody2D):
		is_player = true
	
	if is_player:
		# White border for player
		border.color = Color.WHITE
		original_background_color = Color.WHITE
	else:
		# Black border for enemies  
		border.color = Color.BLACK
		original_background_color = Color.BLACK
	
	# Make sure the border is visible 
	if border:
		border.visible = true
	
	if icon_texture:
		icon_texture.texture = null
		icon_texture.visible = false  # Hide texture completely so border shows

func set_current_turn_style():
	# Highlight the current turn with yellow border
	border.color = Color.YELLOW
	
	# Tint the background slightly yellow while preserving white/black distinction
	if original_background_color == Color.WHITE:
		background.color = Color(1.0, 1.0, 0.8)  # Slightly yellow-tinted white
	elif original_background_color == Color.BLACK:
		background.color = Color(0.3, 0.3, 0.0)  # Dark yellow for black backgrounds
	else:
		# Keep original color but add slight yellow tint
		background.color = original_background_color.lerp(Color.YELLOW, 0.3)
	
	# Optional: Add pulsing effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate:a", 0.7, 0.5)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)



func _ready():
	# Debug: Check if all required nodes exist
	print("TurnIcon: _ready() - Checking scene structure:")
	print("  - background node: ", background)
	print("  - border node: ", border) 
	print("  - icon_texture node: ", icon_texture)
	
	# Set default size
	custom_minimum_size = Vector2(48, 48)
	size = Vector2(48, 48)
	
	# Make sure background is set up correctly if it exists
	if background:
		background.color = Color.GRAY  # Temporary gray to test visibility
		background.visible = true
		print("TurnIcon: Set temporary gray background")