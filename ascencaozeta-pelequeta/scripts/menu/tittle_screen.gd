extends Control

@onready var titulo: Control = $MarginContainer/CenterContainer/VBoxContainer/Label
@onready var botoes: Control = $MarginContainer/CenterContainer/VBoxContainer/HBoxContainer
@onready var fade_overlay: ColorRect = $Fade
@onready var transicao_verde: ColorRect = $TransicaoVerde

var transicao_em_andamento := false


func _ready() -> void:
	# Mantém o verde cobrindo o menu no início.
	transicao_verde.color = Color("132828")
	transicao_verde.modulate.a = 1.0
	transicao_verde.visible = true

	# Revela gradualmente o menu azul.
	var fade_verde := create_tween()
	fade_verde.set_trans(Tween.TRANS_SINE)
	fade_verde.set_ease(Tween.EASE_IN_OUT)
	fade_verde.tween_property(
		transicao_verde,
		"modulate:a",
		0.0,
		1.0
	)
	await fade_verde.finished

	transicao_verde.visible = false

	# Revela o céu azul.
	var fade_cena := create_tween()
	fade_cena.tween_property(fade_overlay, "modulate:a", 0.0, 1.0)
	await fade_cena.finished

	# Entrada da logo.
	var fade_titulo := create_tween()
	fade_titulo.set_trans(Tween.TRANS_CUBIC)
	fade_titulo.set_ease(Tween.EASE_OUT)
	fade_titulo.set_parallel(true)
	fade_titulo.tween_property(titulo, "modulate:a", 1.0, 0.7)
	await fade_titulo.finished

	# Entrada dos botões.
	var fade_botoes := create_tween()
	fade_botoes.set_trans(Tween.TRANS_CUBIC)
	fade_botoes.set_ease(Tween.EASE_OUT)
	fade_botoes.set_parallel(true)
	fade_botoes.tween_property(botoes, "modulate:a", 1.0, 0.6)



func _on_start_btn_pressed() -> void:
	if transicao_em_andamento:
		return

	transicao_em_andamento = true
	await _transicionar_para_cutscene()


func _transicionar_para_cutscene() -> void:
	# Cobre todo o menu com preto.
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_overlay.modulate.a = 0.0
	fade_overlay.visible = true

	var fade_preto := create_tween()
	fade_preto.set_trans(Tween.TRANS_SINE)
	fade_preto.set_ease(Tween.EASE_IN_OUT)
	fade_preto.tween_property(
		fade_overlay,
		"modulate:a",
		1.0,
		1.2
	)
	await fade_preto.finished

	# Só troca a cena depois que a tela estiver preta.
	get_tree().change_scene_to_file(
		"res://scenes/menu/caixa-dialogo.tscn"
	)


func _on_credits_btn_pressed() -> void:
	pass


func _on_quit_btn_pressed() -> void:
	get_tree().quit()
