extends Node3D

var cheese_asset
enum Status{CONNECTED, DISCONNECTED, CONNECTING}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cheese_asset = load("res://scenes/small_objects/cheese.tscn")

func spawn(cheese_name:String, position:Vector3, rotation:Vector3):
	var new_cheese = cheese_asset.instantiate()
	new_cheese.position = position
	new_cheese.rotation = rotation
	new_cheese.name = cheese_name
	add_child(new_cheese)

func despawn(cheese_name:String):
	remove_child(get_node(cheese_name))

func _on_network_manager_cheese_spawned(cheese_name:String, position:Vector3, rotation:Vector3) -> void:
	spawn(cheese_name, position, rotation)

func _on_network_manager_cheese_eaten(cheese_name:String) -> void:
	despawn(cheese_name)

func _on_network_manager_connection_status_schanged(status) -> void:
	if Status.DISCONNECTED:
		for child in get_children():
			remove_child(child)

func _on_network_manager_game_started(_session_durration):
	var children = get_children()
	for child in children:
		child.queue_free()
