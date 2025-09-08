extends Node

var PlayerMaxHealth = 100
var MAX_HAND_SIZE = 7  # Maximum cards in hand

# Global references and configuration
var card_types = {
	"SingleSlash": preload("res://Scripts/Cards/SingleSlash.gd"),
	"DoubleSlash": preload("res://Scripts/Cards/DoubleSlash.gd"),
	"HealCard": preload("res://Scripts/Cards/HealCard.gd"),
	"PoisonCard": preload("res://Scripts/Cards/PoisonCard.gd")
}

# Damage number manager reference
var damage_number_manager: Node2D

# Track enemies in combat
var enemies_in_combat = []
var current_target = null
var registered_enemies = []

# Player reference for animations
var player_character = null

# Audio player for sound effects
var audio_player: AudioStreamPlayer
var master_volume: float = 1.0  # Add volume control

# Turn manager reference
var turn_manager: Node

# Spawn manager reference
var spawn_manager: Node

# Class manager reference
var class_manager: Node

# Game state
var game_frozen: bool = false

# Simple Energy System
var Max_energy: int = 3
var CurrentEnergy: int = 3

# Critical Hit System
var base_crit_chance: float = 0.05  # 5% base crit chance
var base_crit_multiplier: float = 2  # 100% more effect on crit
var player_crit_chance_bonus: float = 0.0  # Additional crit chance from class/items
var player_crit_multiplier_bonus: float = 0.0  # Additional crit multiplier from class/items

func _ready():
	# Initialize turn manager first
	turn_manager = preload("res://Scripts/CombatMechanics/TurnManager.gd").new()
	add_child(turn_manager)
	print("Global: TurnManager initialized")
	
	# Initialize spawn manager
	spawn_manager = preload("res://Scripts/Misc/SpawnManager.gd").new()
	add_child(spawn_manager)
	print("Global: SpawnManager initialized")
	
	# Initialize class manager
	class_manager = preload("res://Scripts/CombatMechanics/ClassManager.gd").new()
	add_child(class_manager)
	print("Global: ClassManager initialized")
	
	# Create an audio player for sound effects
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.volume_db = linear_to_db(master_volume)
	print("Global: Audio system initialized")
	
	# Create and setup damage number manager
	damage_number_manager = preload("res://Scripts/VisuelleGreier/DamageNumberManager.gd").new()
	add_child(damage_number_manager)
	print("Global: DamageNumberManager initialized")

# Register an enemy when it enters combat
func register_enemy(enemy):
	enemies_in_combat.append(enemy)
	registered_enemies.append(enemy)
	# Set as current target if it's the first enemy
	if current_target == null:
		current_target = enemy
	
	# Also register with turn manager
	if turn_manager:
		turn_manager.register_enemy(enemy)
		print("Global: Enemy registered with turn manager - ", enemy.name)

# Remove enemy from combat
func unregister_enemy(enemy):
	enemies_in_combat.erase(enemy)
	registered_enemies.erase(enemy)
	
	# If current target was this enemy, clear it and hide its indicator
	if current_target == enemy:
		# Hide the target indicator before clearing
		if enemy and is_instance_valid(enemy) and enemy.has_method("set_targeted"):
			enemy.set_targeted(false)
		
		# Select a new target from remaining enemies
		if registered_enemies.size() > 0:
			# Find the first alive enemy
			for remaining_enemy in registered_enemies:
				if remaining_enemy and is_instance_valid(remaining_enemy) and remaining_enemy.has_method("is_dead") and not remaining_enemy.is_dead():
					current_target = remaining_enemy
					break
			# If no alive enemies found, clear current_target
			if current_target == enemy:
				current_target = null
		else:
			current_target = null
	
	# Also unregister from turn manager
	if turn_manager:
		turn_manager.unregister_enemy(enemy)
		print("Global: Enemy unregistered from turn manager - ", enemy.name)

# Register player for animations
func register_player(player):
	player_character = player
	print("Global: Player registered for animations")
	
	# Also register with turn manager
	if turn_manager:
		turn_manager.register_player(player)
		print("Global: Player registered with turn manager")

# Game state management
func set_game_frozen(frozen: bool):
	game_frozen = frozen
	print("Global: Game frozen state set to ", frozen)
	
	# Disable turn manager when frozen
	if turn_manager and frozen:
		turn_manager.set_process(false)
		turn_manager.set_physics_process(false)

func is_game_frozen() -> bool:
	return game_frozen

# Handle input for restart/quit when game is frozen
func _input(event):
	if game_frozen and event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			restart_game()
		elif event.keycode == KEY_ESCAPE:
			quit_game()

func restart_game():
	print("Global: Restarting game")
	game_frozen = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func quit_game():
	print("Global: Quitting game")
	get_tree().quit()

