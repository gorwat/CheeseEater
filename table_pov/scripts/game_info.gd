extends Control
signal game_started
signal game_stopped

enum GameState {INIT, RUNNING, TIME_OUT, RAT_CAUGHT}

@export var current_game_state: GameState = GameState.INIT

@onready var game_timer: Timer = $Clock/Timer
@onready var game_menu: Control = $StartMenu
@onready var game_start_button: Button = $StartMenu/StartButton
@onready var game_over_menu: Control = $GameOverMenu
@onready var game_restart_button: Button = $GameOverMenu/RestartButton

var connected: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_over_menu.visible = false
	pass # Replace with function body.

func	 _process(delta: float) -> void:
	if (Input.get_action_strength("stop_game") > 0.0) && current_game_state == GameState.RUNNING:
		stop_game()

func start_game() -> void:
	game_timer.start()
	self.current_game_state = GameState.RUNNING
	game_started.emit()

func stop_game() -> void:
	game_over_menu.visible = true
	game_timer.stop()
	game_stopped.emit()
	
func _on_timer_timeout() -> void:
	self.current_game_state = GameState.TIME_OUT
	stop_game()

func _on_network_manager_connection_status_schanged(status) -> void:
	match status:
		0: 
			connected = true # Connected
			game_start_button.disabled = false
			game_restart_button.disabled = false
		1: 
			connected = false # Disconnected
			game_start_button.disabled = true
			game_restart_button.disabled = true
			
		2: pass # Connecting
		_: pass


func _on_restart_button_pressed() -> void:
	game_over_menu.visible = false
	start_game()
	
func _on_start_button_pressed() -> void:
	game_menu.visible = false
	start_game()


func _on_claw_rat_caught() -> void:
	self.current_game_state = GameState.RAT_CAUGHT
	stop_game()
	pass # Replace with function body.
