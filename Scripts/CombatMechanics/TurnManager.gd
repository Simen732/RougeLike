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

func _ready():
	current_phase = CombatPhase.PLAYER_TURN
	
	await get_tree().process_frame 
	find_turn_order_ui()

func find_turn_order_ui():
	var scene_root = get_tree().current_scene
	turn_order_ui = find_node_by_name(scene_root, "TurnOrderUI")
	if turn_order_ui:
		print("TurnManager: Found TurnOrderUI at path: ", turn_order_ui.get_path())
	else:
		turn_order_ui = find_node_with_script(scene_root, "TurnOrderUI.gd")
		if turn_order_ui:
			print("TurnManager: Found TurnOrderUI by script: ", turn_order_ui.get_path())
		else:
			print("TurnManager: TurnOrderUI not found anywhere in scene tree")

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
	# Prevent duplicate player registration
	if player == player_node:
		print("TurnManager: Player already registered, skipping")
		return
		
	player = player_node
	print("TurnManager: Player registered - ", player_node.name)
	
	# Try to find TurnOrderUI if we don't have it yet
	if not turn_order_ui:
		find_turn_order_ui()
	
	var player_speed = 10
	if player_node.has_method("get_speed"):
		player_speed = player_node.get_speed()
	
	if turn_order_ui:
		turn_order_ui.register_entity(player_node, player_speed)
		print("TurnManager: Registered player with TurnOrderUI (speed: ", player_speed, ")")
	else:
		print("TurnManager: Warning - turn_order_ui not found, cannot register player")
	
	check_and_start_combat()

func register_enemy(enemy_node):
	if enemy_node not in registered_entities:
		registered_entities.append(enemy_node)
		print("TurnManager: Enemy registered - ", enemy_node.name, " (Total entities: ", registered_entities.size(), ")")
		
		# Try to find TurnOrderUI if we don't have it yet
		if not turn_order_ui:
			find_turn_order_ui()
		
		var enemy_speed = 8
		if enemy_node.has_method("get_speed"):
			enemy_speed = enemy_node.get_speed()
		
		if turn_order_ui:
			turn_order_ui.register_entity(enemy_node, enemy_speed)
			print("TurnManager: Registered enemy with TurnOrderUI (speed: ", enemy_speed, ")")
		else:
			print("TurnManager: Warning - turn_order_ui not found, cannot register enemy")
		
		check_and_start_combat()

func check_and_start_combat():
	if player and registered_entities.size() > 0:
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
	if current_phase == CombatPhase.PLAYER_TURN:
		return  
		
	current_phase = CombatPhase.PLAYER_TURN
	current_entity = player
	
	emit_signal("combat_phase_changed", current_phase)
	emit_signal("turn_started", player)

func end_player_turn():
	if Global.is_game_frozen():
		print("TurnManager: Cannot end player turn - game is frozen")
		return
		
	if current_phase != CombatPhase.PLAYER_TURN:
		print("TurnManager: Cannot end player turn - not in player turn phase (current: ", current_phase, ")")
		return
		
	print("TurnManager: Player turn ended")
	emit_signal("turn_ended", player)
	
	# Use turn order UI to determine next entity
	if turn_order_ui:
		var next_entity = turn_order_ui.get_next_entity()
		if next_entity and next_entity != player:
			start_entity_turn(next_entity)
		else:
			start_player_turn()
	else:
		# Fallback to old system if no turn order UI
		if registered_entities.size() > 0:
			start_enemy_turns()
		else:
			start_player_turn()

func start_entity_turn(entity):
	current_phase = CombatPhase.ENEMY_TURN if entity != player else CombatPhase.PLAYER_TURN
	current_entity = entity
	
	print("TurnManager: Entity turn started - ", entity.name)
	emit_signal("turn_started", entity)
	emit_signal("combat_phase_changed", current_phase)
	
	# Tell the entity to take its turn
	if entity.has_method("take_turn") and entity != player:
		entity.take_turn()
	elif entity == player:
		# Player turn - nothing special needed, just wait for player actions
		pass

# Keep old system for backward compatibility
func start_enemy_turns():
	current_phase = CombatPhase.ENEMY_TURN
	emit_signal("combat_phase_changed", current_phase)
	process_next_enemy_turn()

func process_next_enemy_turn():
	# This is now deprecated in favor of the turn order system
	# But kept for compatibility
	pass

func end_current_enemy_turn():
	if current_phase != CombatPhase.ENEMY_TURN:
		print("TurnManager: Cannot end enemy turn - not in enemy turn phase")
		return
	
	print("TurnManager: Enemy turn ended - ", current_entity.name if current_entity else "Unknown")
	emit_signal("turn_ended", current_entity)
	
	# Use turn order UI to get next entity
	if turn_order_ui:
		var next_entity = turn_order_ui.get_next_entity()
		if next_entity == player:
			start_player_turn()
		else:
			start_entity_turn(next_entity)
	else:
		# Fallback
		start_player_turn()

func is_player_turn() -> bool:
	return current_phase == CombatPhase.PLAYER_TURN

func is_enemy_turn() -> bool:
	return current_phase == CombatPhase.ENEMY_TURN

func get_current_phase() -> CombatPhase:
	return current_phase