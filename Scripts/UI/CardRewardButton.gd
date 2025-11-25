extends Button

@onready var card_name_label = $VBoxContainer/CardNameLabel
@onready var card_description_label = $VBoxContainer/CardDescriptionLabel
@onready var selection_border = $SelectionBorder

var card_type: String = ""
var victory_screen_reference = null
var is_selected: bool = false

func _ready():
	connect("pressed", _on_card_reward_pressed)
	custom_minimum_size = Vector2(200, 120)
	
	# Style the button
	add_theme_font_size_override("font_size", 16)
	
	# Style the labels
	if card_name_label:
		card_name_label.add_theme_font_size_override("font_size", 18)
		card_name_label.add_theme_color_override("font_color", Color.WHITE)
	
	if card_description_label:
		card_description_label.add_theme_font_size_override("font_size", 12)
		card_description_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)

func setup_card_reward(p_card_type: String, victory_screen):
	card_type = p_card_type
	victory_screen_reference = victory_screen
	
	# Update display
	update_card_display()
	
	# Hide selection border initially
	if selection_border:
		selection_border.visible = false

func update_card_display():
	if card_name_label:
		card_name_label.text = get_card_display_name(card_type)
	
	if card_description_label:
		card_description_label.text = get_card_description(card_type)

func get_card_display_name(type: String) -> String:
	match type:
		"SingleSlash":
			return "Single Slash"
		"DoubleSlash":
			return "Double Slash"
		"HealCard":
			return "Heal"
		"PoisonCard":
			return "Poison"
		"poison_slash":
			return "Poison Slash"
		_:
			return type

func get_card_description(type: String) -> String:
	match type:
		"SingleSlash":
			return "Deal 8 damage"
		"DoubleSlash":
			return "Deal 10 damage twice"
		"HealCard":
			return "Heal 15 HP"
		"PoisonCard":
			return "Apply poison for 3 turns"
		"poison_slash":
			return "Deal 8 damage + poison"
		_:
			return "Unknown card"

func _on_card_reward_pressed():
	if victory_screen_reference and victory_screen_reference.has_method("on_card_reward_selected"):
		victory_screen_reference.on_card_reward_selected(card_type, self)

func set_selected(selected: bool):
	is_selected = selected
	
	if selection_border:
		selection_border.visible = is_selected
	
	# Change button appearance based on selection
	if is_selected:
		modulate = Color(1.2, 1.2, 0.8)  # Slightly yellow tint
	else:
		modulate = Color.WHITE

func get_card_type() -> String:
	return card_type