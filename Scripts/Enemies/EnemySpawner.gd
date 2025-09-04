@tool
extends Node2D
class_name EnemySpawner

@export var spawner_id: int = 0  # Unique identifier for this spawner
var has_spawned: bool = false

func _ready():
	# Manual ID assignment (uncomment and set as needed if export doesn't work)
	# spawner_id = 0  # Set this manually for each spawner: 0, 1, 2, 3, 4
	
	# Visual indicator that this is a spawner (optional)
	visible = false  # Hide spawners in game
	print("EnemySpawner: Spawner ", spawner_id, " initialized")

func spawn_enemy(enemy_data) -> Node:
	if has_spawned:
		print("EnemySpawner: Warning - Spawner ", spawner_id, " has already spawned an enemy")
		return null
	
	if not enemy_data or not enemy_data.enemy_scene:
		print("EnemySpawner: Invalid enemy data provided to spawner ", spawner_id)
		return null
	
	# Instantiate the enemy
	var enemy_instance = enemy_data.enemy_scene.instantiate()
	if not enemy_instance:
		print("EnemySpawner: Failed to instantiate enemy scene for ", enemy_data.enemy_name)
		return null
	
	# Set enemy position to spawner position
	enemy_instance.global_position = global_position
	
	# Add to scene tree
	get_parent().add_child(enemy_instance)
	
	has_spawned = true
	print("EnemySpawner: Spawned ", enemy_data.enemy_name, " at position ", global_position)
	
	return enemy_instance

func reset_spawner():
	has_spawned = false

func is_available() -> bool:
	return not has_spawned

func get_spawner_id() -> int:
	return spawner_id

func set_spawner_id(id: int):
	spawner_id = id