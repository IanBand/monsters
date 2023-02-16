extends Area2D

#literally just copy pasting this between files
const MONSTER_DATA = [
	{
		"name": "Blocky",
		"scene_path": "res://monsters/blocky/BlockyMonster.tscn",
		"scene": "",
		"preview_path": "", # I wonder if I can just copy the animated sprite node from a loaded scene? prob have to instance it, yoink the node, then free the rest of it...
		"preview": ""
	},
	{
		"name": "Tooble",
		"scene_path": "res://monsters/tooble/ToobleMonster.tscn",
		"scene": "",
		"preview_path": "",
		"preview": ""
	}
]

# notes: 
# in selectable_monsters, monster type is determined by its index in MONSTER_DATA
export (Array, int) var selectable_monsters

var selected_monster_index : int = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	# shuffle selectable_monsters
	#randomize()
	#selectable_monsters.shuffle()
	
	# sort selectable monsters
	selectable_monsters.sort()
	# debug
	print("Level contains these monsters:")
	for i in selectable_monsters:
		print("\t", MONSTER_DATA[i].name)
	


	# create visual outline for spawning area
	# populate the line2D's points : PoolVector2Array property based on CollisionPolygon2D's polygon : PoolVector2Array property
	var points = $CollisionPolygon2D.polygon
	points.push_back(points[0])
	$"../Line2D".points = points
	$"../Line2D".position = $CollisionPolygon2D.position
	
	# create list of monster scenes to preload
	var preload_list = []
	for monster_index in selectable_monsters:
		if !preload_list.has(monster_index):
			preload_list.push_back(monster_index)
	
	# preload the monster scenes
	print("preloading:")
	for i in preload_list:
		print("\t",MONSTER_DATA[i].name)
		MONSTER_DATA[i].scene = load(MONSTER_DATA[i].scene_path)
	
	#init sprites for selectable_monsters
	
	#init conveyer belt graphic 

# handles clicking within the spawn area
func _input_event (_viewport : Object, event : InputEvent , _shape_idx : int ):
	
	#check if any monsters can be spawned at all
	if selectable_monsters.size() == 0:
		# play x graphic at mouse coordinate
		return
	
	if event is InputEventMouseButton:
		if event.is_pressed(): # falling edge
			if event.button_index == BUTTON_LEFT:
				#print("spawning ", MONSTER_DATA[selectable_monsters[selected_monster_index]].name, " at ", event.position)
				
				# spawn selected monster at the mouse position
				var spawned_monster = MONSTER_DATA[selectable_monsters[selected_monster_index]].scene.instance()
				spawned_monster.position = get_global_mouse_position()
				
				# add monster as a child of root
				$"./../../".add_child(spawned_monster)
				
				# delete monster from selectable_monsters array
				selectable_monsters.remove(selected_monster_index)
				
				# update currently selected monster & play spawner spawn animation
				if selectable_monsters.size() > 0:
					selected_monster_index = selected_monster_index % selectable_monsters.size()
				else:
					# remove spawner graphics
					$"../Line2D".hide()
				
				# debug
				updateAvailableMonstersLabel()
				
				
				

# handles scrolling i.e. selecting different monsters to spawn
func _unhandled_input(event):
	
	# check if any monsters are left to cycle through
	if selectable_monsters.size() <= 0:
		return
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			
			if event.button_index == BUTTON_WHEEL_UP:
				selected_monster_index += 1
			
			if event.button_index == BUTTON_WHEEL_DOWN:
				selected_monster_index += selectable_monsters.size() - 1 # ensures we dont mod a negative number
				
			selected_monster_index = selected_monster_index % selectable_monsters.size()
			
			updateAvailableMonstersLabel()

# will not be used???
func updateAvailableMonstersLabel():
	var monsters_str : String = ""
	
	for i in selectable_monsters.size():
		var draw_index = (i + selected_monster_index) % selectable_monsters.size()
		
		monsters_str = monsters_str + ", " + MONSTER_DATA[selectable_monsters[draw_index]].name
		
	$"./../CanvasLayer/DEBUG_MonstersLabel".text = monsters_str


func _process(_delta):
	
	pass
