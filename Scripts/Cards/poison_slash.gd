extends "res://Scripts/Cards/CardBase.gd"

@export var poison_damage = 5
@export var poison_duration = 3
@export var damage_amount = 8
func _ready():
	card_type_name = "poison_slash"
	super._ready()
	print("poison_slash initialized with ", poison_damage, " damage for ", poison_duration, " turns")

func activate_card():
	print("poison_slash activated!")
	super.activate_card()

func apply_effect_to_target(target):
	if target and target.has_method("apply_status_effect"):
		# Apply critical hit calculation to duration
		var crit_result_duration = Global.apply_critical_duration(poison_duration, "poison")
		var final_duration = int(crit_result_duration.duration)
		var is_critical_duration = crit_result_duration.is_critical
		
		# Apply critical hit calculation to damage
		var crit_result_damage = Global.apply_critical_effect(damage_amount, "damage")
		var final_damage = int(crit_result_damage.value)
		var is_critical_damage = crit_result_damage.is_critical
		
		# Apply status effect (poison)
		target.apply_status_effect("poison", poison_damage, final_duration)
		
		# Apply direct damage
		if target and target.has_method("take_damage"):
			target.take_damage(final_damage)
			emit_signal("card_activated", final_damage)
			print("poison_slash: Dealing ", final_damage, " damage to ", target.name, 
				  " (", "CRITICAL! " if is_critical_damage else "", "base: ", damage_amount, ")")
		
		print("poison_slash: Applied poison (", poison_damage, " dmg/turn) for ", final_duration, " turns",
			  " (", "CRITICAL! " if is_critical_duration else "", "base: ", poison_duration, " turns)")
		
		# Show status effect indicator
		if Global.damage_number_manager and target.has_method("get_global_position"):
			var status_color = Color.PURPLE if is_critical_duration else Color.DARK_GREEN
			Global.show_damage_number(final_duration, target.global_position, status_color)
			
			# Show damage number
			var damage_color = Color.YELLOW if is_critical_damage else Color.RED
			Global.show_damage_number(final_damage, target.global_position + Vector2(20, 0), damage_color)
	else:
		print("poison_slash: Target cannot receive status effects")



func get_animation_data() -> Dictionary:
	return {
        "damage": damage_amount,
		"poison_damage": poison_damage,
		"poison_duration": poison_duration,
		"effect_type": "status",
		"sound_volume": 0.9
	}