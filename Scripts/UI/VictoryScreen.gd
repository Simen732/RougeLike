extends Control

@onready var victory_label = $VBoxContainer/VictoryLabel
@onready var rewards_container = $VBoxContainer/RewardsContainer
@onready var card_rewards_container = $VBoxContainer/RewardsContainer/CardRewardsContainer
@onready var continue_button = $VBoxContainer/ContinueButton

var card_reward_scene = preload("res://Scenes/UI/CardRewardButton.tscn")
var available_card_rewards = []
var selected_card_rewards = []
var max_card_choices = 3
var cards_to_select = 1

signal continue_pressed()

func _ready():
	continue_button.connect("pressed", _on_continue_button_pressed)
	# continue_button.disabled = true  # Disable until player makes selections
	
	# Style the victory label
	if victory_label:
		victory_label.add_theme_font_size_override("font_size", 48)
		victory_label.add_theme_color_override("font_color", Color.GOLD)
	
	# Hide initially
	visible = false

func show_victory_screen():
	visible = true
	generate_card_rewards()
	
	# Animate the victory screen appearance
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func generate_card_rewards():
	# Clear existing rewards
	for child in card_rewards_container.get_children():
		child.queue_free()
	
	available_card_rewards.clear()
	selected_card_rewards.clear()
	
	# Get all possible card types
	var all_card_types = Global.card_types.keys()
	
	# Randomly select cards for rewards
	var shuffled_cards = all_card_types.duplicate()
	shuffled_cards.shuffle()
	
	for i in range(min(max_card_choices, shuffled_cards.size())):
		var card_type = shuffled_cards[i]
		available_card_rewards.append(card_type)
		
		# Create reward button
		var reward_button = card_reward_scene.instantiate()
		card_rewards_container.add_child(reward_button)
		
		# Setup the reward button
		if reward_button.has_method("setup_card_reward"):
			reward_button.setup_card_reward(card_type, self)
	
	print("VictoryScreen: Generated ", available_card_rewards.size(), " card reward options")

func on_card_reward_selected(card_type: String, reward_button: Node):
	if card_type in selected_card_rewards:
		# Deselect
		selected_card_rewards.erase(card_type)
		reward_button.set_selected(false)
		continue_button.text = "Make up your mind lol (continue with no cards?)"
	else:
		# Check if we can select more cards
		continue_button.text = "Continue with cards ig"
		if selected_card_rewards.size() < cards_to_select:
			selected_card_rewards.append(card_type)
			reward_button.set_selected(true)
		else:
			# Replace the oldest selection
			var old_card = selected_card_rewards[0]
			selected_card_rewards.remove_at(0)
			selected_card_rewards.append(card_type)
			
			# Update button states
			for child in card_rewards_container.get_children():
				if child.has_method("get_card_type") and child.get_card_type() == old_card:
					child.set_selected(false)
			reward_button.set_selected(true)
	
	# Enable continue button if we have enough selections
	# continue_button.disabled = selected_card_rewards.size() < cards_to_select
	
	print("VictoryScreen: Selected cards: ", selected_card_rewards)

func _on_continue_button_pressed():
	# Add selected cards to player's deck
	apply_card_rewards()
	
	# Hide victory screen
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	emit_signal("continue_pressed")

func apply_card_rewards():
	# Add selected cards to the player's deck via CardManager
	var card_manager = get_tree().current_scene.get_node_or_null("CardManager")
	if card_manager and card_manager.has_method("add_cards_to_deck"):
		for card_type in selected_card_rewards:
			card_manager.add_cards_to_deck(card_type, 1)
			print("VictoryScreen: Added ", card_type, " to player's deck")
	else:
		print("VictoryScreen: Warning - Could not find CardManager to add rewards")