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
	# Apply critical hit calculation to damage
	var crit_result = Global.apply_critical_effect(damage_amount, "damage")
	var final_damage = int(crit_result.value)
	var is_critical = crit_result.is_critical
	
	# Apply damage to the target
	if target and target.has_method("take_damage"):
		target.take_damage(final_damage)
		# Emit the signal for any listeners
		emit_signal("card_activated", final_damage)
		print("SingleSlash: Dealing ", final_damage, " damage to ", target.name, 
			  " (", "CRITICAL! " if is_critical else "", "base: ", damage_amount, ")")
		
		# Show damage number with critical styling
		if Global.damage_number_manager and target.has_method("get_global_position"):
			var damage_color = Color.YELLOW if is_critical else Color.RED
			Global.show_damage_number(final_damage, target.global_position, damage_color)

# Provide animation data specific to damage cards
func get_animation_data() -> Dictionary:
	return {
		"damage": damage_amount,
		"effect_type": "damage",
		"sound_volume": 1.0  # Can be adjusted per card if needed
	}
