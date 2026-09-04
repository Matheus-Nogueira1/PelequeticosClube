extends Control

@onready var nome_label: Label = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/NomeLabel")
@onready var texto_label: RichTextLabel = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/TextoLabel")
@onready var dica_label: Label = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/DicaLabel")

var falas: Array = []
var indice_atual: int = 0
var escrevendo: bool = false
var ativo: bool = false
var velocidade: float = 0.05
var pular_escrita: bool = false

func _ready() -> void:
	print("CaixaDialogo pronta")

	if nome_label == null or texto_label == null or dica_label == null:
		push_error("Um ou mais nodes da caixa não foram encontrados.")
		return

	visible = true
	texto_label.scroll_active = false
	texto_label.fit_content = true
	dica_label.text = "Enter: avançar | Esc: fechar o jogo"

	await get_tree().process_frame
	iniciar_dialogo("intro")

func iniciar_dialogo(id_dialogo: String) -> void:
	print("Abrindo diálogo:", id_dialogo)

	if not has_node("/root/Dialogos"):
		push_error("Autoload 'Dialogos' não encontrado.")
		return

	var dialogos = get_node("/root/Dialogos")
	falas = dialogos.get_conversa(id_dialogo)

	if falas.is_empty():
		print("Diálogo vazio.")
		fechar_dialogo()
		return

	indice_atual = 0
	ativo = true
	visible = true
	_mostrar_fala_atual()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
		return

	if not ativo:
		return

	if event.is_action_pressed("ui_accept"):
		if escrevendo:
			pular_escrita = true
		else:
			_avancar_dialogo()

func _mostrar_fala_atual() -> void:
	if indice_atual < 0 or indice_atual >= falas.size():
		fechar_dialogo()
		return

	var fala: Dictionary = falas[indice_atual]
	nome_label.text = String(fala.get("speaker", ""))
	await _escrever_texto(String(fala.get("text", "")))

func _escrever_texto(texto: String) -> void:
	escrevendo = true
	pular_escrita = false
	texto_label.text = ""

	for i in range(texto.length()):
		if pular_escrita:
			texto_label.text = texto
			break

		texto_label.text = texto.substr(0, i + 1)

		var caractere: String = texto.substr(i, 1)
		var pausa: float = velocidade

		if caractere == "." or caractere == "!" or caractere == "?":
			pausa += 0.20
		elif caractere == "," or caractere == ":" or caractere == ";":
			pausa += 0.10

		await get_tree().create_timer(pausa).timeout

	escrevendo = false
	pular_escrita = false

func _avancar_dialogo() -> void:
	indice_atual += 1

	if indice_atual >= falas.size():
		fechar_dialogo()
		return

	_mostrar_fala_atual()

func fechar_dialogo() -> void:
	ativo = false
	escrevendo = false
	pular_escrita = false
	visible = false
	falas.clear()
	indice_atual = 0
	get_tree().change_scene_to_file("res://scenes/player.tscn")
