extends Node
const CAGE = preload("../scenes/Cage.tscn");

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_cage(cage_name: String, position: Vector3, rotation: Vector3, time_to_live: float):
	print("updating cage" + cage_name)
	var cage = self.find_child(cage_name)
	if cage == null:
		var new_cage = CAGE.instantiate();
		new_cage.name = cage_name;
		self.add_child(new_cage)
		cage = new_cage
	cage.position = position;
	cage.rotation = rotation;
	if time_to_live < 0:
		cage.queue_free();	
