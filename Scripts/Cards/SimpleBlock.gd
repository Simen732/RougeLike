extends "res://Scripts/Cards/CardBase.gd"

@export var block_amount = 5

func _ready():
	card_type_name = "BlockCard"
	energy_cost = 1
	super._ready()
	print("SimpleBlock initialized with block amount: ", block_amount)

func activate_card():
	print("SimpleBlock activated!")
	super.activate_card()

func apply_effect_to_target(_target):
	# Block cards target the player instead of enemies
	var player = Global.player_character
	if player and player.has_method("apply_block"):
		# Apply critical hit calculation to block
		var crit_result = Global.apply_critical_effect(block_amount, "block")
		var final_block_amount = int(crit_result.value)
		var is_critical = crit_result.is_critical
		
		player.apply_block(final_block_amount)
		emit_signal("card_activated", final_block_amount)
		print("BlockCard: Blocking ", final_block_amount, " damage ", 
			  " (", "CRITICAL! " if is_critical else "", "base: ", block_amount, ")")
		
		# Show block number with critical styling
		if Global.damage_number_manager and player.has_method("get_global_position"):
			var block_color = Color.CYAN if is_critical else Color.LIGHT_BLUE
			Global.show_damage_number(final_block_amount, player.global_position, block_color)

func get_animation_data() -> Dictionary:
	return {
		"block": block_amount,
		"effect_type": "block",
		"sound_volume": 0.8
	}