extends Node

var available_classes = []
var selected_class = null

func _ready():
	initialize_classes()

func initialize_classes():
	# Create default "Warrior" class
	var warrior_class = PlayerClass.new(
		"Warrior",
		"A balanced fighter with good health and standard attacks.",
		null,  # TODO: Add class icon
		100,   # Base health
		12     # Base speed
	)
	warrior_class.starting_cards = {
		"SingleSlash": 15,
		"DoubleSlash": 5
	}
	warrior_class.special_abilities = ["Battle Stance"]
	warrior_class.sprite_scale = Vector2(1.8,1.8)  # Make warrior smaller
	
	# Create "Berserker" class (example of different class)
	var berserker_class = PlayerClass.new(
		"Berserker",
		"High damage, low health. Aggressive playstyle.",
		null,  # TODO: Add class icon
		80,    # Lower health
		15     # Higher speed
	)
	berserker_class.starting_cards = {
		"SingleSlash": 10,
		"DoubleSlash": 10  # More aggressive cards
	}
	berserker_class.special_abilities = ["Rage", "Bloodlust"]
	berserker_class.passive_effects = {"damage_bonus": 0.2}
	berserker_class.sprite_scale = Vector2(0.6, 0.6)  # Slightly bigger than warrior
	
	# Create "Guardian" class (example of tanky class)
	var guardian_class = PlayerClass.new(
		"Guardian",
		"High health, defensive abilities. Protects and endures.",
		null,  # TODO: Add class icon
		150,   # Higher health
		8      # Lower speed
	)
	guardian_class.starting_cards = {
		"SingleSlash": 12,
		"DoubleSlash": 3
		# TODO: Add defensive cards when created
	}
	
	guardian_class.special_abilities = ["Shield Wall", "Taunt"]
	guardian_class.passive_effects = {"damage_reduction": 0.1}
	guardian_class.sprite_scale = Vector2(0.7, 0.7)  # Bigger, tankier looking

		# Create "Samurai" class (example of agile class)
	var samurai_class = PlayerClass.new(
		"Samurai",
		"Fast and precise. Excels at dealing damage quickly.",
		null,  # TODO: Add class icon
		100,   # Standard health
		12     # Higher speed
	)

	samurai_class.starting_cards = {
		"SingleSlash": 5,
		"DoubleSlash": 5,
		"HealCard": 3,
		"PoisonCard": 5,
		"poison_slash": 5
	}
	samurai_class.special_abilities = ["Quick Strike", "Dodge"]
	samurai_class.passive_effects = {"crit_chance": 0.1}
	samurai_class.sprite_scale = Vector2(8, 8)
	
	available_classes.append(warrior_class)
	available_classes.append(berserker_class)
	available_classes.append(guardian_class)
	available_classes.append(samurai_class)

	print("ClassManager: Initialized ", available_classes.size(), " classes")

func get_available_classes():
	return available_classes

func select_class(class_index: int):
	if class_index >= 0 and class_index < available_classes.size():
		selected_class = available_classes[class_index]
		print("ClassManager: Selected class ", selected_class.player_class_name)
	else:
		print("ClassManager: Invalid class index ", class_index)

func get_selected_class():
	return selected_class

func apply_class_to_player(player: Node):
	if selected_class:
		selected_class.apply_to_player(player)
		print("ClassManager: Applied class ", selected_class.player_class_name, " to player")

func get_starting_deck() -> Dictionary:
	if selected_class:
		return selected_class.get_starting_deck()
	else:
		# Default deck
		return {
			"SingleSlash": 15,
			"DoubleSlash": 5
		}
