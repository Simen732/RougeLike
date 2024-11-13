extends Node2D

# Decks and hand
var deck = []
var hand = []
var discard_pile = []

# Constants for deck size, max hand size, etc.
const MAX_HAND_SIZE = 5

# Initialize the deck with starter cards
func _ready():
	initialize_deck()

func initialize_deck():
	# Here you could create initial cards
	add_card_to_deck(Global.card_types["DamageCard"].new())
	add_card_to_deck(Global.card_types["DamageCard"].new())
	print("hello")
	# Add more starter cards as needed

	shuffle_deck()

func add_card_to_deck(card):
	deck.append(card)

func shuffle_deck():
	deck.shuffle()

func draw_card():
	print("draw card")
	if deck.size() == 0:
		reshuffle_discard_into_deck()

	if deck.size() > 0:
		var drawn_card = deck.pop_front()
		hand.append(drawn_card)
		
		if hand.size() > MAX_HAND_SIZE:
			discard_card(hand.pop_front())
		
		return drawn_card
	return null

func discard_card(card):
	hand.erase(card)
	discard_pile.append(card)

func reshuffle_discard_into_deck():
	deck = discard_pile.duplicate()
	discard_pile.clear()
	shuffle_deck()

