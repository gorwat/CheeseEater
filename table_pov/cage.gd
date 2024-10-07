extends Node3D


@onready var dust = $DustParticles;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var falling = true;
var fall_vel = 9.8;
const FALL_ACC = 9.8;
const MIN_Y = 0;
# const START_FALL_VEL = 9.8;

var time_to_live = 4.0; # Time until despawn AFTER hitting the ground.


var current_rotation_seed = 0.05; # Rotation speed while falling
const ROTATION_SPEED_SLOWDOWN = 0.025; 
# Called every frame. 'delta' is the elapsed time since the previous frame.


func _process(delta: float) -> void:
	if falling == true:
		fall_vel += delta * FALL_ACC;
	self.position.y -= fall_vel * delta;
	self.position.y = max(MIN_Y, self.position.y)
	
	if self.position.y == MIN_Y:
		if falling:
			dust.emitting = true;
		falling = false;
		time_to_live -= delta;
		if time_to_live < 0:
			self.queue_free();
	else:
		self.rotate(Vector3.UP, current_rotation_seed);
		current_rotation_seed -= ROTATION_SPEED_SLOWDOWN * delta;
		current_rotation_seed = max(0.0, current_rotation_seed);
