extends AnimatedSprite2D
@onready var progress_bar = $ProgressBar
@onready var animated_sprite_2d = $"."

var health = 100
var max_health = 100
var Dead = false
var attack_damage = 15
var player_target = null
var is_attacking = false
var speed = 6

func _ready():
	progress_bar.value = health
	progress_bar.max_value = max_health
	Global.register_enemy(self)
	
	player_target = get_node_or_null("../Player")
	if not player_target:
		print("Slime: Player not found at ../Player, will search later")

func _process(_delta):
	if progress_bar.value < 1 and !Dead:
		animated_sprite_2d.play("Death")
		Dead = true
		Global.unregister_enemy(self)
	elif !Dead and !is_attacking:
		animated_sprite_2d.play("Idle")

func take_damage(damage_amount):
	if Dead:
		return
		
	progress_bar.value -= damage_amount
	
	modulate = Color(1, 0.5, 0.5) 
	await get_tree().create_timer(0.15).timeout
	modulate = Color(1, 1, 1)  

func _on_damage_card_card_activated(damage_amount):
	take_damage(damage_amount)

func take_turn():
	if Dead:
		Global.turn_manager.end_current_enemy_turn()
		return
	
	if player_target and is_instance_valid(player_target) and player_target.has_method("take_damage"):
		attack_player()
	else:
		find_player()
		if player_target:
			attack_player()
	
	await get_tree().create_timer(1.0).timeout
	Global.turn_manager.end_current_enemy_turn()

func attack_player():
	if not player_target or Dead:
		return
	
	is_attacking = true
	animated_sprite_2d.play("Attack")
	
	var timer = get_tree().create_timer(0.5)
	await timer.timeout
	
	if player_target.has_method("take_damage"):
		player_target.take_damage(attack_damage)
		
		if Global.damage_number_manager and player_target.has_method("get_global_position"):
			Global.show_damage_number(attack_damage, player_target.global_position, Color.ORANGE)
	
	is_attacking = false

func find_player():
	var possible_paths = ["../Player", "../../Player", "../../../Player", "Player"]
	
	for path in possible_paths:
		var found_player = get_node_or_null(path)
		if found_player and found_player.has_method("take_damage"):
			player_target = found_player
			return
	
	var current_scene = get_tree().current_scene
	if current_scene:
		player_target = find_node_by_type(current_scene, "Player")

func find_node_by_type(node: Node, type_name: String):
	if node.name == type_name or node.get_script() and node.get_script().get_path().get_file().get_basename() == type_name:
		return node
	
	for child in node.get_children():
		var result = find_node_by_type(child, type_name)
		if result:
			return result
	
	return null

func is_dead() -> bool:
	return Dead

func get_speed() -> int:
	return speed

func modify_speed(modifier: float):
	speed = max(1, int(speed * modifier))

func enrage():
	modify_speed(1.5)
