extends Node

const PORT = 3353 #CH3353
const SERVER_ADDRESS = 'localhost'

var peer = ENetMultiplayerPeer.new()
enum Status{CONNECTED, DISCONNECTED, CONNECTING}
var connection_status = Status.DISCONNECTED

signal rat_pos_recieved
signal connection_status_schanged
signal cheese_spawned
signal cheese_eaten
signal game_started
signal rat_force_quit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print(IP.get_local_interfaces())
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
func _on_connected_to_server(id:int) -> void:
	connection_status = Status.CONNECTED
	connection_status_schanged.emit(connection_status)
	print("Connected to server, yay!")
	pass

func _on_server_disconnected(id:int) -> void:
	connection_status = Status.DISCONNECTED
	connection_status_schanged.emit(connection_status)
	print("Server disconnected")
	pass

func _on_init_connection(ip: String) -> void:
	# Create client.
	match peer.create_client(ip, PORT):
		OK: 
			print("Client created")
			connection_status = Status.CONNECTING
			connection_status_schanged.emit(connection_status)
		_ : print("Client not created :(")
	peer.peer_connected.connect(_on_connected_to_server)
	peer.peer_disconnected.connect(_on_server_disconnected)
	multiplayer.multiplayer_peer = peer

func _on_light_manager_spot_positions_changed(positions: PackedVector3Array, angles: PackedFloat32Array):
	if connection_status == Status.CONNECTED:
		set_spot_positions.rpc(positions, angles)

func _on_claw_rat_caught() -> void:
	catch_rat.rpc()

# rpcs called from rat
@rpc
func set_rat_position(position : Vector3, rotation : Vector3):
	rat_pos_recieved.emit(position, rotation)

@rpc
func start_game(session_duration: int):
	game_started.emit(session_duration)
	
@rpc
func force_quit():
	rat_force_quit.emit()
	
# rps called from table
@rpc
func set_spot_positions(positions: PackedVector3Array, angles: PackedFloat32Array):
	pass

@rpc
func sync_cheese_spawn(cheese_name:String, position:Vector3, rotation:Vector3):
	cheese_spawned.emit(cheese_name, position, rotation)
	
@rpc
func sync_cheese_eaten(cheese_name:String):
	print("cheese eaten")
	cheese_eaten.emit(cheese_name)

@rpc
func update_cage(position: Vector3, rotation: Vector3, enable: bool):
	update_cage.rpc(position, rotation, enable)
