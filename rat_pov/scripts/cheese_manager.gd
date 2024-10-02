extends Node

signal update_cheeses_eaten
signal specific_cheese_eaten
signal specific_cheese_spawned

var cheese_template

var current_cheese_count = 0;
var max_cheese_count = 0;

var time_to_cheese = 0
var time_between_cheese = 5

var cheeses_eaten = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	time_to_cheese = time_between_cheese
	cheese_template = load("res://scenes/small_objects/cheese.tscn")
	for cheese in get_children():
		cheese.connect("been_eaten", _on_cheese_been_eaten)
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
		specific_cheese_spawned.emit(cheese.name, cheese.position, cheese.rotation)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_to_cheese -= delta
	if time_to_cheese <= 0:
		spawn_random_cheese()
		time_to_cheese = time_between_cheese
		


func _on_cheese_been_eaten(cheese_name) -> void:
	cheeses_eaten += 1;
	update_cheeses_eaten.emit(cheeses_eaten)
	specific_cheese_eaten.emit(cheese_name)


func _on_network_manager_game_started() -> void:
	cheeses_eaten = 0
	update_cheeses_eaten.emit(cheeses_eaten)
