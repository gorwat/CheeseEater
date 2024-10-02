extends Node3D

var cheese_asset

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cheese_asset = load("res://scenes/small_objects/cheese.tscn")

func spawn(cheese_name:String, position:Vector3, rotation:Vector3):
	var new_cheese = cheese_asset.instantiate()
	new_cheese.position = position
	new_cheese.rotation = rotation
	new_cheese.name = cheese_name
	add_child(new_cheese)
	print(get_child(0), " ", get_child(0).name)

func despawn(cheese_name:String):
	remove_child(get_node(cheese_name))

func _on_network_manager_cheese_spawned(cheese_name:String, position:Vector3, rotation:Vector3) -> void:
	spawn(cheese_name, position, rotation)

func _on_network_manager_cheese_eaten(cheese_name:String) -> void:
	despawn(cheese_name)
