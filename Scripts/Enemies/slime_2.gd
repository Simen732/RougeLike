extends "res://Scripts/Enemies/EnemyBase.gd"

func enemy_ready():
	# Stronger slime setup
	max_health = 150
	health = max_health
	attack_damage = 25
	speed = 3

func enemy_turn_behavior():
	# Same behavior as regular slime for now
	if player_target and is_instance_valid(player_target) and player_target.has_method("take_damage"):
		attack_player()
	else:
		find_player()
		if player_target:
			attack_player()

func on_death():
	# Could add special death effects here
	pass
