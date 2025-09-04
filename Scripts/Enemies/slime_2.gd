extends "res://Scripts/Enemies/EnemyBase.gd"

func enemy_ready():
	# Stronger slime setup
	max_health = 200
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


func take_damage(damage_amount):
	if Dead:
		return
		
	progress_bar.value -= damage_amount
	health = progress_bar.value
	
	# Flash damage color
	modulate = Color(1.2, 0, 0)
	await get_tree().create_timer(0.15).timeout
	modulate = Color(1.658, 0., 0.) 

func _on_damage_card_card_activated(damage_amount):
	take_damage(damage_amount)
