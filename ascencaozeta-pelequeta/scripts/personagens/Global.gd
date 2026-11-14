extends Node

var selected_character = "Escolhido"

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		_alternar_tela_cheia()


func _alternar_tela_cheia() -> void:
	var modo_atual = DisplayServer.window_get_mode()

	if modo_atual == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
