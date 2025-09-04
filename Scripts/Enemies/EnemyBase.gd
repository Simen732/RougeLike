extends AnimatedSprite2D

@onready var progress_bar = $ProgressBar
@onready var animated_sprite_2d = $"."
@onready var target_indicator = $TargetIndicator

@export var max_health = 100
@export var attack_damage = 15
@export var speed = 6

var health
var Dead = false
var player_target = null
var is_attacking = false

func _ready():
	# Call child-specific initialization FIRST so max_health is set correctly
	enemy_ready()
	
	# Now set up health and progress bar with the correct values
	health = max_health
	progress_bar.max_value = max_health
	progress_bar.value = health
	Global.register_enemy(self)
	
	if target_indicator:
		target_indicator.visible = false
	
	find_player()

# Virtual function for child classes to override
func enemy_ready():
	pass

func _process(_delta):
	if progress_bar.value < 1 and !Dead:
		animated_sprite_2d.play("Death")
		Dead = true
		Global.unregister_enemy(self)
		on_death()
	elif !Dead and !is_attacking:
		animated_sprite_2d.play("Idle")

# Virtual function for death behavior
func on_death():
	pass

# func take_damage(damage_amount):
# 	if Dead:
# 		return
		
# 	progress_bar.value -= damage_amount
# 	health = progress_bar.value
	
# 	# Flash damage color
# 	modulate = Color(1, 0.5, 0.5) 
# 	await get_tree().create_timer(0.15).timeout
# 	modulate = Color(1, 1, 1)

# func _on_damage_card_card_activated(damage_amount):
# 	take_damage(damage_amount)

func take_turn():
	if Dead:
		Global.turn_manager.end_current_enemy_turn()
		return
	
	# Call child-specific turn behavior
	enemy_turn_behavior()
	
	await get_tree().create_timer(1.0).timeout
	Global.turn_manager.end_current_enemy_turn()

# Virtual function for child classes to override
func enemy_turn_behavior():
	# Default behavior: attack player
	if player_target and is_instance_valid(player_target) and player_target.has_method("take_damage"):
		attack_player()
	else:
		find_player()
		if player_target:
			attack_player()

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

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Global.turn_manager.is_player_turn():
			var mouse_pos = get_global_mouse_position()
			var sprite_size = Vector2(64, 64)
			var sprite_rect = Rect2(global_position - sprite_size / 2, sprite_size)
			
			if sprite_rect.has_point(mouse_pos):
				# Use Global targeting system
				Global.set_current_target(self)

func handle_targeting_locally():
	# Clear all enemy target indicators first
	for enemy in Global.registered_enemies:
		if enemy and is_instance_valid(enemy) and enemy.has_method("set_targeted"):
			enemy.set_targeted(false)
	
	# Set this enemy as targeted
	set_targeted(true)
	print("Enemy: Set local target to ", name)

func set_targeted(is_target: bool):
	if target_indicator:
		target_indicator.visible = is_target

func is_dead() -> bool:
	return Dead

func get_speed() -> int:
	return speed

func modify_speed(modifier: float):
	speed = max(1, int(speed * modifier))
