extends Node

const PORT = 3353 #CH3353
const SERVER_ADDRESS = 'localhost'

var peer = ENetMultiplayerPeer.new()
var is_connected = false
signal rat_pos_recieved

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print(IP.get_local_interfaces())
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_connected_to_server(id:int) -> void:
	is_connected = true;
	print("Connected to server, yay!")
	pass

func _on_server_disconnected(id:int) -> void:
	is_connected = false;
	print("Server disconnected")
	pass

func _on_init_connection(ip: String) -> void:
	# Create client.
	match peer.create_client(ip, PORT):
		OK: print("Client created")
		_ : print("Client not created :(")
	peer.peer_connected.connect(_on_connected_to_server)
	peer.peer_disconnected.connect(_on_server_disconnected)
	multiplayer.multiplayer_peer = peer
	
func _on_spot_light_3d_spot_position_changed(is_on: bool, position : Vector3):
	if is_connected:
		set_spot_position.rpc(is_on, position)

@rpc
func set_rat_position(position : Vector3, rotation : Vector3):
	print("Rat position recieved: ", position, " ", rotation)
	rat_pos_recieved.emit(position, rotation)

@rpc
func set_spot_position(is_on: bool, position : Vector3):
	pass