# Target management system
func set_current_target(target):
	# Ensure we have a valid target or clear if null
	if not target:
		clear_current_target()
		return
		
	# Clear previous target indicator if switching targets
	if current_target and current_target != target and is_instance_valid(current_target):
		if current_target.has_method("set_targeted"):
			current_target.set_targeted(false)
	
	# Set new target and show indicator
	current_target = target
	if current_target and current_target.has_method("set_targeted"):
		current_target.set_targeted(true)
	
	print("Global: Target set to ", target.name if target else "none")

func get_current_target():
	# Validate current target is still alive and valid
	if current_target:
		if not is_instance_valid(current_target) or (current_target.has_method("is_dead") and current_target.is_dead()):
			current_target = null
	return current_target

func clear_current_target():
	if current_target and is_instance_valid(current_target) and current_target.has_method("set_targeted"):
		current_target.set_targeted(false)
	current_target = null

# Convenience method to show damage numbers
func show_damage_number(damage: int, world_position: Vector2, color: Color = Color.RED):
	if damage_number_manager:
		damage_number_manager.show_damage(damage, world_position, color)

# Trigger player animation based on card type
func trigger_player_animation(card_type: String, animation_data: Dictionary = {}):
	if player_character and player_character.has_method("play_card_animation"):
		player_character.play_card_animation(card_type, animation_data)
		print("Global: Triggered player animation for card type: ", card_type)

# Critical Hit System Functions

# Calculate if an effect should crit based on current crit chance
func calculate_critical_hit() -> bool:
	var total_crit_chance = base_crit_chance + player_crit_chance_bonus
	var roll = randf()
	var is_crit = roll < total_crit_chance
	
	if is_crit:
		print("Global: Critical hit! (rolled ", roll, " vs ", total_crit_chance, ")")
	
	return is_crit

# Get the total critical multiplier
func get_critical_multiplier() -> float:
	return base_crit_multiplier + player_crit_multiplier_bonus

# Apply critical hit effects to any numeric value
func apply_critical_effect(base_value: float, effect_type: String = "damage") -> Dictionary:
	var is_crit = calculate_critical_hit()
	var final_value = base_value
	
	if is_crit:
		var multiplier = get_critical_multiplier()
		final_value = base_value * multiplier
		
		print("Global: Critical ", effect_type, "! ", base_value, " -> ", final_value, " (x", multiplier, ")")
	
	return {
		"value": final_value,
		"is_critical": is_crit,
		"multiplier": get_critical_multiplier() if is_crit else 1.0,
		"original_value": base_value
	}

# Apply critical hit to duration-based effects (status conditions, buffs, etc.)
func apply_critical_duration(base_duration: float, effect_name: String = "effect") -> Dictionary:
	var is_crit = calculate_critical_hit()
	var final_duration = base_duration
	
	if is_crit:
		# For durations, we add the crit multiplier as extra turns/seconds
		var bonus_duration = base_duration * (get_critical_multiplier() - 1.0)
		final_duration = base_duration + bonus_duration
		
		print("Global: Critical ", effect_name, " duration! ", base_duration, " -> ", final_duration, " turns")
	
	return {
		"duration": final_duration,
		"is_critical": is_crit,
		"multiplier": get_critical_multiplier() if is_crit else 1.0,
		"original_duration": base_duration
	}

# Modify player's crit stats (called by classes, items, etc.)
func modify_crit_chance(bonus: float):
	player_crit_chance_bonus += bonus
	player_crit_chance_bonus = clamp(player_crit_chance_bonus, 0.0, 0.95)  # Cap at 95%
	print("Global: Crit chance bonus set to ", player_crit_chance_bonus, " (total: ", (base_crit_chance + player_crit_chance_bonus) * 100, "%)")

func modify_crit_multiplier(bonus: float):
	player_crit_multiplier_bonus += bonus
	print("Global: Crit multiplier bonus set to ", player_crit_multiplier_bonus, " (total: ", base_crit_multiplier + player_crit_multiplier_bonus, "x)")

func reset_crit_bonuses():
	player_crit_chance_bonus = 0.0
	player_crit_multiplier_bonus = 0.0
	print("Global: Reset crit bonuses to defaults")

# Simple Energy System Functions

# Reset energy to max at start of turn
func reset_energy():
	CurrentEnergy = Max_energy
	print("Global: Energy reset to ", CurrentEnergy, " (Max: ", Max_energy, ")")
	
	# Also try to update energy display directly
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("update_energy_display"):
		main_scene.update_energy_display()
		print("Global: Called update_energy_display from reset_energy")

# Check if player has enough energy to play a card
func can_afford_card(energy_cost: int) -> bool:
	return CurrentEnergy >= energy_cost

# Spend energy when playing a card
func spend_energy(energy_cost: int) -> bool:
	if can_afford_card(energy_cost):
		CurrentEnergy -= energy_cost
		print("Global: Spent ", energy_cost, " energy. Remaining: ", CurrentEnergy)
		return true
	else:
		print("Global: Not enough energy! Need ", energy_cost, ", have ", CurrentEnergy)
		return false

# Get current energy values
func get_current_energy() -> int:
	return CurrentEnergy

func get_max_energy() -> int:
	return Max_energy
