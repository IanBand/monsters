extends "res://monsters/BaseMonster.gd"


# the following variables MUST be overwritten by the derived monster classes
# NONE OF THESE SHOULD BE EXPORTS LOL, these should all be defined in each monsters respective script
# copy/paste and redefine these in each [monster name]Monster.gd script
func _ready():
	throw_angle = 45 # [0,90]
	throw_strength = 400
	weight
	wall_bounce_y_speed = 80 # [0, 200]
	jump_y_speed = 400 # [0, 3000]
	throw_frames = 40
	gravity = 200
	walk_force = 200
	max_walk_speed = 300
	stop_force = 4000

	# visual monster attributes
	item_position_translate = Vector2(32,-150)

	# generally able to pick up monsters with lower pickup priority, is picked up by monsters with higher pickup priority
	pickup_priority = 1
	
	# this is passed to other monsters that are holding this monster. 
	monster_scene_path = "res://monsters/tooble/ToobleMonster.tscn"
