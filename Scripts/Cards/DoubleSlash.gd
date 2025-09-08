extends "res://Scripts/Cards/CardBase.gd"

@export var damage_amount = 10 

func _ready():
	card_type_name = "DoubleSlash"
	energy_cost = 2  # Double attack costs more energy

	super._ready()
	print("DoubleSlash card initialized with damage amount: ", damage_amount)

func activate_card():
	print("DoubleSlash card activated!")
	super.activate_card()

func apply_effect_to_target(target):
	if not target or not target.has_method("take_damage"):
		print("DoubleSlash: Invalid target")
		return
	
	print("DoubleSlash: Starting double attack sequence")
	_perform_double_attack(target)

func _perform_double_attack(target):
	if target and target.has_method("take_damage"):
		# First attack with crit calculation
		var crit_result_1 = Global.apply_critical_effect(damage_amount, "damage")
		var final_damage_1 = int(crit_result_1.value)
		var is_critical_1 = crit_result_1.is_critical
		
		target.take_damage(final_damage_1)
		emit_signal("card_activated", final_damage_1)
		print("DoubleSlash first attack! Dealing ", final_damage_1, " damage to ", target.name,
			  " (", "CRITICAL! " if is_critical_1 else "", "base: ", damage_amount, ")")
		
		# Show damage number for first attack
		if Global.damage_number_manager and target.has_method("get_global_position"):
			var damage_color_1 = Color.YELLOW if is_critical_1 else Color.RED
			Global.show_damage_number(final_damage_1, target.global_position, damage_color_1)

		var timer = get_tree().create_timer(0.8)
		await timer.timeout

		if target and is_instance_valid(target) and target.has_method("take_damage"):
			# Second attack with separate crit calculation
			var crit_result_2 = Global.apply_critical_effect(damage_amount, "damage")
			var final_damage_2 = int(crit_result_2.value)
			var is_critical_2 = crit_result_2.is_critical
			
			target.take_damage(final_damage_2)
			emit_signal("card_activated", final_damage_2)
			print("DoubleSlash second attack! Dealing ", final_damage_2, " damage to ", target.name,
				  " (", "CRITICAL! " if is_critical_2 else "", "base: ", damage_amount, ")")
			print("DoubleSlash: Both attacks completed - total damage: ", final_damage_1 + final_damage_2)
			
			# Show damage number for second attack
			if Global.damage_number_manager and target.has_method("get_global_position"):
				var damage_color_2 = Color.YELLOW if is_critical_2 else Color.ORANGE
				Global.show_damage_number(final_damage_2, target.global_position, damage_color_2)
		else:
			print("DoubleSlash: Target no longer valid for second attack")
	else:
		print("DoubleSlash: Target invalid for first attack")

func get_animation_data() -> Dictionary:
	return {
		"damage": damage_amount,
		"effect_type": "damage",
		"sound_volume": 1.0  
	}
