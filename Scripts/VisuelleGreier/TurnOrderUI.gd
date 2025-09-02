extends Control

@onready var turn_order_container = $HBoxContainer
var turn_icon_scene = preload("res://Scenes/TurnIcon.tscn")

var turn_queue = []  # Array of turn entries showing multiple rounds
var past_turns = []  # Array of completed turns (for history)
var max_visible_turns = 12  # How many turn icons to show at once
var max_past_turns = 8  # How many past turns to keep before removing old ones
var current_turn_index = 0  # Index of the current turn in the combined display

# Turn entry structure: {entity: Node, speed: int, next_turn_time: float}
var entities = []  # All entities in combat with their speed stats
var current_time = 0.0  # Current turn time
var turn_increment = 10.0  # Base time increment per turn
var total_turns_completed = 0  # Track total turns for history management

func _ready():
	print("TurnOrderUI: Initializing...")
	
	# Make sure our container is available
	if not turn_order_container:
		turn_order_container = $HBoxContainer
		if not turn_order_container:
			print("TurnOrderUI: Error - HBoxContainer not found during _ready!")
			return
	
	# Connect to turn manager signals
	if Global.turn_manager:
		Global.turn_manager.connect("combat_started", _on_combat_started)
		Global.turn_manager.connect("turn_ended", _on_turn_ended)
		print("TurnOrderUI: Connected to TurnManager signals")
	else:
		print("TurnOrderUI: Warning - Global.turn_manager not found")
	
	print("TurnOrderUI: Initialized with container: ", turn_order_container)

func _on_combat_started():
	# Initialize turn order when combat starts
	calculate_initial_turn_order()
	update_ui()

func register_entity(entity: Node, speed: int = 10, icon_texture: Texture2D = null):
	# Check if entity is already registered to prevent duplicates
	for existing_entry in entities:
		if existing_entry.entity == entity:
			print("TurnOrderUI: Entity ", entity.name, " is already registered, skipping")
			return
	
	# Register a new entity in the turn system
	var entry = {
		"entity": entity,
		"speed": speed,
		"next_turn_time": 0.0,
		"icon": icon_texture
	}
	entities.append(entry)
	print("TurnOrderUI: Registered entity ", entity.name, " with speed ", speed)
	
	# If we have multiple entities, recalculate and update immediately
	if entities.size() > 1:
		calculate_initial_turn_order()
		# Delay the UI update to make sure the scene is ready
		call_deferred("update_ui")
		print("TurnOrderUI: Updated turn order, now showing ", turn_queue.size(), " turns")

func unregister_entity(entity: Node):
	# Remove entity from turn system
	for i in range(entities.size() - 1, -1, -1):
		if entities[i].entity == entity:
			entities.remove_at(i)
			break
	
	# Recalculate turn order
	calculate_initial_turn_order()
	update_ui()
	print("TurnOrderUI: Unregistered entity ", entity.name)

func calculate_initial_turn_order():
	# Calculate when each entity gets their turns based on speed
	# Higher speed = more frequent turns
	turn_queue.clear()
	current_time = 0.0
	
	# Reset all entities' next turn times
	for entry in entities:
		entry.next_turn_time = turn_increment / entry.speed
	
	# Generate turn queue for multiple rounds ahead
	var queue_length = 0
	var safety_counter = 0
	
	while queue_length < max_visible_turns and safety_counter < 1000:
		# Find entity with the earliest next turn time
		var next_entity = null
		var earliest_time = INF
		
		for entry in entities:
			if entry.entity and is_instance_valid(entry.entity):
				if entry.next_turn_time < earliest_time:
					earliest_time = entry.next_turn_time
					next_entity = entry
		
		if next_entity:
			# Add this entity's turn to the queue
			turn_queue.append({
				"entity": next_entity.entity,
				"speed": next_entity.speed,
				"icon": next_entity.icon,
				"turn_time": earliest_time
			})
			
			# Schedule their next turn
			next_entity.next_turn_time += turn_increment / next_entity.speed
			queue_length += 1
		
		safety_counter += 1
	
	print("TurnOrderUI: Generated turn queue with ", turn_queue.size(), " entries")

func _on_turn_ended(entity):
	print("TurnOrderUI: Turn ended for ", entity.name if entity else "Unknown")
	
	# Move current turn to past turns
	if turn_queue.size() > 0 and turn_queue[0].entity == entity:
		var completed_turn = turn_queue[0]
		turn_queue.remove_at(0)
		completed_turn["completed"] = true  # Mark as completed
		past_turns.append(completed_turn)
		total_turns_completed += 1
		print("TurnOrderUI: Moved ", entity.name, " to past turns")
		
		# Remove old past turns if we have too many
		while past_turns.size() > max_past_turns:
			var removed_turn = past_turns[0]
			past_turns.remove_at(0)
			print("TurnOrderUI: Removed old past turn: ", removed_turn.entity.name if removed_turn.entity else "Unknown")
	
	# Update current turn index (it stays the same since we removed from front but added to past)
	current_turn_index = past_turns.size()
	
	# Update entity speeds in case they changed during the turn
	update_entity_speeds()
	
	# Extend the queue to maintain future visibility
	extend_turn_queue()
	
	# Update the visual UI with timeline
	call_deferred("update_timeline_ui")

func update_entity_speeds():
	# Update speeds for all registered entities in case they changed
	# But don't reset their turn timers - this preserves turn order progression
	var should_recalculate = false
	
	for entry in entities:
		if entry.entity and is_instance_valid(entry.entity):
			var new_speed = 10  # Default speed
			if entry.entity.has_method("get_speed"):
				new_speed = entry.entity.get_speed()
				
			if new_speed != entry.speed:
				print("TurnOrderUI: Speed changed for ", entry.entity.name, " from ", entry.speed, " to ", new_speed)
				entry.speed = new_speed
				should_recalculate = true
	
	# Only recalculate if speeds actually changed
	if should_recalculate:
		print("TurnOrderUI: Speed changes detected, recalculating turn order")
		recalculate_turn_order()

