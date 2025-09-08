extends Control

@onready var class_list_container = $VBoxContainer/HBoxContainer/ScrollContainer/ClassListContainer
@onready var class_name_label = $VBoxContainer/HBoxContainer/ClassInfoPanel/ClassNameLabel
@onready var class_description_label = $VBoxContainer/HBoxContainer/ClassInfoPanel/ClassDescriptionLabel
@onready var class_stats_label = $VBoxContainer/HBoxContainer/ClassInfoPanel/ClassStatsLabel
@onready var select_button = $VBoxContainer/SelectButton
@onready var back_button = $VBoxContainer/BackButton

var selected_class_index = -1

func _ready():
	# Try to find nodes with fallback paths if the main paths don't work
	if not class_list_container:
		class_list_container = get_node_or_null("VBoxContainer/ScrollContainer/ClassListContainer")
	if not class_name_label:
		class_name_label = get_node_or_null("VBoxContainer/ClassInfoPanel/ClassNameLabel")
	if not class_description_label:
		class_description_label = get_node_or_null("VBoxContainer/ClassInfoPanel/ClassDescriptionLabel")
	if not class_stats_label:
		class_stats_label = get_node_or_null("VBoxContainer/ClassInfoPanel/ClassStatsLabel")
	if not select_button:
		select_button = get_node_or_null("VBoxContainer/SelectButton")
	if not back_button:
		back_button = get_node_or_null("VBoxContainer/BackButton")
	
	# Print the scene structure for debugging
	print("ClassSelection: Scene structure:")
	print_scene_tree(self, 0)
	
	# Check if required nodes exist before proceeding
	if not class_list_container:
		print("ClassSelection: Missing class_list_container - please set up the scene structure")
		print("ClassSelection: Expected path: VBoxContainer/HBoxContainer/ScrollContainer/ClassListContainer")
		return
	
	setup_class_list()
	update_class_info()
	
	# Connect buttons
	if select_button:
		select_button.connect("pressed", _on_select_button_pressed)
		select_button.disabled = true
	
	if back_button:
		back_button.connect("pressed", _on_back_button_pressed)

func print_scene_tree(node: Node, depth: int):
	var indent = ""
	for i in range(depth):
		indent += "  "
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		print_scene_tree(child, depth + 1)

func setup_class_list():
	# Ensure class_list_container exists
	if not class_list_container:
		print("ClassSelection: class_list_container is null - cannot setup class list")
		return
	
	print("ClassSelection: class_list_container found: ", class_list_container)
	
	# Clear existing buttons
	for child in class_list_container.get_children():
		child.queue_free()
	
	# Check if Global.class_manager exists
	if not Global.class_manager:
		print("ClassSelection: Global.class_manager is null!")
		return
	
	var classes = Global.class_manager.get_available_classes()
	print("ClassSelection: Found ", classes.size(), " classes")
	
	for i in range(classes.size()):
		var player_class = classes[i]
		print("ClassSelection: Creating button for class: ", player_class.player_class_name)
		
		# Create button for this class
		var class_button = Button.new()
		class_button.text = player_class.player_class_name
		class_button.custom_minimum_size = Vector2(200, 60)
		
		# Style the button (you can customize this)
		class_button.add_theme_font_size_override("font_size", 20)
		
		# Connect the button
		class_button.connect("pressed", _on_class_button_pressed.bind(i))
		
		class_list_container.add_child(class_button)
		print("ClassSelection: Added button to container")
	
	print("ClassSelection: Finished setting up class list with ", class_list_container.get_child_count(), " buttons")

func _on_class_button_pressed(class_index: int):
	selected_class_index = class_index
	update_class_info()
	
	# Enable select button
	if select_button:
		select_button.disabled = false
	
	# Update button visuals to show selection
	update_button_selection()

func update_button_selection():
	if not class_list_container:
		return
		
	for i in range(class_list_container.get_child_count()):
		var button = class_list_container.get_child(i)
		if i == selected_class_index:
			button.modulate = Color(0.8, 1.0, 0.8)  # Light green tint
		else:
			button.modulate = Color.WHITE

func update_class_info():
	if selected_class_index == -1:
		# No class selected
		if class_name_label:
			class_name_label.text = "Select a Class"
		if class_description_label:
			class_description_label.text = "Choose your character class to begin your adventure."
		if class_stats_label:
			class_stats_label.text = ""
		return
	
	var classes = Global.class_manager.get_available_classes()
	var player_class = classes[selected_class_index]
	
	if class_name_label:
		class_name_label.text = player_class.player_class_name
	if class_description_label:
		class_description_label.text = player_class.description
	
	# Build stats text
	var stats_text = "Health: " + str(player_class.base_health) + "\n"
	stats_text += "Speed: " + str(player_class.base_speed) + "\n"
	
	if not player_class.special_abilities.is_empty():
		stats_text += "Special Abilities: " + ", ".join(player_class.special_abilities) + "\n"
	
	if not player_class.passive_effects.is_empty():
		stats_text += "Passive Effects:\n"
		for effect in player_class.passive_effects:
			stats_text += "  • " + effect + ": " + str(player_class.passive_effects[effect]) + "\n"
	
	if class_stats_label:
		class_stats_label.text = stats_text

func _on_select_button_pressed():
	if selected_class_index != -1:
		Global.class_manager.select_class(selected_class_index)
		
		# Transition to main game scene
		get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_back_button_pressed():
	# Return to main menu
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
