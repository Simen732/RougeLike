extends AnimatedSprite2D
@onready var progress_bar = $ProgressBar


# Called when the node enters the scene tree for the first time.
func _ready():
	progress_bar.value = 100 # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_damage_card_card_activated(damage_amount):
	progress_bar.value -= damage_amount
	print("hdhsahdadsa")


func _on_damage_card_2_card_activated(damage_amount):
	progress_bar.value -= damage_amount
	print("hdhsahdadsa")
