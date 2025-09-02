extends Label

@export var float_speed = 100.0
@export var fade_duration = 1.5
@export var float_distance = 50.0

var tween: Tween

func _ready():
	# Set initial properties
	modulate.a = 1.0
	z_index = 100  # Make sure it appears above other elements
	
	# Start the floating animation
	animate_damage_number()

func setup_damage_number(damage: int, start_position: Vector2, color: Color = Color.RED):
	text = str(damage)
	position = start_position
	modulate = color
	
	# Make the text bold and larger
	add_theme_font_size_override("font_size", 24)
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_shadow_color", Color.BLACK)
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)

func animate_damage_number():
	# Create tween for animation
	tween = create_tween()
	tween.set_parallel(true)  # Allow multiple animations at once
	
	# Float upward
	var target_position = position + Vector2(0, -float_distance)
	tween.tween_property(self, "position", target_position, fade_duration).set_ease(Tween.EASE_OUT)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, fade_duration).set_ease(Tween.EASE_IN)
	
	# Scale effect (start big, shrink to normal, then shrink more)
	scale = Vector2(1.5, 1.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), fade_duration - 0.2).set_ease(Tween.EASE_IN).set_delay(0.2)
	
	# Remove the damage number after animation
	tween.tween_callback(queue_free).set_delay(fade_duration)