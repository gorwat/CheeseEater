extends Node

signal update_cheeses_eaten
signal specific_cheese_eaten
signal specific_cheese_spawned

var cheese_template

var current_cheese_count = 0;
var max_cheese_count = 0;

var time_to_cheese = 0
var time_between_cheese = 5

@export var cheeses_eaten = 0

enum GameState {INIT, RUNNING, TIME_OUT, RAT_CAUGHT, FORCE_QUIT}
var current_game_state: GameState = GameState.INIT

# Called when the node enters the scene tree for the first time.
func _ready():
	time_to_cheese = time_between_cheese
	cheese_template = load("res://scenes/small_objects/cheese.tscn")
	despawn_all_cheese()

func despawn_all_cheese():
	max_cheese_count = 0
	current_cheese_count = 0
	
	for cheese in get_children():
		cheese.connect("been_eaten", _on_cheese_been_eaten)
		cheese.despawn()
		max_cheese_count += 1

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
	if (current_game_state == GameState.RUNNING):
		time_to_cheese -= delta
		if time_to_cheese <= 0:
			spawn_random_cheese()
			time_to_cheese = time_between_cheese
		
func _on_cheese_been_eaten(cheese_name) -> void:
	cheeses_eaten += 1;
	update_cheeses_eaten.emit(cheeses_eaten)
	specific_cheese_eaten.emit(cheese_name)

func _on_game_info_game_started(session_duration: int) -> void:
	cheeses_eaten = 0
	update_cheeses_eaten.emit(cheeses_eaten)
	despawn_all_cheese()

func _on_game_info_update_game_state(new_game_state: GameState) -> void:
	current_game_state = new_game_state
