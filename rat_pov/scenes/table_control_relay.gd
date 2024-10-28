extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	# for now, use device 1. maybe allow swap later?
	var direction_d1 = Vector3(
		Input.get_action_strength("right_d1") - Input.get_action_strength("left_d1"),
		0.0,
		Input.get_action_strength("down_d1") - Input.get_action_strength("up_d1"),
	).limit_length(1.0);
	
	var drop_cage = Input.get_action_strength("table_drop_cage_d1") > 0;
	
	%NetworkManager.relay_table_controls.rpc(direction_d1, drop_cage);
	
	
	
