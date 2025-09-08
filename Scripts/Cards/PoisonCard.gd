extends "res://Scripts/Cards/CardBase.gd"

@export var poison_damage = 5
@export var poison_duration = 3

func _ready():
	card_type_name = "PoisonCard"
	super._ready()
	print("PoisonCard initialized with ", poison_damage, " damage for ", poison_duration, " turns")

func activate_card():
	print("PoisonCard activated!")
	super.activate_card()

func apply_effect_to_target(target):
	if target and target.has_method("apply_status_effect"):
		# Apply critical hit calculation to duration
		var crit_result = Global.apply_critical_duration(poison_duration, "poison")
		var final_duration = int(crit_result.duration)
		var is_critical = crit_result.is_critical
		
		# Apply status effect (this would need to be implemented in enemies)
		target.apply_status_effect("poison", poison_damage, final_duration)
		emit_signal("card_activated", poison_damage)
		print("PoisonCard: Applied poison (", poison_damage, " dmg/turn) for ", final_duration, " turns",
			  " (", "CRITICAL! " if is_critical else "", "base: ", poison_duration, " turns)")
		
		# Show status effect indicator
		if Global.damage_number_manager and target.has_method("get_global_position"):
			var status_color = Color.PURPLE if is_critical else Color.DARK_GREEN
			Global.show_damage_number(final_duration, target.global_position, status_color)
	else:
		print("PoisonCard: Target cannot receive status effects")

func get_animation_data() -> Dictionary:
	return {
		"poison_damage": poison_damage,
		"poison_duration": poison_duration,
		"effect_type": "status",
		"sound_volume": 0.9
	}