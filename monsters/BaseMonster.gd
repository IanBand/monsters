extends KinematicBody2D
# new monster creation guide:
# copy and rename a monster script that already exists
# copy a monsters scene too
# modify collision resource, modify animation resources
# override functions per monster

# ================================================================================
# ============================ CORE MONSTER MECHANICS ============================
# ================================================================================

# yeah its a god class so what? 
# your god is weak, mine makes up like 90% of the code in the game

# data
# TODO: make into an enum https://victorkarp.com/how-to-use-enums-in-the-godot-engine/ ??? enums suck ass in 3.0
# literally just copy pasting this between files
const TILE_NAMES = ["Goal","Throw","Jump","Freeze","Normal","Reverse","Gift","Kill","HoldReverse","EmptyReverse", "EmptyJump", "HoldingJump", "Painted"]


# mutually exclusive states
# keep in mind not every combination is valid
# these are values you would ASSIGN only.
# grounded vs airborne are derived
# walking vs idle is derived
enum MonsterStatus {NONE, FROZEN, BURN} # status
enum Direction {LEFT, RIGHT} # current_direction
enum MonsterState {HOLD_ITEM, HOLD_MONSTER, THROW, FLINCH, NORMAL, GRAB, SPECIAL1} # states TODO: might turn grab into a special state

# action state
var monster_status     : int = MonsterStatus.NONE
var current_direction  : int = Direction.RIGHT
var monster_state      : int
var prev_monster_state : int  = MonsterState.NORMAL
var grounded           : bool = false
var frame_count = 0
var dead = false

# physics state 
var velocity = Vector2()
var reverse_block_lockout : bool = false

# used for turning around when you cant pick up an item
var reverse_direction_lockout_frames : int = 0
var reverse_direction_lockout_amount : int = 20 # override per monster, based on traction/walk speed


# results of physics calculations, can be mutated by custom state functions
var net_lr_input : float

# dynamic child nodes
var item_sprite_node : AnimatedSprite
var held_item_scene

var held_monster_sprite_node_0 : AnimatedSprite
var held_monster_sprite_node_2 : AnimatedSprite
var held_monster_scene

# other nodes
onready var tile_map  : TileMap = $"../TileMap" 
onready var paint_map : TileMap = $"../PaintMap"
onready var ghost_scene = preload("res://effect/ghost/Ghost.tscn")


# the following variables MUST be overwritten by the derived monster classes in the _ready function
# NONE OF THESE SHOULD BE EXPORTS LOL, these should all be defined in each monsters respective script
# copy/paste and redefine these in each [monster name]Monster.gd script
var throw_angle : float = 45 # [0,90]
var throw_strength : float = 400
var weight  : float 
var wall_bounce_y_speed : float = 60 # [0, 200]
var wall_bounce_x_speed_factor : float = -0.2
var jump_y_speed : float = 700 # [0, 3000]
var throw_frames : float = 40
var gravity : float = 200
var walk_force : float = 70
var max_walk_speed : float = 200
var stop_force : float = 5000
var pickup_priority = 0 # monster with higher pickup priority picks up monster with lower priority. Equal or one of them holding an item means they reflect off of eachother
var item_additional_collision_height : float = 0 # was 40. Need a way to have monster be grounded after they throw the item

# visual monster attributes
var item_position_translate : Vector2 = Vector2(0,0)
var shake_radius : int = 10

# this is passed to other monsters that are holding this monster. 
var monster_scene_path : String = ""

var temp_sprite_position_0
var temp_sprite_position_2
var rng

func _ready():
	rng = RandomNumberGenerator.new()
	enterState(MonsterState.NORMAL)

func _physics_process(delta):
	
	# run state logic
	match monster_state:
		MonsterState.NORMAL:
			#execNormal()
			applyWalk(delta)
			applyGravity(delta)
		MonsterState.HOLD_ITEM:
			applyWalk(delta)
			applyGravity(delta)
		MonsterState.HOLD_MONSTER:
			applyWalk(delta)
			applyGravity(delta)
		MonsterState.THROW:
			applyGravity(delta)
			execThrow()
		MonsterState.FLINCH:
			execFlinch()
		#MonsterState.GRAB:
		#	execGrab()
		#MonsterState.SPECIAL1:
		#   execSpecial1()
		_:
			pass

	# move based on the velocity and snap to the ground
	velocity = move_and_slide_with_snap(velocity, Vector2.DOWN, Vector2.UP)
	
	# bounce off of walls check WAS HERE
	
	if reverse_direction_lockout_frames > 0:
		reverse_direction_lockout_frames -= 1
	
	
	# test for collisions
	# note: the test for item collisions happens in BaseItem.gd
	for i in get_slide_count():
		var collision : KinematicCollision2D = get_slide_collision(i) #https://docs.godotengine.org/en/3.0/classes/class_kinematicbody2d.html#class-kinematicbody2d-get-slide-collision
		
		print(collision.collider.name)
		
		# test for collision with action blocks
		if collision.collider.name == "TileMap":
			touchActionBlock(collision)
			
		# test for collisiion with monsters
		if "Monster" in collision.collider.name:
			# touched a monster!
			print("Touched ", collision.collider.name)
			touchMonster(collision.collider, collision.collider.monster_scene_path)
	
	# bounce off of walls check
	# note: this is tripped when monsters collide with eachother
	if is_on_wall():
		reverseDirection()
		velocity.y = -wall_bounce_y_speed
		velocity.x *= wall_bounce_x_speed_factor
		
	# apply direction to sprites
	if current_direction == Direction.LEFT:
		$"AnimatedSprite-0".flip_h = true
		$"AnimatedSprite-2".flip_h = true
	else:
		$"AnimatedSprite-0".flip_h = false
		$"AnimatedSprite-2".flip_h = false
	
