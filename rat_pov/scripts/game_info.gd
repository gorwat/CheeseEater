extends Control
signal game_started
signal game_stopped
signal force_quit

enum GameState {INIT, RUNNING, TIME_OUT, RAT_CAUGHT, FORCE_QUIT}

@export var current_game_state: GameState = GameState.INIT
@onready var game_timer: Timer = $Clock/Timer

# screens
@onready var game_menu: Control = $StartMenu
@onready var rat_caught_screen: Control = $RatCaughtScreen
@onready var timer_out_screen: Control = $TimerOutScreen

# UI elements
@onready var timer_ui: Label = $Clock
@onready var cheese_counter: Label = $CheeseCounter
@onready var game_start_button: Button = $StartMenu/StartButton
@onready var game_restart_caught_button: Button = $RatCaughtScreen/RestartButton
@onready var game_restart_timer_out_button: Button = $TimerOutScreen/RestartButton


var connected: bool = true #false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# init visibility of screens
	game_menu.visible = true
	rat_caught_screen.visible = false
	timer_out_screen.visible = false
	
	#  init visibility of ingame UI
	timer_ui.visible = false
	cheese_counter.visible = false
	

func	 _process(delta: float) -> void:
	if (Input.get_action_strength("stop_game") > 0.0) && current_game_state == GameState.RUNNING:
		current_game_state = GameState.FORCE_QUIT
		stop_game()

func start_game() -> void:
	game_timer.start()
	current_game_state = GameState.RUNNING 
	
	# hide screens
	game_menu.visible = false
	rat_caught_screen.visible = false
	timer_out_screen.visible = false
	
	# show ingame UI
	timer_ui.visible = true
	cheese_counter.visible = true
	
	game_started.emit(game_timer.wait_time)

func stop_game() -> void:
	if (current_game_state == GameState.TIME_OUT):
		timer_out_screen.visible = true
	elif(current_game_state == GameState.RAT_CAUGHT):
		rat_caught_screen.visible = true
	elif(current_game_state == GameState.FORCE_QUIT):
		game_menu.visible = true
		force_quit.emit()
	
	# hide ingame UI
	timer_ui.visible = false
	cheese_counter.visible = false
	
	game_timer.stop()
	game_stopped.emit()
	
func _on_timer_timeout() -> void:
	self.current_game_state = GameState.TIME_OUT
	stop_game()

func _on_network_manager_connection_status_changed(status) -> void:
	match status:
		0: 
			connected = true # Connected
			game_start_button.disabled = false
			game_restart_caught_button.disabled = false
			game_restart_timer_out_button.disabled = false
		1: 
			connected = false # Disconnected
			game_start_button.disabled = true
			game_restart_caught_button.disabled = true
			game_restart_timer_out_button.disabled = true
			
		2: pass # Connecting
		_: pass

func _on_restart_button_pressed() -> void:
	current_game_state = GameState.RUNNING
	start_game()
	
func _on_start_button_pressed() -> void:
	current_game_state = GameState.RUNNING
	start_game()

func _on_cheese_manager_update_cheeses_eaten(cheeses: int) -> void:
	cheese_counter.text = "%s" % cheeses

func _on_network_manager_rat_was_caught() -> void:
	current_game_state = GameState.RAT_CAUGHT
	stop_game()
