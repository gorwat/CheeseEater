extends Node

const AIM_SPEED = 10.0;
const CAGE = preload("scenes/Cage.tscn");
const CAGE_COOLDOWN = 2.0;
var current_cage_cooldown = 0.0;
const CAGE_DROP_HEIGHT = 10.0;
var over_obsticle = false;
var next_cage_idx = 0;

@onready var aim = $Aim;
@onready var aim_frame = $Aim/frame;
@onready var cages = $Cages;
@onready var cage = $Cage;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cage.connect("update_cage", %NetworkManager.update_cage)


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
	
	if over_obsticle:
		aim_frame.modulate = Color(1.0,0.5,0.5)
	elif current_cage_cooldown > 0:
		aim_frame.modulate = Color(0.5,0.5,0.5)
	else:
		aim_frame.modulate = Color(1.0,1.0,1.0)
	
	
	if Input.get_action_strength("scoop_drop") and current_cage_cooldown == 0 and not over_obsticle:
		self.new_cage();
		current_cage_cooldown = CAGE_COOLDOWN;
		
func new_cage():
	cage.position = aim.position;
	cage.position.y = CAGE_DROP_HEIGHT;
	cage.connect("caught_rat", _on_rat_caught);
	cage.reset()
	

func _on_rat_caught():
	print("rat caught")
	%NetworkManager._on_claw_rat_caught()
	

func _on_cage_piller_entered(area: Area3D) -> void:
	over_obsticle = true


func _on_cage_pillar_exited(area: Area3D) -> void:
	over_obsticle = false
