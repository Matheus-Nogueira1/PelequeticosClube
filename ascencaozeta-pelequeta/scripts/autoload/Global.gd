extends Node

var selected_character = "Escolhido"
# Estado da demonstração (só em memória; o projeto não tem salvamento).
var retorno_combate: String = ""      # "", "vitoria" ou "fuga" (a derrota reinicia o combate)
var dummy_derrotado: bool = false
var demo_encerrada: bool = false


func reiniciar_demo() -> void:
	retorno_combate = ""
	dummy_derrotado = false
	demo_encerrada = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		_alternar_tela_cheia()


func _alternar_tela_cheia() -> void:
	var modo_atual = DisplayServer.window_get_mode()

	if modo_atual == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
