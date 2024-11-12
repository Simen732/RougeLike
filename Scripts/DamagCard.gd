# DamageCard.gd
extends "res://Scripts/CardBase.gd"  # Replace with the actual path to BaseCard.gd

@export var damage_amount := 10  # Damage specific to this card ty



func activate_card():
	# Emit the signal with the damage amount
	emit_signal("card_activated", damage_amount)
	print("Damage Card activated! Dealing ", damage_amount, " damage.")
	reset_position()
	
