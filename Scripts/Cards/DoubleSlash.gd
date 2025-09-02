extends "res://Scripts/Cards/CardBase.gd"

@export var damage_amount = 10 

func _ready():
	card_type_name = "DoubleSlash"

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
		target.take_damage(damage_amount)
		emit_signal("card_activated", damage_amount)
		print("DoubleSlash first attack! Dealing ", damage_amount, " damage to ", target.name)
		
		# Show damage number for first attack
		if Global.damage_number_manager and target.has_method("get_global_position"):
			Global.show_damage_number(damage_amount, target.global_position, Color.RED)

		var timer = get_tree().create_timer(0.8)
		await timer.timeout

		if target and is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(damage_amount)
			emit_signal("card_activated", damage_amount)
			print("DoubleSlash second attack! Dealing ", damage_amount, " damage to ", target.name)
			print("DoubleSlash: Both attacks completed - total damage: ", damage_amount * 2)
			
			# Show damage number for second attack
			if Global.damage_number_manager and target.has_method("get_global_position"):
				Global.show_damage_number(damage_amount, target.global_position, Color.ORANGE)
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
