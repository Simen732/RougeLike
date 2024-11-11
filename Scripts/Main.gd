extends Node2D
@onready var progress_bar = $CharacterBody2D/ProgressBar


# Called when the node enters the scene tree for the first time.
func _ready():
	progress_bar.value = 50


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
