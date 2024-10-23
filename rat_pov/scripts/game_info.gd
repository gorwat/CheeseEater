extends Control
signal game_started
signal game_stopped
signal force_quit
signal update_game_state

enum GameState {INIT, RUNNING, TIME_OUT, RAT_CAUGHT, FORCE_QUIT}

@export var current_game_state: GameState = GameState.INIT
@onready var game_timer: Timer = $Clock/Timer
@onready var cheese_manager: Node =  get_parent().get_node("CheeseManager")

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

# Options
@onready var options: Control = $Options
@onready var session_duration: Label = $Options/SessionDuration

var connected: bool = true #false
var high_score: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_to_main_menu()

func	 _process(delta: float) -> void:
	if (Input.is_action_just_pressed("stop_game")):
		current_game_state = GameState.FORCE_QUIT
		update_game_state.emit(current_game_state)
		stop_game()
		
	if (Input.is_action_just_pressed("increase_session_duration")):
		game_timer.wait_time += 10
		session_duration.text = str(game_timer.wait_time)
		
	if (Input.is_action_just_pressed("decrease_session_duration")):
		if (game_timer.wait_time > 10):
			game_timer.wait_time -= 10
			session_duration.text = str(game_timer.wait_time)
		
	if (Input.is_action_just_pressed("toggle_need_table")):
		if (options.find_child("NeedTable").text == "false"):
			options.find_child("NeedTable").text = "true"
			disable_start_buttons()
		else:
			options.find_child("NeedTable").text = "false"
			enable_start_buttons() 
		
	if (Input.is_action_just_pressed("toggle_options_visible")):
		options.visible = not options.visible
		game_menu.find_child("EscDummy").visible = not game_menu.find_child("EscDummy").visible

func reset_to_main_menu() -> void:
	# init visibility of screens
	game_menu.visible = true
	rat_caught_screen.visible = false
	timer_out_screen.visible = false
	
	#  init visibility of ingame UI
	timer_ui.visible = false
	cheese_counter.visible = false
	options.visible = false
	
	# set session duration to default value set in Timer
	game_timer.wait_time = timer_ui.default_time
	session_duration.text = str(game_timer.wait_time)
	
	
func start_game() -> void:
	game_timer.start()
	current_game_state = GameState.RUNNING 
	update_game_state.emit(current_game_state)
	
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
		update_and_show_scores(cheese_manager.cheeses_eaten)
	elif(current_game_state == GameState.RAT_CAUGHT):
		rat_caught_screen.visible = true
	elif(current_game_state == GameState.FORCE_QUIT):
		reset_to_main_menu()
		force_quit.emit()
	
	# hide ingame UI
	timer_ui.visible = false
	cheese_counter.visible = false
	
	game_timer.stop()
	game_stopped.emit()
	
func _on_timer_timeout() -> void:
	self.current_game_state = GameState.TIME_OUT
	update_game_state.emit(current_game_state)
	stop_game()

func update_and_show_scores(cheese_score: int) -> void:
	timer_out_screen.find_child("YourScore").text = str(cheese_score)
	if (cheese_score > high_score):
		high_score = cheese_score
		timer_out_screen.find_child("HighScore").text = str(cheese_score)
	timer_out_screen.visible = true
	
func _on_network_manager_connection_status_changed(status) -> void:
	match status:
		0: 
			connected = true # Connected
			enable_start_buttons()
		1: 
			connected = false # Disconnected
			disable_start_buttons()
			
		2: pass # Connecting
		_: pass

# allow player to start game even when table is not connected
func enable_start_buttons() -> void:
	game_start_button.disabled = false
	game_restart_caught_button.disabled = false
	game_restart_timer_out_button.disabled = false
	
func disable_start_buttons() -> void:
	game_start_button.disabled = true
	game_restart_caught_button.disabled = true
	game_restart_timer_out_button.disabled = true

func _on_restart_button_pressed() -> void:
	current_game_state = GameState.RUNNING
	update_game_state.emit(current_game_state)
	start_game()
	
func _on_start_button_pressed() -> void:
	current_game_state = GameState.RUNNING
	update_game_state.emit(current_game_state)
	start_game()

func _on_cheese_manager_update_cheeses_eaten(cheeses: int) -> void:
	cheese_counter.text = "%s" % cheeses

func _on_network_manager_rat_was_caught() -> void:
	current_game_state = GameState.RAT_CAUGHT
	update_game_state.emit(current_game_state)
	stop_game()
