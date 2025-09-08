extends Node2D

var deck = []
var hand = []
var discard = []
var singleSlashCard = preload("res://Scenes/SingleSlash.tscn")
var doubleSlashCard = preload("res://Scenes/DoubleSlash.tscn")
var healCard = preload("res://Scenes/HealCard.tscn")
var poisonCard = preload("res://Scenes/PoisonCard.tscn")
var hand_node
var deck_visual_node
var deck_count_label
var MAX_HAND_SIZE = 7

func _ready():
	hand_node = get_node("../Hand")
	deck_visual_node = get_node("../DeckVisual")
	deck_count_label = get_node("../DeckVisual/DeckCountLabel")
	print("Card Manager: Hand node found at ", hand_node)
	initialize_deck()
	update_deck_visual()
	draw_starting_hand()

# Draw initial hand of 4 cards
func draw_starting_hand():
	for i in range(4):
		draw_card()

# Initialize deck with cards based on selected class
func initialize_deck():
	# Get starting deck from class manager
	var starting_deck = Global.class_manager.get_starting_deck()
	
	for card_type in starting_deck:
		var count = starting_deck[card_type]
		
		# Add cards of this type to deck
		if card_type in Global.card_types:
			for i in range(count):
				add_card_to_deck(Global.card_types[card_type].new())
		else:
			print("Card Manager: Unknown card type in starting deck: ", card_type)
	
	shuffle_deck()
	print("Card Manager: Deck initialized with ", deck.size(), " cards based on selected class")

# Blander decket
func shuffle_deck():
	deck.shuffle()

# Legger et kort til decket
func add_card_to_deck(card):
	deck.append(card)

# Update the visual representation of the deck
func update_deck_visual():
	if deck_count_label:
		deck_count_label.text = str(deck.size())
	
	# Show/hide deck visual based on whether deck has cards
	if deck_visual_node:
		deck_visual_node.visible = deck.size() > 0

# Trekker et kort fra decket
func draw_card():
	# Check if game is frozen
	if Global.is_game_frozen():
		return false
		
	# Check if hand is already at maximum size
	if hand_node.get_child_count() >= MAX_HAND_SIZE:
		print("Card Manager: Hand is full (", MAX_HAND_SIZE, " cards), cannot draw more")
		return false
		
	if deck.size() == 0:
		# If deck is empty, shuffle the discard pile into the deck
		if discard.size() > 0:
			deck = discard.duplicate()
			discard.clear()
			shuffle_deck()
			print("Card Manager: Shuffled discard pile into deck")
		else:
			print("Card Manager: No cards left to draw!")
			return false

	var card = deck.pop_front()
	hand.append(card)

	# Instantiate the correct card scene based on card type
	var card_instance
	var card_type = card.get_script().get_path()
	if "SingleSlash" in card_type:
		card_instance = singleSlashCard.instantiate()
	elif "DoubleSlash" in card_type: 
		card_instance = doubleSlashCard.instantiate()
	elif "HealCard" in card_type: 
		card_instance = healCard.instantiate()
	elif "PoisonCard" in card_type: 
		card_instance = poisonCard.instantiate()
	else:
		print("Card Manager: Unknown card type: ", card_type)
		return false
	
	hand_node.add_child(card_instance)
	print("Card Manager: Added card to hand at position ", card_instance.position)
	
	# Make sure region_enabled is true for proper sizing
	if card_instance is Sprite2D:
		card_instance.region_enabled = true
	
	# Connect card signals
	if card_instance.has_signal("card_activated"):
		card_instance.connect("card_activated", _on_card_activated)

	arrange_hand()
	update_deck_visual()
	return true

# Draw multiple cards (for end turn) - respects hand size limit
func draw_cards(count: int):
	var cards_drawn = 0
	for i in range(count):
		if draw_card():
			cards_drawn += 1
		else:
			break  # Stop drawing if we can't draw more cards
	
	print("Card Manager: Drew ", cards_drawn, " out of ", count, " requested cards")
	return cards_drawn

# Remove used (grayed out) cards from hand
func remove_used_cards():
	var cards_to_remove = []
	
	# Find all used cards (children of hand_node that are not playable)
	for i in range(hand_node.get_child_count()):
		var card_instance = hand_node.get_child(i)
		if card_instance.has_method("is_card_playable") and not card_instance.is_card_playable():
			cards_to_remove.append(card_instance)
	
	# Remove used cards
	for card in cards_to_remove:
		# Add the corresponding data card to discard pile
		if hand.size() > 0:
			var card_data = hand.pop_front()  # Remove from hand data
			discard.append(card_data)
		
		# Remove the visual card
		card.queue_free()
	
	# Clean up hand data array to match visual cards
	hand.clear()
	for i in range(hand_node.get_child_count()):
		if hand_node.get_child(i) and not hand_node.get_child(i).is_queued_for_deletion():
			# Add a placeholder card - this should match the actual card type in a real implementation
			hand.append(Global.card_types["SingleSlash"].new())
	
	arrange_hand()
	print("Card Manager: Removed ", cards_to_remove.size(), " used cards")

# End turn functionality
func end_turn():
	# Check if game is frozen
	if Global.is_game_frozen():
		print("Card Manager: Cannot end turn - game is frozen")
		return
		
	print("Card Manager: Ending turn")
	remove_used_cards()
	# Wait a frame for cards to be removed
	await get_tree().process_frame
	
	# Calculate how many cards to draw (up to 4, but respect hand size limit)
	var current_hand_size = hand_node.get_child_count()
	var cards_to_draw = min(4, MAX_HAND_SIZE - current_hand_size)
	
	if cards_to_draw > 0:
		var drawn = draw_cards(cards_to_draw)
		print("Card Manager: Turn ended, drew ", drawn, " new cards (hand size: ", current_hand_size + drawn, "/", MAX_HAND_SIZE, ")")
	else:
		print("Card Manager: Turn ended, hand is full - no cards drawn")
	
	# Tell the turn manager that player turn is over
	if Global.turn_manager:
		Global.turn_manager.end_player_turn()

# Plasserer kortene horisontalt i hånden kreft
func arrange_hand():
	for i in range(hand_node.get_child_count()):
		var card_instance = hand_node.get_child(i)
		if card_instance and not card_instance.is_queued_for_deletion():
			var spacing = 150  # Increased spacing between cards
			card_instance.position = Vector2(i * spacing, 0)
			print("Card Manager: Arranged card ", i, " at position ", card_instance.position)
			
			# Update the initial position of the card AFTER arranging it
			if card_instance.has_method("update_initial_position"):
				card_instance.update_initial_position()

# Handle card activation
func _on_card_activated(damage_amount):
	# This will be called when any card is activated
	print("Card Manager: Card activated with damage: ", damage_amount)
	# You can add game logic here like checking if enemy is defeated