func recalculate_turn_order():
	# Only use this for major changes like entity death/spawn
	# For normal turn progression, use extend_turn_queue instead
	print("TurnOrderUI: Recalculating turn order...")
	
	# Clear current queue
	turn_queue.clear()
	
	# Reset turn times for all entities
	for entry in entities:
		if entry.entity and is_instance_valid(entry.entity):
			entry.next_turn_time = turn_increment / entry.speed
	
	# Generate new turn queue
	var queue_length = 0
	var safety_counter = 0
	
	while queue_length < max_visible_turns and safety_counter < 1000:
		# Find entity with the earliest next turn time
		var next_entity = null
		var earliest_time = INF
		
		for entry in entities:
			if entry.entity and is_instance_valid(entry.entity):
				if entry.next_turn_time < earliest_time:
					earliest_time = entry.next_turn_time
					next_entity = entry
		
		if next_entity:
			# Add this entity's turn to the queue
			turn_queue.append({
				"entity": next_entity.entity,
				"speed": next_entity.speed,
				"icon": next_entity.icon,
				"turn_time": earliest_time
			})
			
			# Schedule their next turn
			next_entity.next_turn_time += turn_increment / next_entity.speed
			queue_length += 1
		else:
			break
		
		safety_counter += 1
	
	print("TurnOrderUI: Recalculated turn queue with ", turn_queue.size(), " entries")

func extend_turn_queue():
	# Add more turns to the end of the queue to maintain visibility
	# Don't reset turn times - just continue the progression
	var safety_counter = 0
	
	while turn_queue.size() < max_visible_turns and safety_counter < 100:
		# Find entity with earliest next turn time
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
			
			# Schedule their next turn (this is the key - we advance their timer)
			next_entity.next_turn_time += turn_increment / next_entity.speed
		else:
			break
		
		safety_counter += 1
	
	print("TurnOrderUI: Extended queue, now has ", turn_queue.size(), " entries")

func update_timeline_ui():
	print("TurnOrderUI: Updating timeline UI - Past: ", past_turns.size(), " Future: ", turn_queue.size())
	
	# Safety check - make sure we have a container
	var container = turn_order_container
	if not container:
		container = get_node_or_null("HBoxContainer")
		if not container:
			print("TurnOrderUI: Error - No HBoxContainer found, cannot update UI")
			return
	
	# Verify container is valid
	if not is_instance_valid(container):
		print("TurnOrderUI: Error - Container is not valid")
		return
	
	# Clear existing children completely
	for child in container.get_children():
		child.queue_free()
	
	# Wait for children to actually be removed
	await get_tree().process_frame
	await get_tree().process_frame  # Wait an extra frame to be sure
	
	print("TurnOrderUI: Container cleared, creating timeline...")
	
	# Create combined timeline: [Past turns] + [Current turn] + [Future turns]
	var timeline = []
	
	# Add past turns
	for past_turn in past_turns:
		timeline.append({
			"entry": past_turn,
			"type": "past"
		})
	
	# Add current turn (first in future queue)
	if turn_queue.size() > 0:
		timeline.append({
			"entry": turn_queue[0],
			"type": "current"
		})
		
		# Add remaining future turns
		for i in range(1, min(turn_queue.size(), max_visible_turns - past_turns.size())):
			timeline.append({
				"entry": turn_queue[i],
				"type": "future"
			})
	
	# Determine the visible portion of timeline (centered on current turn)
	var start_index = 0
	var current_pos = past_turns.size()  # Position of current turn in timeline
	
	# Try to center current turn, but don't go below 0
	var half_visible = max_visible_turns / 2
	start_index = max(0, current_pos - half_visible)
	
	# Create icons for visible portion
	var icons_created = 0
	for i in range(start_index, min(timeline.size(), start_index + max_visible_turns)):
		var timeline_item = timeline[i]
		var turn_entry = timeline_item.entry
		var turn_type = timeline_item.type
		
		if not is_instance_valid(turn_entry.entity):
			continue
			
		var icon = turn_icon_scene.instantiate()
		container.add_child(icon)
		
		# Configure the icon based on type
		if icon.has_method("setup_icon"):
			var is_current = (turn_type == "current")
			icon.setup_icon(turn_entry.entity, turn_entry.icon, is_current)
			
			# Apply special styling for past turns
			if turn_type == "past":
				icon.modulate = Color(0.7, 0.7, 0.7, 0.8)  # Slightly dimmed
			
			print("TurnOrderUI: Created ", turn_type, " icon for ", turn_entry.entity.name)
		
		icons_created += 1
	
	print("TurnOrderUI: Timeline update complete, ", icons_created, " icons created")

# Keep the old update_ui function for compatibility but redirect to timeline
func update_ui():
	update_timeline_ui()

func get_next_entity():
	# Get the entity whose turn is next (first in future queue)
	if turn_queue.size() > 0:
		return turn_queue[0].entity
	return null

func get_current_turn_order():
	# Return copy of current turn queue for debugging
	return turn_queue.duplicate()

func get_timeline_info():
	# Debug function to get complete timeline info
	return {
		"past_turns": past_turns.size(),
		"current_turn": turn_queue[0].entity.name if turn_queue.size() > 0 else "None",
		"future_turns": turn_queue.size() - 1,
		"total_completed": total_turns_completed
	}
