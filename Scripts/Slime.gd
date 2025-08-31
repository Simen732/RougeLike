extends AnimatedSprite2D
@onready var progress_bar = $ProgressBar
@onready var animated_sprite_2d = $"."

var health = 100
var max_health = 100
var Dead = false

# Called when the node enters the scene tree for the first time.
func _ready():
	progress_bar.value = health
	progress_bar.max_value = max_health
	# Register with Global when entering the scene
	Global.register_enemy(self)
	print("Slime initialized with health: ", health)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if progress_bar.value < 1 and !Dead:
		animated_sprite_2d.play("Death")
		Dead = true
		# Unregister from Global when dead
		Global.unregister_enemy(self)
		print("Slime died!")
	elif !Dead:
		animated_sprite_2d.play("Idle")

# Take damage and update health bar
func take_damage(damage_amount):
	if Dead:
		return
		
	progress_bar.value -= damage_amount
	print("Slime took " + str(damage_amount) + " damage! Health now: " + str(progress_bar.value))
	
	# Flash the sprite to indicate damage
	modulate = Color(1, 0.5, 0.5)  # Red tint
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)  # Back to normal

func _on_damage_card_card_activated(damage_amount):
	take_damage(damage_amount)
