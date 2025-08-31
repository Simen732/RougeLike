extends Node2D
@onready var progress_bar = $CharacterBody2D/ProgressBar
@onready var slime = $Slime
@onready var card_manager = $CardManager
@onready var end_turn_button = $EndTurnButton
@onready var player = $CharacterBody2D

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set up the combat scene
	setup_combat()
	# Connect the end turn button
	if end_turn_button:
		end_turn_button.connect("pressed", _on_end_turn_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Setup the combat scene, connecting cards to enemies
func setup_combat():
	# Make sure enemies are registered with Global
	if slime and not slime.Dead:
		# Enemy should self-register in its _ready function
		pass
	
	# Make sure player is registered for animations
	if player:
		Global.register_player(player)

# Handle end turn button press
func _on_end_turn_pressed():
	print("Main: End turn button pressed")
	if card_manager:
		card_manager.end_turn()
