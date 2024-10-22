extends Control
signal game_started
signal game_stopped

enum GameState {INIT, RUNNING, TIME_OUT, RAT_CAUGHT, FORCE_QUIT}

@export var current_game_state: GameState = GameState.INIT

@onready var game_timer: Timer = $Clock/Timer

# screens
@onready var game_menu: Control = $StartMenu
@onready var time_out_menu: Control = $GameOverMenu
@onready var caught_rat_menu: Control = $CaughtRatMenu

# UI elements
@onready var timer_ui: Label = $Clock

var connected: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_menu.visible = true
	time_out_menu.visible = false
	caught_rat_menu.visible = false
	timer_ui.visible = false

func	 _process(delta: float) -> void:
	if (Input.get_action_strength("stop_game") > 0.0) && current_game_state == GameState.RUNNING:
		stop_game()

func start_game() -> void:
	game_timer.start()
	self.current_game_state = GameState.RUNNING
	
	# hide screens
	game_menu.visible = false
	time_out_menu. visible = false
	caught_rat_menu. visible = false
	
	# show ingame UI
	timer_ui.visible = true
	
	game_started.emit()

func stop_game() -> void:
	if (current_game_state == GameState.TIME_OUT):
		time_out_menu.visible = true
	elif (current_game_state == GameState.RAT_CAUGHT):
		caught_rat_menu.visible = true
	elif (current_game_state == GameState.FORCE_QUIT):
		game_menu.visible = true
	
	game_timer.stop()
	timer_ui.visible = false
	
func _on_timer_timeout() -> void:
	self.current_game_state = GameState.TIME_OUT
	stop_game()

func _on_network_manager_connection_status_schanged(status) -> void:
	match status:
		0: 
			connected = true # Connected
		1: 
			connected = false # Disconnected
			
		2: pass # Connecting
		_: pass

func _on_network_manager_game_started(session_duration: int) -> void:
	game_timer.wait_time = session_duration
	start_game()

func _on_network_manager_rat_force_quit() -> void:
	self.current_game_state = GameState.FORCE_QUIT
	stop_game()

func _on_claw_rat_caught() -> void:
	if (current_game_state == GameState.RUNNING):
		self.current_game_state = GameState.RAT_CAUGHT
		stop_game()
