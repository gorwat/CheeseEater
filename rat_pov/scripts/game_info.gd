extends Control
signal game_started
signal game_stopped
signal force_quit
signal update_game_state
signal recenter_speed_changed(new_speed: float)
signal rotation_speed_changed(new_speed: float)

enum GameState {INIT, RUNNING, TIME_OUT, RAT_CAUGHT, FORCE_QUIT}
@export var state : GameState

@export var current_game_state: GameState = GameState.INIT
@onready var game_timer: Timer = $Clock/Timer
@onready var cheese_manager: Node = get_parent().get_node("CheeseManager")
@onready var player: Node = get_node("../Player")

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


@export var player_speed: float = 10.0
@onready var player_speed_input: LineEdit = $Options/PlayerSpeedInput


@export var recenter_speed: float = 3.0
@export var rotation_speed_deg: float = 180.0
@onready var recenter_speed_input: LineEdit = $Options/RecenterSpeedInput
@onready var rotation_speed_input: LineEdit = $Options/RotationSpeedInput

@onready var wii_checkbox: CheckBox = $Options/WiiCheckBox

var connected: bool = true
var high_score: int = 0

func _ready() -> void:
	reset_to_main_menu()
	
	# Set initial player speed in input field and connect the input
	if player_speed_input:
		player_speed_input.text = str(player_speed)
		player_speed_input.text_submitted.connect(_on_player_speed_changed)
	
	# Set initial recenter speed and rotation speed in input fields and connect inputs
	if recenter_speed_input:
		recenter_speed_input.text = str(recenter_speed)
		recenter_speed_input.text_submitted.connect(_on_recenter_speed_changed)
	
	if rotation_speed_input:
		rotation_speed_input.text = str(rotation_speed_deg)
		rotation_speed_input.text_submitted.connect(_on_rotation_speed_changed)

	# Connect the WiiCheckBox toggled signal
	if wii_checkbox:
		wii_checkbox.toggled.connect(_on_wii_checkbox_toggled)
		# Optionally set initial state
		if recenter_speed == 1.5:
			wii_checkbox.set_pressed(true)
		else:
			wii_checkbox.set_pressed(false)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("stop_game"):
		current_game_state = GameState.FORCE_QUIT
		update_game_state.emit(current_game_state)
		stop_game()
		
	if Input.is_action_just_pressed("increase_session_duration"):
		game_timer.wait_time += 10
		session_duration.text = str(game_timer.wait_time)
		
	if Input.is_action_just_pressed("decrease_session_duration"):
		if game_timer.wait_time > 10:
			game_timer.wait_time -= 10
			session_duration.text = str(game_timer.wait_time)
		
	if Input.is_action_just_pressed("toggle_need_table"):
		if options.find_child("NeedTable").text == "false":
			options.find_child("NeedTable").text = "true"
			disable_start_buttons()
		else:
			options.find_child("NeedTable").text = "false"
			enable_start_buttons()
	
	if Input.is_action_just_pressed("toggle_camera_recenter"):
		if options.find_child("Recenter").text == "false":
			options.find_child("Recenter").text = "true"
			%CameraRig.recenter_enable = true
		else:
			options.find_child("Recenter").text = "false"
			%CameraRig.recenter_enable = false
		
	if Input.is_action_just_pressed("toggle_options_visible"):
		options.visible = not options.visible
		game_menu.find_child("EscDummy").visible = not game_menu.find_child("EscDummy").visible

func reset_to_main_menu() -> void:
	# init visibility of screens
	game_menu.visible = true
	rat_caught_screen.visible = false
	timer_out_screen.visible = false
	
	# init visibility of ingame UI
	timer_ui.visible = false
	cheese_counter.visible = false
	options.visible = false
	
	# set session duration to default value set in Timer
	game_timer.wait_time = timer_ui.default_time
	session_duration.text = str(game_timer.wait_time)

func start_game() -> void:
	game_timer.start()
	set_game_state(GameState.RUNNING)
	
	# hide screens
	game_menu.visible = false
	rat_caught_screen.visible = false
	timer_out_screen.visible = false
	
	# show ingame UI
	timer_ui.visible = true
	cheese_counter.visible = true
	
	game_started.emit(game_timer.wait_time)

func stop_game() -> void:
	if current_game_state == GameState.TIME_OUT:
		update_and_show_scores(cheese_manager.cheeses_eaten)
	elif current_game_state == GameState.RAT_CAUGHT:
		rat_caught_screen.visible = true
	elif current_game_state == GameState.FORCE_QUIT:
		reset_to_main_menu()
		force_quit.emit()
	
	# hide ingame UI
	timer_ui.visible = false
	cheese_counter.visible = false
	
	game_timer.stop()
	game_stopped.emit()
	
func set_game_state(state: GameState) -> void:
	self.current_game_state = state
	update_game_state.emit(self.current_game_state)
	
func _on_timer_timeout() -> void:
	set_game_state(GameState.TIME_OUT)
	stop_game()

func update_and_show_scores(cheese_score: int) -> void:
	timer_out_screen.find_child("YourScore").text = str(cheese_score)
	if cheese_score > high_score:
		high_score = cheese_score
		timer_out_screen.find_child("HighScore").text = str(cheese_score)
	timer_out_screen.visible = true
	
func _on_network_manager_connection_status_changed(status) -> void:
	match status:
		0: 
			connected = true
			enable_start_buttons()
		1: 
			connected = false
			disable_start_buttons()
			
		2: pass
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
	set_game_state(GameState.RUNNING)
	start_game()
	
func _on_start_button_pressed() -> void:
	set_game_state(GameState.RUNNING)
	start_game()

func _on_cheese_manager_update_cheeses_eaten(cheeses: int) -> void:
	cheese_counter.text = "%s" % cheeses

func _on_network_manager_rat_was_caught() -> void:
	set_game_state(GameState.RAT_CAUGHT)
	stop_game()

func _on_player_speed_changed(value: String) -> void:
	var new_speed = value.to_float()
	player_speed = new_speed
	player.speed = player_speed  # Update the speed variable in player.gd

func _on_recenter_speed_changed(value: String) -> void:
	var new_speed = value.to_float()
	recenter_speed = new_speed
	recenter_speed_changed.emit(new_speed)

func _on_rotation_speed_changed(value: String) -> void:
	var new_speed = value.to_float()
	rotation_speed_deg = new_speed
	rotation_speed_changed.emit(new_speed)

func _on_wii_checkbox_toggled(pressed: bool) -> void:
	if pressed:
		recenter_speed = 1.5
		recenter_speed_input.text = "1.5"
	else:
		recenter_speed = 3.0
		recenter_speed_input.text = "3.0"
	recenter_speed_changed.emit(recenter_speed)