func playAnimation(animation_name):
	$"AnimatedSprite-0".play(animation_name)
	
	if $"AnimatedSprite-2".frames.get_animation_names().has(animation_name):
		$"AnimatedSprite-2".play(animation_name)
	else:
		$"AnimatedSprite-2".play("none")
		

func stopAnimation():
	$"AnimatedSprite-0".stop() # or play jumping/airborn anim
	$"AnimatedSprite-2".stop()

func pickupItem(item):
		# mechanical item pickup procedure
		item_sprite_node = item.get_node("AnimatedSprite")
		
		#attach item to self
		item.remove_child(item_sprite_node)
		add_child(item_sprite_node)
		
		item_sprite_node.translate(item_position_translate)
		item_sprite_node.translate(Vector2(0, item_additional_collision_height))
		
		# apply translate to item sprite if we are facing left while picking up the item
		if current_direction == Direction.LEFT:
			item_sprite_node.translate(Vector2(-2 * item_position_translate.x, 0))
			pass
		
		# delete item node
		item.get_parent().remove_child(item) # or try calling something you make like item.killSelf()
		
		$CollisionShape2D.shape.extents.y += item_additional_collision_height
		# also have to modify position of each animatedSprite
		$"AnimatedSprite-0".position.y += item_additional_collision_height
		$"AnimatedSprite-2".position.y += item_additional_collision_height
		#position.y -= item_additional_collision_height # need some way of snapping monster back onto the ground.. :/
		

func pickupMonster(monster):
	held_monster_sprite_node_0 = monster.get_node("AnimatedSprite-0")
	held_monster_sprite_node_2 = monster.get_node("AnimatedSprite-2")
	
	# avoid name colisions?
	held_monster_sprite_node_0.name = "HeldMonsterAnimatedSprite-0"
	held_monster_sprite_node_2.name = "HeldMonsterAnimatedSprite-2"
	
	# position and flip sprites
	held_monster_sprite_node_0.translate(item_position_translate * 0.5)
	held_monster_sprite_node_2.translate(item_position_translate * 0.5)
	held_monster_sprite_node_0.set_flip_v(true)
	held_monster_sprite_node_2.set_flip_v(true)
	held_monster_sprite_node_0.set_flip_h(false)
	held_monster_sprite_node_2.set_flip_h(false)
	
	# delete monster
	monster.get_parent().remove_child(monster)
	
	#attach sprites to self
	monster.remove_child(held_monster_sprite_node_0)
	monster.remove_child(held_monster_sprite_node_2)
	add_child(held_monster_sprite_node_0)
	add_child(held_monster_sprite_node_2)

func applyWalk(delta):
	# net_lr_input = (Input.get_action_strength("move_right") - Input.get_action_strength("move_left"))
	if current_direction == Direction.LEFT:
		net_lr_input = -walk_force
	else:
		net_lr_input = walk_force
		
	velocity.x += net_lr_input * delta
	
	# clamp to the maximum horizontal movement speed
	velocity.x = clamp(velocity.x, -max_walk_speed, max_walk_speed)

func applyGravity(delta):
	velocity.y += gravity * delta
	
func reverseDirection():

	# invert the monster sprites horizontal offset
	$"AnimatedSprite-0".position.x *= -1
	$"AnimatedSprite-2".position.x *= -1
	
	current_direction = Direction.RIGHT if current_direction == Direction.LEFT else Direction.LEFT
	
	if monster_state == MonsterState.HOLD_ITEM:
		if current_direction == Direction.LEFT:
			item_sprite_node.translate(Vector2(-2 * item_position_translate.x, 0)) # item_position_translate.y
		else:
			item_sprite_node.translate(Vector2(2 * item_position_translate.x, 0))
			

