extends Node3D
enum ScoopState {Passive, MovingUp, MovingDown, }

var scoop_speed: float = 4.0;
var scoop_drop_speed: float = 6.0;
var scoop_state: ScoopState = ScoopState.Passive;
var top_y = 10.0;
var bot_y = 0.0;


func _process(delta: float):
	var direction = Vector3(
		Input.get_action_strength("scoop_right") - Input.get_action_strength("scoop_left"),
		0.0,
		Input.get_action_strength("scoop_back") - Input.get_action_strength("scoop_forward"),
	).limit_length(1.0);
	var delta_pos = direction * (delta * scoop_speed);
	self.position += delta_pos;

	if Input.get_action_strength("scoop_drop"):
		if (scoop_state == ScoopState.Passive):
			scoop_state = ScoopState.MovingDown;


	match (scoop_state):
		ScoopState.Passive:
			pass
		ScoopState.MovingDown:
			self.position -= Vector3(0, scoop_drop_speed, 0) * delta;
		ScoopState.MovingUp:
			self.position += Vector3(0, scoop_drop_speed, 0) * delta;
		_:
			pass
	
	self.position.y = clamp(bot_y, self.position.y, top_y);
	if position.y == top_y and scoop_state == ScoopState.MovingUp:
		scoop_state = ScoopState.Passive;
	if position.y == bot_y and scoop_state == ScoopState.MovingDown:
		scoop_state = ScoopState.MovingUp;

	$Label.text = str(round(position.y * 10)) + "m"
