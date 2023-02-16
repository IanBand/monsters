extends KinematicBody2D


const YSPEED = 300
const AMPLITUDE = 4
const FREQ = 5
const DESPAWN = 10
var t = 0

var rng 
var phase : float
var frequency_variance : float
var amp_variance : float


func _ready():
	
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	phase = rng.randf_range(-1.0, 1.0)
	frequency_variance = rng.randf_range(-1.0, 1.0)
	amp_variance = rng.randf_range(-1.0, 1.0)
	
	$AnimatedSprite.play()

func _process(delta):
	t += delta
	position.x += sin(t * (FREQ + frequency_variance) + phase ) * ( AMPLITUDE + amp_variance) 
	position.y += -1 * YSPEED * delta
	
	if t > DESPAWN:
		queue_free()
		pass