func throwObject(throw_velocity: Vector2):
	
	# derive absolute_velocity from velicity + current_direction + throw_velocity
	
	print("throwObject()")
	var obj
	if monster_state == MonsterState.HOLD_ITEM:
		# delete attached AnimatedSprite node
		remove_child(item_sprite_node)
		item_sprite_node.queue_free()	
		obj = held_item_scene.instance()
		
		# assign it throw_velocity
		obj.apply_central_impulse(throw_velocity)
		
	if monster_state == MonsterState.HOLD_MONSTER:
		remove_child(held_monster_sprite_node_0)
		remove_child(held_monster_sprite_node_2)
		
		held_monster_sprite_node_0.queue_free()
		held_monster_sprite_node_2.queue_free()
		
		#print(held_monster_scene)
		obj = held_monster_scene.instance()
		obj.velocity = throw_velocity
		obj.current_direction = current_direction
		# TODO: apply HP and other saved monster attributes to thrown monster
		
	# spawn obj at our current coordinates
	obj.position = position + Vector2(0, -200)
	
	$"../".add_child(obj)
	
	# remove extra hitbox height from item
	$CollisionShape2D.shape.extents.y -= item_additional_collision_height
	$"AnimatedSprite-0".position.y -= item_additional_collision_height
	$"AnimatedSprite-2".position.y -= item_additional_collision_height
	
	

func touchActionBlock(collision):
	
	var pos : Vector2 = tile_map.world_to_map(collision.position)
	print(pos)
	var id : int = tile_map.get_cellv(pos)
	
	
	if id < 0:
		print("ERROR: called touchActionBlock() while not touching a valid action block")
		# we have to return here because if we continue with -1 we will just be activating the last block in the TILE_NAMES array
		return
		
	print("on ", id, " ", TILE_NAMES[id])
	
	#print("Walking on ", TILE_NAMES[id], " block")
	match TILE_NAMES[id]:
		"HoldReverse":
			if not holding():
				reverse_block_lockout = false
		"EmptyReverse":
			if holding():
				reverse_block_lockout = false
		"Reverse":
			pass
		_:
			reverse_block_lockout = false
	
	
	# check if the block is covered in paint
	var paint_id : int = paint_map.get_cellv(pos)
	if paint_id > 0:
		if TILE_NAMES[paint_id] == "Painted":
			return
	
	
	# match breaks by default, "continue" for fallthrough
	match TILE_NAMES[id]:
		"Normal":
			#TODO: play walk animation while grounded
			pass
		
		"Jump":
			touchJumpBlock()
		"EmptyJump":
			if not holding():
				touchJumpBlock()
		"HoldingJump":
			if holding():
				touchJumpBlock()
		
		"HoldReverse":
			if holding():
				touchReverseBlock()
		"EmptyReverse":
			if not holding():
				touchReverseBlock()
		"Reverse":
			print("uh")
			touchReverseBlock()
		
		"Throw":
			if holding():
				enterState(MonsterState.THROW)
		"Kill":
			if not dead:
				touchKillBlock()
				dead = true
			queue_free()
		_:
			pass

func touchJumpBlock():
	velocity.y = -jump_y_speed

func touchReverseBlock():
	if not reverse_block_lockout:
		reverseDirection()
		velocity.x *= 0.2
		reverse_block_lockout = true

func touchKillBlock():
	if holding():
		# "final throw" velocity gets a 50% boost ( * 1.5 )
		var throw_velocity = Vector2(throw_strength * 1.5, 0).rotated(-deg2rad(throw_angle)) 
		if current_direction == Direction.LEFT:
			throw_velocity.x *= -1
		throwObject(throw_velocity)
	spawnGhost()
	
func spawnGhost():
		var ghost = ghost_scene.instance()
		ghost.position = position
		$"../".add_child(ghost)

func enterState( new_monster_state : int, args = []):
	
	# don't enter a state we're already in
	if new_monster_state == monster_state:
		return
	
	print("Entering, ", MonsterState.keys()[new_monster_state])
	
	# EXIT the current state
	match monster_state:
		#MonsterState.NORMAL:
		#MonsterState.HOLD_ITEM:
		#MonsterState.HOLD_MONSTER:
		#MonsterState.THROW:
		MonsterState.FLINCH:
			exitFlinch()
		#MonsterState.GRAB:
		#MonsterState.SPECIAL1:
		_:
			pass
	
	# ENTER the new state
	match new_monster_state:
		MonsterState.NORMAL:
			enterNormal()
		MonsterState.HOLD_ITEM:
			enterHoldItem(args[0])
		MonsterState.HOLD_MONSTER:
			enterHoldMonster(args[0])
		MonsterState.THROW:
			enterThrow()
		MonsterState.FLINCH:
			enterFlinch(args[0])
		MonsterState.GRAB:
			pass
		MonsterState.SPECIAL1:
			pass
	
	# update state history
	prev_monster_state = monster_state
	monster_state = new_monster_state

