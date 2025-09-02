extends AnimatedSprite2D
@onready var progress_bar = $ProgressBar
@onready var animated_sprite_2d = $"."

var health = 100
var max_health = 100
var Dead = false
var attack_damage = 15  # Damage the slime deals to player
var player_target = null  # Reference to player
var is_attacking = false  # Track if slime is currently attacking
var speed = 37  # Slime speed for turn order - 3x player speed (12 * 3 = 36)

func _ready():
	progress_bar.value = health
	progress_bar.max_value = max_health
	print("Slime: Registering with Global")
	Global.register_enemy(self)
	
	# Find the player (you might need to adjust this based on your scene structure)
	player_target = get_node_or_null("../Player")  # Adjust path as needed
	if not player_target:
		print("Slime: Player not found at ../Player, will search later")

func _process(delta):
	if progress_bar.value < 1 and !Dead:
		animated_sprite_2d.play("Death")
		Dead = true
		Global.unregister_enemy(self)
		print("Slime died!")
	elif !Dead and !is_attacking:
		animated_sprite_2d.play("Idle")

func take_damage(damage_amount):
	if Dead:
		return
		
	progress_bar.value -= damage_amount
	print("Slime took " + str(damage_amount) + " damage! Health now: " + str(progress_bar.value))
	
	modulate = Color(1, 0.5, 0.5) 
	await get_tree().create_timer(0.15).timeout
	modulate = Color(1, 1, 1)  

func _on_damage_card_card_activated(damage_amount):
	take_damage(damage_amount)

# Enemy turn behavior
func take_turn():
	if Dead:
		# If dead, just end turn immediately
		Global.turn_manager.end_current_enemy_turn()
		return
	
	print("Slime is taking its turn!")
	
	# Attack the player if we have a valid target
	if player_target and is_instance_valid(player_target) and player_target.has_method("take_damage"):
		attack_player()
	else:
		# Try to find player if we don't have a reference
		find_player()
		if player_target:
			attack_player()
		else:
			print("Slime: No player target found!")
	
	# End turn after a brief delay to show attack animation
	await get_tree().create_timer(1.0).timeout
	Global.turn_manager.end_current_enemy_turn()

func attack_player():
	if not player_target or Dead:
		return
	
	print("Slime attacks player for ", attack_damage, " damage!")
	
	# Set attacking state to prevent idle animation from overriding
	is_attacking = true
	
	# Play attack animation
	animated_sprite_2d.play("Attack")
	
	# Wait for the animation to finish
	var timer = get_tree().create_timer(0.5)
	await timer.timeout
	
	# Deal damage to player
	if player_target.has_method("take_damage"):
		player_target.take_damage(attack_damage)
		
		# Show damage number on player
		if Global.damage_number_manager and player_target.has_method("get_global_position"):
			Global.show_damage_number(attack_damage, player_target.global_position, Color.ORANGE)
	
	# Reset attacking state so idle animation can resume
	is_attacking = false

func find_player():
	# Try different possible paths to find the player
	var possible_paths = ["../Player", "../../Player", "../../../Player", "Player"]
	
	for path in possible_paths:
		var found_player = get_node_or_null(path)
		if found_player and found_player.has_method("take_damage"):
			player_target = found_player
			print("Slime: Found player at ", path)
			return
	
	# If not found by path, try searching the scene tree
	var current_scene = get_tree().current_scene
	if current_scene:
		player_target = find_node_by_type(current_scene, "Player")
		if player_target:
			print("Slime: Found player in scene tree")

func find_node_by_type(node: Node, type_name: String):
	# Check if current node matches
	if node.name == type_name or node.get_script() and node.get_script().get_path().get_file().get_basename() == type_name:
		return node
	
	# Recursively check children
	for child in node.get_children():
		var result = find_node_by_type(child, type_name)
		if result:
			return result
	
	return null

func is_dead() -> bool:
	return Dead

func get_speed() -> int:
	return speed

# Example method to modify speed dynamically  
func modify_speed(modifier: float):
	speed = max(1, int(speed * modifier))  # Ensure speed doesn't go below 1
	print("Slime: Speed changed to ", speed)

# Example method for slime to get enraged and speed up
func enrage():
	modify_speed(1.5)  # 50% speed increase
	print("Slime: Enraged! Speed increased to ", speed)
