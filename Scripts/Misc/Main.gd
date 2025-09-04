extends Node2D
@onready var progress_bar = $Player/ProgressBar
@onready var card_manager = $CardManager
@onready var end_turn_button = $EndTurnButton
@onready var player = $Player

var enemy_spawners = []

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set up the combat scene
	setup_combat()
	# Connect the end turn button
	if end_turn_button:
		end_turn_button.connect("pressed", _on_end_turn_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

# Setup the combat scene, connecting cards to enemies
func setup_combat():
	# Find all enemy spawners in the scene
	find_enemy_spawners()
	
	# Generate and spawn enemies
	spawn_encounter()
	
	# Make sure player is registered for animations
	if player:
		Global.register_player(player)

func find_enemy_spawners():
	enemy_spawners.clear()
	# Search for EnemySpawner nodes in the scene
	_find_spawners_recursive(self)
	
	print("Main: Found ", enemy_spawners.size(), " enemy spawners")

func _find_spawners_recursive(node: Node):
	# Check if this node is an EnemySpawner
	if node.get_script() and node.get_script().resource_path.contains("EnemySpawner.gd"):
		enemy_spawners.append(node)
	
	# Check children
	for child in node.get_children():
		_find_spawners_recursive(child)

func spawn_encounter():
	if enemy_spawners.is_empty():
		print("Main: No enemy spawners found in scene!")
		return
	
	# Generate encounter using SpawnManager
	var encounter = Global.spawn_manager.generate_encounter()
	
	if encounter.is_empty():
		print("Main: No enemies generated for encounter!")
		return
	
	# Reset all spawners
	for spawner in enemy_spawners:
		spawner.reset_spawner()
	
	# Assign enemies to random spawners
	var available_spawners = enemy_spawners.duplicate()
	available_spawners.shuffle()
	
	for i in range(min(encounter.size(), available_spawners.size())):
		var enemy_data = encounter[i]
		var spawner = available_spawners[i]
		
		var spawned_enemy = spawner.spawn_enemy(enemy_data)
		if spawned_enemy:
			print("Main: Successfully spawned ", enemy_data.enemy_name, " at spawner ", spawner.get_spawner_id())
		else:
			print("Main: Failed to spawn ", enemy_data.enemy_name, " at spawner ", spawner.get_spawner_id())

# Handle end turn button press
func _on_end_turn_pressed():
	print("Main: End turn button pressed")
	if card_manager:
		card_manager.end_turn()