func holding():
	return monster_state == MonsterState.HOLD_ITEM or monster_state == MonsterState.HOLD_MONSTER
	
# ================================================================================
# ============================ INDIVIDUAL MONSTER BEHAVIOR =======================
# ================================================================================
# override these functions to implement custom monster behavior

#func onLanding():
#	pass
# determine what to do after a monster has been touched
func touchMonster(other_monster, scene_path : String):
	
	print("other monsters pickup priority:", other_monster.pickup_priority, ", our pickup priority", pickup_priority)
	
	# dont pickup the other monster under these conditions 
	# TODO: turn this into canPickupMonster(other_monster)?
	if (
		other_monster.pickup_priority >= pickup_priority or
		holding() or
		other_monster.holding()
		):
		return
	# pickup the monster
	
	print(scene_path)
	held_monster_scene = load(scene_path)
	
	enterState(MonsterState.HOLD_MONSTER, [other_monster])
	
	
# determine what to do after an item has been touched
# note: this is ONLY called by items
func touchItem(item, scene_path : String): # TODO: pass more than just the item_id, need positional data and stuff too
	#print("picking up ", item)
	if holding():
		if reverse_direction_lockout_frames == 0:
			velocity.x *= -1 # LOOOOL THIS CODE SUCKS
			reverseDirection()
			reverse_direction_lockout_frames = reverse_direction_lockout_amount
	if canPickupItem(item):
		held_item_scene = load(scene_path) # might have to move this...?
		enterState(MonsterState.HOLD_ITEM, [item])



# determine what to do after a monster receives damage from an item
# note: this is ONLY called by items
func damageFromItem(item, damage : int, damage_direction : Vector2):
	print("damageFromItem(", damage, ")")
	
	# drop current item if one is held
	if holding():
		throwObject(Vector2(damage_direction.x, -damage_direction.y) * 1)
		
	
	# apply damage
	
	# update hp bar
	
	# enter flinch state for x frames
	enterState(MonsterState.FLINCH, [floor(damage / 4)])
	
	# fly away from damage_direction 
	
	
	
	pass
	
	

	
#IMPLEMENT canPickupItem PER MONSTER
func canPickupItem(_item : KinematicCollision2D):
	return true

# func monsterMonsterInteraction()

#{HOLD_ITEM, HOLD_MONSTER, THROW, FLINCH, NORMAL, GRAB, SPECIAL1}
# enter, exit, and exec state functions
# these can be overwritten by moster classes
# if any of the enter_ exit_ or exec_ don't exist, then its safe to assume they are trivial and would be implemented as "pass"

func enterNormal():
	playAnimation("walk")

func enterThrow():
	playAnimation("throw")
	
	var throw_velocity = Vector2(throw_strength, 0).rotated(deg2rad(throw_angle)) 
	
	if current_direction == Direction.LEFT:
		throw_velocity.x *= -1
	
	# -y is up
	throw_velocity.y *= -1
		
	
	throwObject(throw_velocity)
	
	# set throw animation timer
	frame_count = 0
func execThrow():
	
	# stop moving
	velocity.x = 0.9 * velocity.x
	
	# wait until throw_frames are up
	frame_count += 1
	if frame_count >= throw_frames:
		frame_count = 0
		enterState(MonsterState.NORMAL)
	

func enterGrab():
	pass
func execGrab():
	pass

func enterHoldItem(item):
	playAnimation("walk-hold")
	pickupItem(item)

func enterHoldMonster(monster):
	playAnimation("walk-hold")
	pickupMonster(monster)

func enterFlinch(flinch_frames):
	playAnimation("flinch")
	
	temp_sprite_position_0 = $"AnimatedSprite-0".position
	temp_sprite_position_2 = $"AnimatedSprite-2".position
	
	velocity.x = 0
	velocity.y = 0
	
	frame_count = flinch_frames
	# apply damage to health

func execFlinch():
	if frame_count > 0:
		frame_count -= 1
		
		# randomly update visual position
		rng.randomize()
		
		$"AnimatedSprite-0".position = temp_sprite_position_0 + Vector2(rng.randi_range(-shake_radius, shake_radius),rng.randi_range(-shake_radius, shake_radius))
		$"AnimatedSprite-2".position = temp_sprite_position_0 + Vector2(rng.randi_range(-shake_radius, shake_radius),rng.randi_range(-shake_radius, shake_radius))
	if frame_count == 0:
		
		spawnGhost()
		queue_free()
				
		#enterState(MonsterState.NORMAL)

func exitFlinch():
	$"AnimatedSprite-0".position = temp_sprite_position_0
	$"AnimatedSprite-2".position = temp_sprite_position_0
