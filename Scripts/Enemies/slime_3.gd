extends "res://Scripts/Enemies/EnemyBase.gd"

func enemy_ready():
	max_health = 50
	health = max_health
	attack_damage = 7.5
	speed = 12

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
		if target_indicator:
			target_indicator.visible = false
		return
		
	progress_bar.value -= damage_amount
	health = progress_bar.value
	
	# Check if this damage killed the enemy
	if health <= 0:
		if target_indicator:
			target_indicator.visible = false
	
	# Flash damage color
	modulate = Color(0, 1.4, 0.8)
	await get_tree().create_timer(0.15).timeout
	modulate = Color(0, 1.105, 0.552)

func _on_damage_card_card_activated(damage_amount):
	take_damage(damage_amount)
