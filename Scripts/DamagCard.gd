# DamageCard.gd
extends "res://Scripts/CardBase.gd"  # Replace with the actual path to BaseCard.gd

@export var damage_amount := 10  # Damage specific to this card ty

func _ready():
	# Set the card type for animation purposes
	card_type_name = "DamageCard"
	# Call parent ready function
	super._ready()
	print("Damage card initialized with damage amount: ", damage_amount)

func activate_card():
	# Call the parent method which handles targeting and animations
	print("Damage card activated!")
	super.activate_card()

func apply_effect_to_target(target):
	# Apply damage to the target
	if target and target.has_method("take_damage"):
		target.take_damage(damage_amount)
		# Emit the signal for any listeners
		emit_signal("card_activated", damage_amount)
		print("Damage Card activated! Dealing ", damage_amount, " damage to ", target.name)

# Provide animation data specific to damage cards
func get_animation_data() -> Dictionary:
	return {
		"damage": damage_amount,
		"effect_type": "damage",
		"sound_volume": 1.0  # Can be adjusted per card if needed
	}

