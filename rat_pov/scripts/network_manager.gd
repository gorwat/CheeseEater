extends Node

const PORT = 3353 #CH3353
const MAX_CLIENTS = 1

signal spot_positions_changed
signal rat_was_caught
signal timer_out
signal connection_status_changed

var peer = ENetMultiplayerPeer.new()
enum Status{CONNECTED, DISCONNECTED, CONNECTING}
var connection_status = Status.DISCONNECTED

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
		set_rat_position.rpc()
	# Control relay to table
	self.relay_table_controls.rpc(Vector3.ZERO, Input.is_action_just_pressed("table_cage_drop"));
		

func _on_client_disconnected(id: int):
	connection_status = Status.DISCONNECTED
	connection_status_changed.emit(connection_status)
	print("Disconnected :%(")

func _on_client_connected(id: int):
	connection_status = Status.CONNECTED
	connection_status_changed.emit(connection_status)
	print("Connected!")
	
func _on_player_rat_moved(position : Vector3, rotation : Vector3):
	set_rat_position.rpc(position, rotation)
	
func _on_cheese_manager_specific_cheese_eaten(cheese_name) -> void:
	sync_cheese_eaten.rpc(cheese_name)
	
func _on_cheese_manager_specific_cheese_spawned(cheese_name, position, rotation) -> void:
	sync_cheese_spawn.rpc(cheese_name, position, rotation)

func _on_game_info_game_started(session_duration : int) -> void:
	start_game.rpc(session_duration)
	
func _on_game_info_force_quit() -> void:
	force_quit.rpc()


# rpcs called from rat
@rpc
func set_rat_position(position : Vector3, rotation : Vector3):
	pass
	
@rpc
func start_game(session_duration: int):
	pass
	
@rpc
func force_quit():
	pass

@rpc("any_peer")
func sync_cheese_spawn(cheese_name:String, position:Vector3, rotation:Vector3):
	pass
	
@rpc("any_peer")
func sync_cheese_eaten(cheese_name:String):
	pass

# rpcs called from table
@rpc("any_peer")
func set_spot_positions(positions: PackedVector3Array, angles: PackedFloat32Array):
	spot_positions_changed.emit(positions, angles)

@rpc("any_peer")
func update_cage(position:Vector3, rotation:Vector3, enable: bool):
	print("we update the cage now")
	%Cage.position = position
	%Cage.rotation = rotation
	if enable:
		%Cage.set_process(true)
		%Cage.show()
	else:
		%Cage.position.y = -100
		%Cage.set_process(false)
		%Cage.hide()
		

@rpc("any_peer")
func rat_caught():
	rat_was_caught.emit()
	
@rpc("any_peer")
func relay_table_controls(direction: Vector3, cage_drop: bool):
	pass
