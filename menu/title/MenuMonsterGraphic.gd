extends RigidBody2D

export (Vector2) var init_force

var amplitude : float = 1.0
var period    : int = 100
var frame     : int = 0

func _ready():
	#apply_central_impulse(init_force)
	gravity_scale = 0

func _physics_process(delta):
	return
	
	#if frame == period / 2:
	#	gravity_scale = 0
	#	apply_central_impulse(Vector2.UP * amplitude)
	if frame % period == 0:
		print("downing")
		apply_central_impulse(Vector2.DOWN * amplitude)
	if (frame + period / 2) % period == 0:
		print("upping")
		apply_central_impulse(Vector2.UP * amplitude)
	frame += 1
		
		
