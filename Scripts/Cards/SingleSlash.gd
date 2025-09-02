extends "res://Scripts/Cards/CardBase.gd"

@export var damage_amount = 8  

func _ready():
	# Set the card type for animation purposes
	card_type_name = "SingleSlash"
	# Call parent ready function
	super._ready()
	print("SingleSlash card initialized with damage amount: ", damage_amount)

func activate_card():
	# Call the parent method which handles targeting and animations
	print("SingleSlash card activated!")
	super.activate_card()

func apply_effect_to_target(target):
	# Apply damage to the target
	if target and target.has_method("take_damage"):
		target.take_damage(damage_amount)
		# Emit the signal for any listeners
		emit_signal("card_activated", damage_amount)
		print("SingleSlash: Dealing ", damage_amount, " damage to ", target.name)
		
		# Show damage number
		if Global.damage_number_manager and target.has_method("get_global_position"):
			Global.show_damage_number(damage_amount, target.global_position, Color.RED)

# Provide animation data specific to damage cards
func get_animation_data() -> Dictionary:
	return {
		"damage": damage_amount,
		"effect_type": "damage",
		"sound_volume": 1.0  # Can be adjusted per card if needed
	}
