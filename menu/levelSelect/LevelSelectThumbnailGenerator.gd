extends GridContainer


var level_thumbnail_scene = preload("res://menu/levelSelect/LevelThumbnail.tscn")

var rng = RandomNumberGenerator.new()

func _ready():
	
	rng.randomize()
	
	# create level preview button for every level
	for i in LevelsMemory.monsters_in_level.size():
		
		var thumbnail = level_thumbnail_scene.instance()
		
		var world : int = floor(i / 6) + 1
		var level : int = i + 1
		
		
		# attach correct images to TextureButton and TextureRect in thumbnail
		
		if i <= LevelsMemory.level_complete: 
			# level thumbnail will be a screenshot. get from screenshots folder
			
			thumbnail.texture_normal = load("res://menu/levelSelect/screenshots/test.png")
			# thumbnail.texture_hover = 
			# thumbnail.texture_pressed = 
			
			# level is playable
			thumbnail.set_default_cursor_shape(CURSOR_POINTING_HAND)
			
			
			if i < LevelsMemory.level_complete:
				var completion_star = thumbnail.get_node("CompletionStar")
				completion_star.texture = load("res://menu/levelSelect/numbers/level-complete-star-normal.png")
				completion_star.anchor_top = 0.1 + rng.randf_range(-0.05, 0.05)
				completion_star.anchor_left = 0.55 + rng.randf_range(-0.05, 0.05)
				# if special_completion
					# level will have a blue star signifying a spepcial completion
				# else
					# level will have a gold star signifying that it has been completed
				pass
		else:
			# level thumbnail will be the world default
			thumbnail.texture_normal = load("res://menu/levelSelect/thumbnails/level-thumbnail-normal" + String(world) + ".png")
		
		
		
		# assign number texture to thumbnail
		var number = thumbnail.get_node("Number")
		number.texture = load("res://menu/levelSelect/numbers/number" + String(level) + ".png")
		number.anchor_top  = 0.1
		number.anchor_left = 0.1
		
		# adjust margins, click functionality
		
		add_child(thumbnail)
		
