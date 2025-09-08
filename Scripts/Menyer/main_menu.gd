extends Node2D

@onready var StartButton = $Start
@onready var ContinueButton = $Continue
@onready var QuiteButton = $Quite


func _ready():
    StartButton.pressed.connect(_on_startButton_down)
    ContinueButton.pressed.connect(_on_continueButton_down)
    QuiteButton.pressed.connect(_on_quiteButton_down)

func _on_startButton_down():
    print("Start button pressed")
    get_tree().change_scene_to_file("res://Scenes/ClassSelection.tscn")

func _on_continueButton_down():
    print("Continue button pressed")
    get_tree().change_scene_to_file("res://Scenes/Continue.tscn")

func _on_quiteButton_down():
    print("Quite button pressed")
    get_tree().quit()