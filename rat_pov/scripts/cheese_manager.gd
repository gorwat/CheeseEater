extends Node

var cheese_positions = [Vector3(1,1,2),
						Vector3(1,1,4)]
var cheese_template

var current_cheese_count = 0;
var max_cheese_count = 0;

var time_to_cheese = 0
var time_between_cheese = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	time_to_cheese = time_between_cheese
	cheese_template = load("res://scenes/small_objects/cheese.tscn")
	for cheese in get_children():
		cheese.despawn()
		max_cheese_count += 1
	
	spawn_random_cheese()

func spawn_random_cheese():
	if current_cheese_count >= max_cheese_count:
		return
	
	var cheese_idx = randi_range(0, max_cheese_count - 1);
	var cheese = self.get_children()[cheese_idx]
	if cheese.is_spawned:
		spawn_random_cheese()
	else:
		cheese.spawn()
		current_cheese_count += 1
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_to_cheese -= delta
	if time_to_cheese <= 0:
		spawn_random_cheese()
		time_to_cheese = time_between_cheese
		