extends Node2D

var deck = []
var hand = []
var damageCard = preload("res://Scenes/DamagCard.tscn")
var hand_node

	# Initialiserer decket og gir spileren to kort
func _ready():
	hand_node = get_node("../Hand")
	print(hand_node)
	initialize_deck()
	for i in range(7):
		draw_card()

	# Legger til to DamageCards i decket
func initialize_deck():
	add_card_to_deck(Global.card_types["DamageCard"].new())
	add_card_to_deck(Global.card_types["DamageCard"].new())
	shuffle_deck()

	# Blander decket
func shuffle_deck():
	deck.shuffle()

	# Legger et kort til decket
func add_card_to_deck(card):
	deck.append(card)

	# Trekker et kort fra decket
func draw_card():

	var card = deck.pop_front()
	hand.append(card)

	var card_instance = damageCard.instantiate()
	hand_node.add_child(card_instance)

	arrange_hand()

	# Plasserer kortene horisontalt i hånden kreft
func arrange_hand():
	for i in range(hand.size()):
		var card_instance = hand_node.get_child(i)
		card_instance.position = Vector2(i * 100, 0)
