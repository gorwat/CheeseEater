extends Node3D

signal been_eaten

var is_spawned = true;

func spawn():
	is_spawned = true;
	self.position.y = -0.4
	
func despawn():
	is_spawned = false;
	self.position.y = -5

	

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func _on_area_3d_body_entered(body):
	if not is_spawned:
		return
	print("Ate cheese!")
	despawn()
	been_eaten.emit()
	pass # Replace with function body.
