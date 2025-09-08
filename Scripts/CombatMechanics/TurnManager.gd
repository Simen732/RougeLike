extends Node

signal turn_started(entity)
signal turn_ended(entity)
signal combat_phase_changed(phase)
signal combat_started()

enum CombatPhase {
	PLAYER_TURN,
	ENEMY_TURN,
	TURN_TRANSITION
}

var current_phase = CombatPhase.PLAYER_TURN
var current_entity = null
var registered_entities = []  
var player = null
var turn_order_ui = null
var combat_has_started = false  # Add flag to prevent multiple starts  

func _ready():
	current_phase = CombatPhase.PLAYER_TURN
	await get_tree().process_frame 
	find_turn_order_ui()

func find_turn_order_ui():
	var scene_root = get_tree().current_scene
	turn_order_ui = find_node_by_name(scene_root, "TurnOrderUI")
	if not turn_order_ui:
		turn_order_ui = find_node_with_script(scene_root, "TurnOrderUI.gd")

func find_node_with_script(node: Node, script_name: String):
	var script = node.get_script()
	if script and script.resource_path.get_file() == script_name:
		return node
	for child in node.get_children():
		var result = find_node_with_script(child, script_name)
		if result:
			return result
	return null

func find_node_by_name(node: Node, target_name: String):
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result = find_node_by_name(child, target_name)
		if result:
			return result
	return null

func register_player(player_node):
	if player == player_node:
		return
		
	player = player_node
	
	if not turn_order_ui:
		find_turn_order_ui()
	
	var player_speed = 10
	if player_node.has_method("get_speed"):
		player_speed = player_node.get_speed()
	
	if turn_order_ui:
		turn_order_ui.register_entity(player_node, player_speed)
	
	check_and_start_combat()

func register_enemy(enemy_node):
	if enemy_node not in registered_entities:
		registered_entities.append(enemy_node)
		
		if not turn_order_ui:
			find_turn_order_ui()
		
		var enemy_speed = 8
		if enemy_node.has_method("get_speed"):
			enemy_speed = enemy_node.get_speed()
		
		if turn_order_ui:
			turn_order_ui.register_entity(enemy_node, enemy_speed)
		
		check_and_start_combat()

func check_and_start_combat():
	# Only start combat once, and only when we have both player and at least one enemy
	if not combat_has_started and player and registered_entities.size() > 0:
		combat_has_started = true
		print("TurnManager: Starting combat with ", registered_entities.size(), " enemies")
		
		emit_signal("combat_started")
		
		if turn_order_ui:
			await get_tree().process_frame 
			turn_order_ui._on_combat_started()

func unregister_enemy(enemy_node):
	if enemy_node in registered_entities:
		registered_entities.erase(enemy_node)
		
		if turn_order_ui:
			turn_order_ui.unregister_entity(enemy_node)
		
		if current_phase == CombatPhase.ENEMY_TURN and registered_entities.is_empty():
			start_player_turn()

func start_player_turn():
	# Always reset energy when player turn starts, regardless of previous turn
	Global.reset_energy()
	
	# Always update energy display when player turn starts
	var main_scene = get_tree().current_scene
	if main_scene.has_method("update_energy_display"):
		main_scene.update_energy_display()
	
	if current_phase == CombatPhase.PLAYER_TURN:
		return  
		
	current_phase = CombatPhase.PLAYER_TURN
	current_entity = player
	
	emit_signal("combat_phase_changed", current_phase)
	emit_signal("turn_started", player)

func end_player_turn():
	if Global.is_game_frozen():
		return
		
	if current_phase != CombatPhase.PLAYER_TURN:
		return
	
	# Process status effects on all enemies at the end of player turn
	process_all_status_effects()
		
	emit_signal("turn_ended", player)
	
	if turn_order_ui:
		var next_entity = turn_order_ui.get_next_entity()
		if next_entity and next_entity != player:
			start_entity_turn(next_entity)
		else:
			start_player_turn()
	else:
		if registered_entities.size() > 0:
			start_enemy_turns()
		else:
			start_player_turn()

# Process status effects on all enemies
func process_all_status_effects():
	print("TurnManager: Processing status effects for all enemies at end of player turn")
	for enemy in registered_entities:
		if enemy and is_instance_valid(enemy) and enemy.has_method("process_status_effects") and not enemy.is_dead():
			enemy.process_status_effects()

func start_entity_turn(entity):
	current_phase = CombatPhase.ENEMY_TURN if entity != player else CombatPhase.PLAYER_TURN
	current_entity = entity
	
	emit_signal("turn_started", entity)
	emit_signal("combat_phase_changed", current_phase)
	
	if entity.has_method("take_turn") and entity != player:
		entity.take_turn()

func start_enemy_turns():
	current_phase = CombatPhase.ENEMY_TURN
	emit_signal("combat_phase_changed", current_phase)
	process_next_enemy_turn()

func process_next_enemy_turn():
	pass

func end_current_enemy_turn():
	if current_phase != CombatPhase.ENEMY_TURN:
		return
	
	emit_signal("turn_ended", current_entity)
	
	if turn_order_ui:
		var next_entity = turn_order_ui.get_next_entity()
		if next_entity == player:
			start_player_turn()
		else:
			start_entity_turn(next_entity)
	else:
		start_player_turn()

func is_player_turn() -> bool:
	return current_phase == CombatPhase.PLAYER_TURN

func is_enemy_turn() -> bool:
	return current_phase == CombatPhase.ENEMY_TURN

func get_current_phase() -> CombatPhase:
	return current_phase