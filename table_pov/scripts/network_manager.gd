extends Node

const PORT = 3353 #CH3353
const SERVER_ADDRESS = 'localhost'

var peer = ENetMultiplayerPeer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create client.
	peer.create_client(SERVER_ADDRESS, PORT)
	peer.peer_connected.connect(_on_connected_to_server)
	peer.peer_disconnected.connect(_on_server_disconnected)
	multiplayer.multiplayer_peer = peer


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_connected_to_server(id:int) -> void:
	print("Connected to server, yay!")
	pass

func _on_server_disconnected(id:int) -> void:
	print("Server disconnected")
	pass
