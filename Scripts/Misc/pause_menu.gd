extends Node2D

@onready var ContinueButton = $Continue
@onready var EscapeButton = $Escape

var is_paused = false

func _ready():
	# Set process mode so pause menu works when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	
	# Connect the Continue button to the function
	ContinueButton.pressed.connect(_on_continue_button_pressed)
	EscapeButton.pressed.connect(_on_escape_button_pressed)

func _on_continue_button_pressed():
		visible = false
		is_paused = false
		get_tree().paused = false
		# Hide the darkening effect
		get_tree().current_scene.get_node("CanvasModulate").visible = false

func _on_escape_button_pressed():
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("Pause") and !is_paused: 
		visible = true
		is_paused = true
		get_tree().paused = true
		# Show the darkening effect
		get_tree().current_scene.get_node("CanvasModulate").visible = true
		
	elif event.is_action_pressed("Pause") and is_paused: 
		visible = false
		is_paused = false
		get_tree().paused = false
		# Hide the darkening effect
		get_tree().current_scene.get_node("CanvasModulate").visible = false

	
