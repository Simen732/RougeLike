extends Control

@onready var turn_order_container = $HBoxContainer
var turn_icon_scene = preload("res://Scenes/TurnIcon.tscn")

var turn_queue = []
var past_turns = []
var max_visible_turns = 12
var max_past_turns = 8
var current_turn_index = 0

var entities = []
var current_time = 0.0
var turn_increment = 10.0
var total_turns_completed = 0
var combat_started = false

func _ready():
	if Global.turn_manager:
		Global.turn_manager.connect("turn_started", _on_turn_started)
		Global.turn_manager.connect("turn_ended", _on_turn_ended)
	
	if not turn_order_container:
		turn_order_container = get_node_or_null("HBoxContainer")

func _on_combat_started():
	combat_started = true
	calculate_initial_turn_order()
	call_deferred("update_timeline_ui")

func register_entity(entity: Node, speed: int = 10, icon_texture: Texture2D = null):
	for existing_entry in entities:
		if existing_entry.entity == entity:
			return
	
	var entry = {
		"entity": entity,
		"speed": speed,
		"next_turn_time": 0.0,
		"icon": icon_texture
	}
	entities.append(entry)
	
	if entities.size() > 1 and combat_started:
		calculate_initial_turn_order()
		call_deferred("update_ui")

func unregister_entity(entity: Node):
	for i in range(entities.size()):
		if entities[i].entity == entity:
			entities.remove_at(i)
			break
	
	for i in range(turn_queue.size() - 1, -1, -1):
		if turn_queue[i].entity == entity:
			turn_queue.remove_at(i)
	
	call_deferred("update_ui")

func calculate_initial_turn_order():
	turn_queue.clear()
	
	for entry in entities:
		entry.next_turn_time = turn_increment / entry.speed
	
	var queue_length = 0
	var safety_counter = 0
	
	while queue_length < max_visible_turns and safety_counter < 1000:
		var next_entity = null
		var earliest_time = INF
		
		for entry in entities:
			if entry.entity and is_instance_valid(entry.entity):
				if entry.next_turn_time < earliest_time:
					earliest_time = entry.next_turn_time
					next_entity = entry
		
		if next_entity:
			turn_queue.append({
				"entity": next_entity.entity,
				"speed": next_entity.speed,
				"icon": next_entity.icon,
				"turn_time": earliest_time
			})
			
			next_entity.next_turn_time += turn_increment / next_entity.speed
			queue_length += 1
		else:
			break
		
		safety_counter += 1

func _on_turn_started(_entity):
	pass

func _on_turn_ended(entity):
	if turn_queue.size() > 0 and turn_queue[0].entity == entity:
		var completed_turn = turn_queue[0]
		turn_queue.remove_at(0)
		completed_turn["completed"] = true
		past_turns.append(completed_turn)
		total_turns_completed += 1
		
		while past_turns.size() > max_past_turns:
			# var removed_turn = past_turns[0]
			past_turns.remove_at(0)
	
	current_turn_index = past_turns.size()
	update_entity_speeds()
	extend_turn_queue()
	call_deferred("update_timeline_ui")

func update_entity_speeds():
	var should_recalculate = false
	
	for entry in entities:
		if entry.entity and is_instance_valid(entry.entity):
			var new_speed = 10
			if entry.entity.has_method("get_speed"):
				new_speed = entry.entity.get_speed()
				
			if new_speed != entry.speed:
				entry.speed = new_speed
				should_recalculate = true
	
	if should_recalculate:
		recalculate_turn_order()

func extend_turn_queue():
	var safety_counter = 0
	
	while turn_queue.size() < max_visible_turns and safety_counter < 100:
		var next_entity = null
		var earliest_time = INF
		
		for entry in entities:
			if entry.entity and is_instance_valid(entry.entity):
				if entry.next_turn_time < earliest_time:
					earliest_time = entry.next_turn_time
					next_entity = entry
		
		if next_entity:
			turn_queue.append({
				"entity": next_entity.entity,
				"speed": next_entity.speed,
				"icon": next_entity.icon,
				"turn_time": earliest_time
			})
			
			next_entity.next_turn_time += turn_increment / next_entity.speed
		else:
			break
		
		safety_counter += 1

func recalculate_turn_order():
	turn_queue.clear()
	
	for entry in entities:
		if entry.entity and is_instance_valid(entry.entity):
			entry.next_turn_time = turn_increment / entry.speed
	
	var queue_length = 0
	var safety_counter = 0
	
	while queue_length < max_visible_turns and safety_counter < 1000:
		var next_entity = null
		var earliest_time = INF
		
		for entry in entities:
			if entry.entity and is_instance_valid(entry.entity):
				if entry.next_turn_time < earliest_time:
					earliest_time = entry.next_turn_time
					next_entity = entry
		
		if next_entity:
			turn_queue.append({
				"entity": next_entity.entity,
				"speed": next_entity.speed,
				"icon": next_entity.icon,
				"turn_time": earliest_time
			})
			
			next_entity.next_turn_time += turn_increment / next_entity.speed
			queue_length += 1
		else:
			break
		
		safety_counter += 1

func update_timeline_ui():
	var container = turn_order_container
	if not container:
		container = get_node_or_null("HBoxContainer")
		if not container:
			return
	
	if not is_instance_valid(container):
		return
	
	for child in container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var timeline = []
	
	for past_turn in past_turns:
		timeline.append({
			"entry": past_turn,
			"type": "past"
		})
	
	if turn_queue.size() > 0:
		timeline.append({
			"entry": turn_queue[0],
			"type": "current"
		})
		
		for i in range(1, min(turn_queue.size(), max_visible_turns - past_turns.size())):
			timeline.append({
				"entry": turn_queue[i],
				"type": "future"
			})
	
	var start_index = 0
	var current_pos = past_turns.size()
	var half_visible = max_visible_turns / 2.0
	start_index = max(0, current_pos - half_visible)
	
	for i in range(start_index, min(timeline.size(), start_index + max_visible_turns)):
		var timeline_item = timeline[i]
		var turn_entry = timeline_item.entry
		var turn_type = timeline_item.type
		
		if not is_instance_valid(turn_entry.entity):
			continue
			
		var icon = turn_icon_scene.instantiate()
		container.add_child(icon)
		
		if icon.has_method("setup_icon"):
			var is_current = (turn_type == "current")
			icon.setup_icon(turn_entry.entity, turn_entry.icon, is_current)
			
			if turn_type == "past":
				icon.modulate = Color(0.7, 0.7, 0.7, 0.8)

func update_ui():
	update_timeline_ui()

func get_next_entity():
	if turn_queue.size() > 0:
		return turn_queue[0].entity
	return null

func get_current_turn_order():
	return turn_queue.duplicate()

func get_timeline_info():
	return {
		"past_turns": past_turns.size(),
		"current_turn": turn_queue[0].entity.name if turn_queue.size() > 0 else "None",
		"future_turns": turn_queue.size() - 1,
		"total_completed": total_turns_completed
	}
