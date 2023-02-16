extends TextureButton

#onready var lvl_select_scene = preload()

func _pressed():
	get_tree().change_scene("res://menu/levelSelect/LevelSelectMenu.tscn")
