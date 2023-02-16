extends "res://monsters/BaseMonster.gd"


# the following variables MUST be overwritten by the derived monster classes
# NONE OF THESE SHOULD BE EXPORTS LOL, these should all be defined in each monsters respective script
# copy/paste and redefine these in each [monster name]Monster.gd script
func _ready():
	throw_angle = 45 # [0,90]
	throw_strength = 420
	weight
	wall_bounce_y_speed = 60 # [0, 200]
	jump_y_speed = 200 # [0, 3000]
	throw_frames = 40
	gravity = 400
	walk_force = 50 
	max_walk_speed = 150
	stop_force = 5000

	# visual monster attributes
	item_position_translate = Vector2(0,-175)

	
	
	# generally able to pick up monsters with lower pickup priority, is picked up by monsters with higher pickup priority
	pickup_priority = 10
	
	# this is passed to other monsters that are holding this monster. 
	monster_scene_path = "res://monsters/blocky/BlockyMonster.tscn"
