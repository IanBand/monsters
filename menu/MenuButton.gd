extends TextureButton

export (String, FILE) var scene_to_load
export (bool) var is_quit

func _pressed():
	if is_quit:
		get_tree().quit()
	get_tree().change_scene(scene_to_load)
