extends Node

const PORT = 3353 #CH3353
const MAX_CLIENTS = 1

signal spot_position_changed

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
	if Input.is_key_pressed(KEY_P):
		print("Attempt to send rat position")
		set_rat_position.rpc()

func _on_client_disconnected(id: int):
	print("Disconnected :%(")

func _on_client_connected(id: int):
	print("Connected!")
	
func _on_player_rat_moved(position : Vector3, rotation : Vector3):
	print("Attempt to send rat position")
	set_rat_position.rpc(position, rotation)

@rpc
func set_rat_position(position : Vector3, rotation : Vector3):
	print("Rat position sent")
	
@rpc("any_peer")
func set_spot_position(position : Vector3):
	print("Spot position recieved")
	spot_position_changed.emit(position)
