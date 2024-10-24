extends Node3D

signal caught_rat;
signal update_cage;
@onready var dust = $DustParticles;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var falling = true;
var fall_vel = 25;
const FALL_ACC = 9.8;
const MIN_Y = 0;
# const START_FALL_VEL = 9.8;

var time_to_live = 1.5; # Time until despawn AFTER hitting the ground.


var current_rotation_speed = 0.05; # Rotation speed while falling
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
		self.rotate(Vector3.UP, current_rotation_speed);
		current_rotation_speed -= ROTATION_SPEED_SLOWDOWN * delta;
		current_rotation_speed = max(0.0, current_rotation_speed);
		
	self.update_cage.emit(self.name, self.position, self.rotation, self.time_to_live)




func _on_rat_in_cage(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	print("rat gotten! body")
	caught_rat.emit()
	time_to_live = 10; # so that the player has time to watch the rat in a cage 
