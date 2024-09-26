extends Node3D
enum ScoopState {Passive, MovingUp, MovingDown, }

var scoop_speed: float = 10.0;
var scoop_drop_speed: float = 6.0;
var scoop_state: ScoopState = ScoopState.Passive;
var top_y = 10.0;
var bot_y = 0.0;


var crosshair_min_scale = 0.5;
var crosshair_max_scale = 1;

var size_x = 7.5;
var size_z = 5.0;

var time_to_catch = 1.0; # Counts down when rat is in claw range, counts up when outside.
var max_time_to_catch = 0.60;

@onready var crosshair : Node3D = $Crosshair;
@onready var crosshair_frame: Sprite3D = $Crosshair/frame;
@onready var label: Label3D = $Label;
@onready var rat: CharacterBody3D = %Player;
@onready var networkmanager: Node = %NetworkManager;

signal rat_caught

func _ready():
	$outline.modulate = Color(1,1,1,0.75);
	

func _process(delta: float):
	var direction = Vector3(
		Input.get_action_strength("scoop_right") - Input.get_action_strength("scoop_left"),
		0.0,
		Input.get_action_strength("scoop_back") - Input.get_action_strength("scoop_forward"),
	).limit_length(1.0);
	var delta_pos = direction * (delta * scoop_speed);
	self.position += delta_pos;

	if Input.get_action_strength("scoop_drop"):
		pass
	
	var rat_in_bounds = abs(rat.position.x - self.position.x) < (size_x / 2) and abs(rat.position.z - self.position.z) < (size_z / 2);
	
	# Rat raycast
	var space_state = get_world_3d().direct_space_state;
	var origin = rat.position + Vector3(0,1,0);
	var end = rat.position + Vector3(0,3,0);
	var ray_query = PhysicsRayQueryParameters3D.create(origin, end);
	ray_query.collide_with_areas = true;
	var ray_res = space_state.intersect_ray(ray_query);
	var rat_ray_clear = ray_res.is_empty();
	
	var charge_fraction = 1 - time_to_catch / max_time_to_catch; # one - zero: how near are we to catch
	
	#print("ratInBox: " + str(rat_in_bounds) + "  ratRayHit: " + str(rat_ray_clear));
	if (rat_in_bounds):
		time_to_catch -= delta;
		time_to_catch = max(time_to_catch, 0);
		
		crosshair.position.x = rat.position.x - self.position.x;
		crosshair.position.z = rat.position.z - self.position.z;
		crosshair_frame.modulate = Color(0.5 + charge_fraction * 0.5, charge_fraction * 0.5, charge_fraction * 0.5);
	else:
		time_to_catch += delta;
		time_to_catch = min(time_to_catch, max_time_to_catch);
		crosshair.position = Vector3.ZERO;
		
		crosshair_frame.modulate = Color(0.5,0.5,0.5,0.5);
											   
	
	var can_catch : bool = rat_in_bounds and rat_ray_clear and time_to_catch == 0;
	#$Crosshair/full.visible = can_catch;
	
	if (can_catch):
		#$Crosshair/full.modulate = Color(0.5, 1, 0.5);
		crosshair_frame.modulate = Color(0.5, 1, 0.5);
		if Input.get_action_strength("scoop_drop"):
			print("WE GOT THE RAT!");
			rat_caught.emit()
	
	var s = lerp( crosshair_min_scale, 1.0, time_to_catch / max_time_to_catch)
	crosshair.set_scale(Vector3(s,1,s));
	
	#label.text = str(round(time_to_catch * 10) / 10) + "s"
		
		
