extends AnimatedSprite2D
@onready var progress_bar = $ProgressBar
@onready var animated_sprite_2d = $"."


var Dead = false

# Called when the node enters the scene tree for the first time.
func _ready():
	progress_bar.value = 100 # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if progress_bar.value < 1 and !Dead:
		animated_sprite_2d.play("Death")
		Dead = true
	else:
		animated_sprite_2d.play("Idle")
		


func _on_damage_card_card_activated(damage_amount):
	progress_bar.value -= damage_amount
	print("hdhsahdadsa")
