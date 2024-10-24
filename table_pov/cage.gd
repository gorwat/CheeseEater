extends Node3D

signal caught_rat;
signal update_cage;
@onready var dust = $DustParticles;

# Called when the node enters the scene tree for the first time.

var falling = true;
var fall_vel = 10;
const START_FALL_VEL = 10;
const FALL_ACC = 9.8;
const MIN_Y = 0;
# const START_FALL_VEL = 9.8;

var time_to_live = 1.5; # Time until despawn AFTER hitting the ground.
var MAX_TIME_TO_LIVE = 1.5

var current_rotation_speed = 0.05; # Rotation speed while falling
const START_ROTATION_SPEED = 0.05;
const ROTATION_SPEED_SLOWDOWN = 0.025; 
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _ready() -> void:
	self.set_process(false)
	self.hide()
	
func reset():
	self.fall_vel = START_FALL_VEL;
	self.falling = true;
	self.time_to_live = MAX_TIME_TO_LIVE;
	self.current_rotation_speed = START_ROTATION_SPEED;
	self.set_process(true)
	self.show()
	update_cage.emit(self.position, self.rotation, true)
	# note that the position must be set by caller
	

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
			self.update_cage.emit(self.position, self.rotation, false)
			self.set_process(false)
			self.hide()
			return
			
	else:
		self.rotate(Vector3.UP, current_rotation_speed);
		current_rotation_speed -= ROTATION_SPEED_SLOWDOWN * delta;
		current_rotation_speed = max(0.0, current_rotation_speed);
		
	self.update_cage.emit(self.position, self.rotation, true)




func _on_rat_in_cage(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	print("rat gotten! body")
	caught_rat.emit()
	time_to_live = 10; # so that the player has time to watch the rat in a cage 
