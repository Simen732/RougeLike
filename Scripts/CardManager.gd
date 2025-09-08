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
	initialize_deck()
	update_deck_visual()
	draw_starting_hand()

func draw_starting_hand():
	for i in range(4):
		draw_card()

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

func shuffle_deck():
	deck.shuffle()

func add_card_to_deck(card):
	deck.append(card)

func update_deck_visual():
	if deck_count_label:
		deck_count_label.text = str(deck.size())
	
	if deck_visual_node:
		deck_visual_node.visible = deck.size() > 0

func draw_card():
	if Global.is_game_frozen():
		return false
		
	if hand_node.get_child_count() >= MAX_HAND_SIZE:
		return false
		
	if deck.size() == 0:
		if discard.size() > 0:
			deck = discard.duplicate()
			discard.clear()
			shuffle_deck()
		else:
			return false

	var card = deck.pop_front()
	hand.append(card)

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
	
	if card_instance is Sprite2D:
		card_instance.region_enabled = true
	
	if card_instance.has_signal("card_activated"):
		card_instance.connect("card_activated", _on_card_activated)

	arrange_hand()
	update_deck_visual()
	return true

func draw_cards(count: int):
	var cards_drawn = 0
	for i in range(count):
		if draw_card():
			cards_drawn += 1
		else:
			break
	return cards_drawn

func remove_used_cards():
	var cards_to_remove = []
	
	for i in range(hand_node.get_child_count()):
		var card_instance = hand_node.get_child(i)
		if card_instance.has_method("is_card_playable") and not card_instance.is_card_playable():
			cards_to_remove.append(card_instance)
	
	for card in cards_to_remove:
		if hand.size() > 0:
			var card_data = hand.pop_front()
			discard.append(card_data)
		card.queue_free()
	
	hand.clear()
	for i in range(hand_node.get_child_count()):
		if hand_node.get_child(i) and not hand_node.get_child(i).is_queued_for_deletion():
			hand.append(Global.card_types["SingleSlash"].new())
	
	arrange_hand()

func end_turn():
	if Global.is_game_frozen():
		return
		
	remove_used_cards()
	await get_tree().process_frame
	
	var current_hand_size = hand_node.get_child_count()
	var cards_to_draw = min(4, MAX_HAND_SIZE - current_hand_size)
	
	if cards_to_draw > 0:
		draw_cards(cards_to_draw)
	
	if Global.turn_manager:
		Global.turn_manager.end_player_turn()

func arrange_hand():
	for i in range(hand_node.get_child_count()):
		var card_instance = hand_node.get_child(i)
		if card_instance and not card_instance.is_queued_for_deletion():
			var spacing = 150
			card_instance.position = Vector2(i * spacing, 0)
			
			if card_instance.has_method("update_initial_position"):
				card_instance.update_initial_position()

func _on_card_activated(_damage_amount):
	pass
