
extends Control

@onready var fade_overlay: ColorRect = $Fade
@onready var transicao_verde: ColorRect = $TransicaoVerde

var transicao_em_andamento := false
var botoes_menu: Array[Button] = []


func _ready() -> void:
	# Mantém o background original intacto.
	$bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Cria os botões nas posições reais da imagem 320x192.
	criar_botao("PLAY", Rect2(36, 41, 53, 17), _on_start_btn_pressed)
	criar_botao("OPTIONS", Rect2(36, 73, 53, 17), _on_options_btn_pressed)
	criar_botao("CREDITS", Rect2(36, 105, 53, 17), _on_credits_btn_pressed)
	criar_botao("EXIT", Rect2(36, 137, 53, 17), _on_quit_btn_pressed)

	# Mantém a transição inicial verde.
	transicao_verde.color = Color("132828")
	transicao_verde.modulate.a = 1.0
	transicao_verde.visible = true
	transicao_verde.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fade_overlay.visible = false
	fade_overlay.modulate.a = 0.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tween_verde := create_tween()
	tween_verde.set_trans(Tween.TRANS_SINE)
	tween_verde.set_ease(Tween.EASE_IN_OUT)
	tween_verde.tween_property(
		transicao_verde, "modulate:a", 0.0, 1.0
	)
	await tween_verde.finished

	transicao_verde.visible = false


func criar_botao(nome: String, area: Rect2, acao: Callable) -> void:
	var botao := Button.new()
	botao.name = nome
	botao.text = ""
	botao.tooltip_text = ""
	botao.focus_mode = Control.FOCUS_NONE

	# Coordenadas em pixels da imagem original.
	botao.set_anchors_preset(Control.PRESET_TOP_LEFT)
	botao.position = area.position
	botao.size = area.size
	botao.z_index = 5

	# Normal: totalmente transparente.
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.TRANSPARENT
	normal.set_border_width_all(0)
	botao.add_theme_stylebox_override("normal", normal)

	# Hover: apenas um brilho vermelho discreto.
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.65, 0.05, 0.10, 0.22)
	hover.set_border_width_all(1)
	hover.border_color = Color(0.8, 0.15, 0.2, 0.45)
	hover.set_corner_radius_all(2)
	botao.add_theme_stylebox_override("hover", hover)

	# Clique: um pouco mais escuro, sem aumentar o botão.
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.35, 0.02, 0.05, 0.35)
	pressed.set_border_width_all(1)
	pressed.border_color = Color(0.8, 0.15, 0.2, 0.55)
	pressed.set_corner_radius_all(2)
	botao.add_theme_stylebox_override("pressed", pressed)

	add_child(botao)
	botao.pressed.connect(acao)
	botoes_menu.append(botao)


func _on_start_btn_pressed() -> void:
	if transicao_em_andamento:
		return

	transicao_em_andamento = true

	for botao in botoes_menu:
		botao.disabled = true

	# Fade para preto antes de trocar de cena.
	fade_overlay.visible = true
	fade_overlay.z_index = 10
	fade_overlay.color = Color.BLACK
	fade_overlay.modulate.a = 0.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		fade_overlay, "modulate:a", 1.0, 1.2
	)
	await tween.finished

	get_tree().change_scene_to_file(
		"res://scenes/menu/caixa-dialogo.tscn"
	)


func _on_options_btn_pressed() -> void:
	pass # Conecte à tela de opções quando ela existir.


func _on_credits_btn_pressed() -> void:
	pass # Conecte à tela de créditos quando ela existir.


func _on_quit_btn_pressed() -> void:
	get_tree().quit()
