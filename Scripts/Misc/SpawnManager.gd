extends Node

# Enemy pools and encounter settings
var enemy_pool = []
var current_encounter_level: int = 1
var min_enemies_per_encounter: int = 1
var max_enemies_per_encounter: int = 3

func _ready():
	initialize_enemy_pool()

func initialize_enemy_pool():
	# Note: You'll need to create these scene files or update paths to match your existing scenes
	# For now, using placeholder paths - update these to match your actual enemy scene files
	var slime_data = EnemyData.new(
		"Slime",
		preload("res://Scenes/Slime.tscn"),
		3,  # Higher weight = more common
		1,  # Available from level 1
		2   # Max 2 slimes per encounter
	)
	
	var slime2_data = EnemyData.new(
		"Slime2", 
		preload("res://Scenes/Slime2.tscn"),
		1,  # Lower weight = less common
		1,  # Available from level 1
		1   # Max 1 strong slime per encounter
	)
	
	var slime3_data = EnemyData.new(
		"Slime3",
		preload("res://Scenes/Slime3.tscn"),
		4,  # Medium weight
		1,  # Available from level 1
		2   # Max 2 fast slimes per encounter
	)
	
	# Only add enemies with valid scenes
	if slime_data.enemy_scene:
		enemy_pool.append(slime_data)
	if slime2_data.enemy_scene:
		enemy_pool.append(slime2_data)
	if slime3_data.enemy_scene:
		enemy_pool.append(slime3_data)
	
	print("SpawnManager: Enemy pool initialized with ", enemy_pool.size(), " enemy types")

func generate_encounter() -> Array:
	if enemy_pool.is_empty():
		print("SpawnManager: No enemies in pool - please configure enemy scenes")
		return []
		
	var encounter = []
	var enemy_count = randi_range(min_enemies_per_encounter, max_enemies_per_encounter)
	var enemy_type_counts = {}  # Track how many of each type we've spawned
	
	print("SpawnManager: Generating encounter with ", enemy_count, " enemies")
	
	for i in range(enemy_count):
		var selected_enemy = select_random_enemy(enemy_type_counts)
		if selected_enemy:
			encounter.append(selected_enemy)
			# Track count for this enemy type
			if selected_enemy.enemy_name in enemy_type_counts:
				enemy_type_counts[selected_enemy.enemy_name] += 1
			else:
				enemy_type_counts[selected_enemy.enemy_name] = 1
	
	print("SpawnManager: Generated encounter: ", get_encounter_summary(encounter))
	return encounter

func select_random_enemy(current_counts: Dictionary):
	var available_enemies = []
	var total_weight = 0
	
	# Filter enemies by level and count limits
	for enemy_data in enemy_pool:
		if enemy_data.min_encounter_level <= current_encounter_level:
			var current_count = current_counts.get(enemy_data.enemy_name, 0)
			if current_count < enemy_data.max_count_per_encounter:
				available_enemies.append(enemy_data)
				total_weight += enemy_data.spawn_weight
	
	if available_enemies.is_empty():
		print("SpawnManager: No available enemies for current constraints")
		return null
	
	# Weighted random selection
	var random_value = randi_range(1, total_weight)
	var current_weight = 0
	
	for enemy_data in available_enemies:
		current_weight += enemy_data.spawn_weight
		if random_value <= current_weight:
			return enemy_data
	
	# Fallback to first available enemy
	return available_enemies[0]

func get_encounter_summary(encounter: Array) -> String:
	var summary = {}
	for enemy_data in encounter:
		if enemy_data.enemy_name in summary:
			summary[enemy_data.enemy_name] += 1
		else:
			summary[enemy_data.enemy_name] = 1
	
	var result = ""
	for enemy_name in summary:
		if result != "":
			result += ", "
		result += str(summary[enemy_name]) + "x " + enemy_name
	
	return result

func set_encounter_level(level: int):
	current_encounter_level = level
	print("SpawnManager: Encounter level set to ", level)