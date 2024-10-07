extends Node

const AIM_SPEED = 10.0;
const CAGE = preload("scenes/Cage.tscn");
const CAGE_COOLDOWN = 3.0;
var current_cage_cooldown = 0.0;
const CAGE_DROP_HEIGHT = 10.0;

@onready var aim = $Aim;
@onready var cages = $Cages;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	current_cage_cooldown = clamp(current_cage_cooldown - delta, 0, CAGE_COOLDOWN);
	
	
	var direction = Vector3(
		Input.get_action_strength("scoop_right") - Input.get_action_strength("scoop_left"),
		0.0,
		Input.get_action_strength("scoop_back") - Input.get_action_strength("scoop_forward"),
	).limit_length(1.0);
	var delta_pos = direction * (delta * AIM_SPEED);
	aim.position += delta_pos;
	
	
	if Input.get_action_strength("scoop_drop") and current_cage_cooldown == 0:
		var new_cage = CAGE.instantiate();
		new_cage.position = aim.position;
		new_cage.position.y = CAGE_DROP_HEIGHT;
		cages.add_child(new_cage);
		current_cage_cooldown = CAGE_COOLDOWN;
		
	
