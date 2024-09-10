extends Node


const PORT = 3353 #CH3353
const MAX_CLIENTS = 1

var peer = ENetMultiplayerPeer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create server.
	peer.create_server(PORT, MAX_CLIENTS)
	peer.peer_connected.connect(_on_client_connected)
	peer.peer_disconnected.connect(_on_client_disconnected)
	multiplayer.multiplayer_peer = peer
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_client_disconnected(id: int):
	print("Disconnected :%(")

func _on_client_connected(id: int):
	print("Connected!")
