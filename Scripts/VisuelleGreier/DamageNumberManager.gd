extends Node2D

var damage_number_scene = preload("res://Scenes/DamageNumber.tscn")

func _ready():
	# Make this node global so it can be accessed from anywhere
	set_name("DamageNumberManager")

func show_damage(damage: int, world_position: Vector2, color: Color = Color.RED):
	# Create damage number instance
	var damage_number = damage_number_scene.instantiate()
	
	# Add it to the scene tree
	get_tree().current_scene.add_child(damage_number)
	
	# Setup the damage number
	damage_number.setup_damage_number(damage, world_position, color)
	
	print("Damage number spawned: ", damage, " at position: ", world_position)

# Convenience method for standard damage (red)
func show_damage_red(damage: int, world_position: Vector2):
	show_damage(damage, world_position, Color.RED)

# Convenience method for healing (green)
func show_healing(healing: int, world_position: Vector2):
	show_damage(healing, world_position, Color.GREEN)

# Convenience method for critical damage (orange/yellow)
func show_critical_damage(damage: int, world_position: Vector2):
	show_damage(damage, world_position, Color.ORANGE)