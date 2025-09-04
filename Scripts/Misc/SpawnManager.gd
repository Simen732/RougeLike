extends Node

# Enemy pools and encounter settings
var enemy_pool = []
var current_encounter_level: int = 1
var min_enemies_per_encounter: int = 1
var max_enemies_per_encounter: int = 3

# Value-based encounter balancing
var base_encounter_value: int = 50  # Base difficulty value
var encounter_value_variance: int = 10  # ±10 variance (40-60 range)
var max_attempts: int = 100  # Safety limit for generation attempts

func _ready():
	initialize_enemy_pool()

func initialize_enemy_pool():
	# Create enemy data entries with cost values
	var slime_data = EnemyData.new(
		"Slime",
		preload("res://Scenes/Slime.tscn"),
		2,  # Higher weight = more common
		1,  # Available from level 1
		2,  # Max 2 slimes per encounter
		10  # Cost: 10 points
	)
	
	var slime2_data = EnemyData.new(
		"Slime2", 
		preload("res://Scenes/Slime2.tscn"),
		1,  # Lower weight = less common
		1,  # Available from level 1
		2,  # Max 2 strong slimes per encounter
		20  # Cost: 20 points (stronger)
	)
	
	var slime3_data = EnemyData.new(
		"Slime3",
		preload("res://Scenes/Slime3.tscn"),
		2,  # Medium weight
		1,  # Available from level 1
		5,  # Max 5 fast slimes per encounter
		10  # Cost: 10 points (same as slime but different stats)
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
	
	# Calculate target value for this encounter
	var target_value = base_encounter_value + randi_range(-encounter_value_variance, encounter_value_variance)
	print("SpawnManager: Generating encounter with target value: ", target_value)
	
	var encounter = generate_value_based_encounter(target_value)
	
	if encounter.is_empty():
		print("SpawnManager: Failed to generate encounter, falling back to simple generation")
		encounter = generate_simple_fallback()
	
	print("SpawnManager: Generated encounter: ", get_encounter_summary(encounter))
	return encounter

func generate_value_based_encounter(target_value: int) -> Array:
	var encounter = []
	var current_value = 0
	var enemy_type_counts = {}
	var attempts = 0
	
	while current_value < target_value and attempts < max_attempts:
		attempts += 1
		
		# Get available enemies that don't exceed our limits
		var available_enemies = get_available_enemies(enemy_type_counts, target_value - current_value)
		
		if available_enemies.is_empty():
			break
		
		# Select enemy using weighted random selection
		var selected_enemy = select_weighted_enemy(available_enemies)
		if not selected_enemy:
			break
		
		# Add to encounter
		encounter.append(selected_enemy)
		current_value += selected_enemy.cost
		
		# Update count tracking
		if selected_enemy.enemy_name in enemy_type_counts:
			enemy_type_counts[selected_enemy.enemy_name] += 1
		else:
			enemy_type_counts[selected_enemy.enemy_name] = 1
		
		print("SpawnManager: Added ", selected_enemy.enemy_name, " (cost: ", selected_enemy.cost, "), total value: ", current_value, "/", target_value)
	
	print("SpawnManager: Encounter generation completed in ", attempts, " attempts, final value: ", current_value, "/", target_value)
	return encounter

func get_available_enemies(current_counts: Dictionary, remaining_value: int) -> Array:
	var available = []
	
	for enemy_data in enemy_pool:
		# Check level requirement
		if enemy_data.min_encounter_level > current_encounter_level:
			continue
		
		# Check count limit
		var current_count = current_counts.get(enemy_data.enemy_name, 0)
		if current_count >= enemy_data.max_count_per_encounter:
			continue
		
		# Check if cost fits within remaining value
		if enemy_data.cost > remaining_value:
			continue
		
		available.append(enemy_data)
	
	return available

func select_weighted_enemy(available_enemies: Array):
	if available_enemies.is_empty():
		return null
	
	var total_weight = 0
	for enemy_data in available_enemies:
		total_weight += enemy_data.spawn_weight
	
	var random_value = randi_range(1, total_weight)
	var current_weight = 0
	
	for enemy_data in available_enemies:
		current_weight += enemy_data.spawn_weight
		if random_value <= current_weight:
			return enemy_data
	
	return available_enemies[0]  # Fallback

func generate_simple_fallback() -> Array:
	var encounter = []
	var enemy_count = randi_range(min_enemies_per_encounter, max_enemies_per_encounter)
	var enemy_type_counts = {}
	
	for i in range(enemy_count):
		var selected_enemy = select_random_enemy(enemy_type_counts)
		if selected_enemy:
			encounter.append(selected_enemy)
			if selected_enemy.enemy_name in enemy_type_counts:
				enemy_type_counts[selected_enemy.enemy_name] += 1
			else:
				enemy_type_counts[selected_enemy.enemy_name] = 1
	
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