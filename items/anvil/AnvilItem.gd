extends "res://items/BaseItem.gd"

var deflection_velocity : Vector2

func _ready():
	scene_path = "res://items/anvil/AnvilItem.tscn"
	
	
func touchMonster(monster):
	print("Anvil's y velocity:", prev_linear_velocity.y)
	
	if prev_linear_velocity.y > 0:
		var damage : int = 50 + 0.1 * prev_linear_velocity.length()
		monster.damageFromItem(self, damage, prev_linear_velocity)
		
		# go into hitlag state
		hitlag_counter = floor(damage / 4)
		mode = MODE_STATIC
				
		# bounce anvil in direction of prev_linear_velocity
		deflection_velocity = prev_linear_velocity * -1
		
	else:
		monster.touchItem(self, scene_path)

func custom_physics_process():
	
	# get out of hitlag state
	if hitlag_counter == 1:
		mode = MODE_CHARACTER
		
		# fly in a direction
		#apply_central_impulse(Vector2(0, -5000))
		apply_central_impulse(deflection_velocity * 0.7)
		
		deflection_velocity = Vector2(0,0)
	
	if hitlag_counter > 1:
		pass
		#randomly move visual sprite	
