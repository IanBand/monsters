extends RigidBody2D

# WHEN CREATING A NEW ITEM:
# need to tick Contact Monitor in editor for this to work, also set Contacts Reported option (typically set to 3 allowing for 2 blocks and 1 monster)

var scene_path : String

var prev_linear_velocity : Vector2

var hitlag_counter : int = 0

func _physics_process(_delta):
		
	var colliding_bodies = get_colliding_bodies() # need to tick Contact Monitor in editor for this to work, also set Contacts Reported option
	
	# only spin while not touching anything, i.e. airborn
	if colliding_bodies.size() == 0:
		$AnimatedSprite.play("default")
		prev_linear_velocity = linear_velocity
	else:
		$AnimatedSprite.stop()

	if hitlag_counter > 0:
		hitlag_counter -= 1
	else: 
		for body in colliding_bodies:
			var colliding_class = body.get_class()
			
			#print(colliding_class)
			match colliding_class:
				"RigidBody2D":
					touchOtherItem(body)
				"KinematicBody2D":
					touchMonster(body)
				"TileMap":
					#print("Toucching a block, check if action block")
					pass
				_:
					pass
	
	# clear prev linear velocity
	if colliding_bodies.size() > 0:
		prev_linear_velocity = Vector2(0,0)
	

	
	custom_physics_process()

# Override these functions for every item
func touchOtherItem(other):
	pass
func touchMonster(monster):
	monster.touchItem(self, scene_path)
func custom_physics_process():
	pass
