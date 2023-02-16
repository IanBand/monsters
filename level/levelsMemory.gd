extends Node

# monsters unlocked after each level (this is the only data associated with each level)
var monsters_in_level = [
	[],[],[],[],[],[],
	[],[],[],[],[],[],
	[],[],[],[],[],[],
	[],[],[],[],[],[],
	[],[],[],[],[],[]
] 

# set when loading a level that has already been completed
# when true, players are allowed to spawn any monster that has appeared in any level before the level they have completed
var is_free_play = false

# this is the only game data that gets saved on exit lol
var level_complete = 7

# settings go here, they also get saved on exit


# Called when the node enters the scene tree for the first time.
func _ready():
	print("is free play?: ", is_free_play)
	#Engine.set_time_scale(1.5)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
