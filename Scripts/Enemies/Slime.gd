extends "res://Scripts/Enemies/EnemyBase.gd"

func enemy_ready():
	# Slime-specific setup
	max_health = 100
	health = max_health
	attack_damage = 15
	speed = 6

func enemy_turn_behavior():
	# Slime just does basic attack
	if player_target and is_instance_valid(player_target) and player_target.has_method("take_damage"):
		attack_player()
	else:
		find_player()
		if player_target:
			attack_player()

func enrage():
	modify_speed(1.5)

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
	modulate = Color(1, 0.5, 0.5) 
	await get_tree().create_timer(0.15).timeout
	modulate = Color(1, 1, 1)

func _on_damage_card_card_activated(damage_amount):
	take_damage(damage_amount)
