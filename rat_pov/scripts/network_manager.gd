extends Node

const PORT = 3353 #CH3353
const MAX_CLIENTS = 1

signal spot_positions_changed
signal rat_was_caught
signal timer_out
signal game_started

var peer = ENetMultiplayerPeer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create server.
	peer.create_server(PORT, MAX_CLIENTS)
	peer.peer_connected.connect(_on_client_connected)
	peer.peer_disconnected.connect(_on_client_disconnected)
	multiplayer.multiplayer_peer = peer
	print(IP.get_local_interfaces())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_P):
		print("Attempt to send rat position")
		set_rat_position.rpc()

func _on_client_disconnected(id: int):
	print("Disconnected :%(")

func _on_client_connected(id: int):
	print("Connected!")
	
func _on_player_rat_moved(position : Vector3, rotation : Vector3):
	#print("Attempt to send rat position")
	set_rat_position.rpc(position, rotation)
	
func _on_cheese_manager_specific_cheese_eaten(cheese_name) -> void:
	sync_cheese_eaten.rpc(cheese_name)
	
func _on_cheese_manager_specific_cheese_spawned(cheese_name, position, rotation) -> void:
	sync_cheese_spawn.rpc(cheese_name, position, rotation)

@rpc
func set_rat_position(position : Vector3, rotation : Vector3):
	#print("Rat position sent")
	pass

@rpc("any_peer")
func set_spot_positions(positions: PackedVector3Array, angles: PackedFloat32Array):
	spot_positions_changed.emit(positions, angles)

@rpc("any_peer")
func catch_rat():
	rat_was_caught.emit()

@rpc("any_peer")
func time_out():
	timer_out.emit()

@rpc("any_peer")
func start_game():
	game_started.emit()
	
@rpc("any_peer")
func sync_cheese_spawn(cheese_name:String, position:Vector3, rotation:Vector3):
	pass
	
@rpc("any_peer")
func sync_cheese_eaten(cheese_name:String):
	pass
