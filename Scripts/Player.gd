extends CharacterBody2D
@onready var progress_bar = $ProgressBar





func _physics_process(delta):
	pass
	
	
func _ready():
	progress_bar.value = progress_bar.max_value
