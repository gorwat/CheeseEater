extends Control
signal init_connection

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	var text = $'AspectRatioContainer/VBoxContainer/HBoxContainer/Address Input'.get_text()
	if text != "":
		emit_signal("init_connection", text)
		


func _on_line_edit_text_submitted(new_text: String) -> void:
	emit_signal("init_connection", new_text)


func _on_network_manager_connection_status_schanged(status) -> void:
	match status:
		0: self.visible = false # Connected
		1: self.visible = true # Disconnected
		2: pass # Connecting
		_: pass
	
