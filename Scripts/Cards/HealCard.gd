extends "res://Scripts/Cards/CardBase.gd"

@export var heal_amount = 15

func _ready():
	card_type_name = "HealCard"
	energy_cost = 2  # Healing costs more energy
	super._ready()
	print("HealCard initialized with heal amount: ", heal_amount)

func activate_card():
	print("HealCard activated!")
	super.activate_card()

func apply_effect_to_target(_target):
	# Heal cards target the player instead of enemies
	var player = Global.player_character
	if player and player.has_method("heal"):
		# Apply critical hit calculation to healing
		var crit_result = Global.apply_critical_effect(heal_amount, "healing")
		var final_healing = int(crit_result.value)
		var is_critical = crit_result.is_critical
		
		player.heal(final_healing)
		emit_signal("card_activated", final_healing)
		print("HealCard: Healing ", final_healing, " HP ", 
			  " (", "CRITICAL! " if is_critical else "", "base: ", heal_amount, ")")
		
		# Show healing number with critical styling
		if Global.damage_number_manager and player.has_method("get_global_position"):
			var heal_color = Color.LIME if is_critical else Color.GREEN
			Global.show_damage_number(final_healing, player.global_position, heal_color)

func get_animation_data() -> Dictionary:
	return {
		"healing": heal_amount,
		"effect_type": "healing",
		"sound_volume": 0.8
	}