extends Control

@onready var nome_label: Label = get_node_or_null(
	"PanelContainer/MarginContainer/Panel/VBoxContainer/NomeLabel"
)
@onready var texto_label: RichTextLabel = get_node_or_null(
	"PanelContainer/MarginContainer/Panel/VBoxContainer/TextoLabel"
)
@onready var dica_label: Label = get_node_or_null(
	"PanelContainer/MarginContainer/Panel/VBoxContainer/DicaLabel"
)
@onready var dialogue_box: Control = get_node_or_null("DialogueBox")

@export var iniciar_intro_automaticamente: bool = true
@export var fechar_para_selecao: bool = true

var combatente: CombatenteData = null
var falas: Array = []
var indice_atual: int = 0
var escrevendo: bool = false
var ativo: bool = false
var velocidade: float = 0.05
var pular_escrita: bool = false

var dialogo_configurado: bool = false
var dialogo_configurado_id: String = ""

var opcoes_atuais: Array = []
var botoes_opcoes: Array[Button] = []
var rotulo_opcoes: Label = null
var indice_opcao_selecionada: int = 0
var opcoes_ativas: bool = false


func _ready() -> void:
	print("CaixaDialogo pronta")

	if nome_label == null or texto_label == null or dica_label == null:
		push_error("Um ou mais nodes da caixa de diálogo não foram encontrados.")
		return

	visible = false
	texto_label.scroll_active = false
	texto_label.fit_content = true

	_configurar_interface_opcoes()

	if dialogo_configurado:
		iniciar_dialogo(dialogo_configurado_id)
	elif iniciar_intro_automaticamente:
		await get_tree().process_frame
		iniciar_dialogo("intro")


func configurar_dialogo(
	personagem: CombatenteData,
	id_dialogo: String,
	retornar_para_selecao: bool = false
) -> void:
	combatente = personagem
	dialogo_configurado_id = id_dialogo
	dialogo_configurado = true
	fechar_para_selecao = retornar_para_selecao
	iniciar_intro_automaticamente = false

	if is_inside_tree() and is_node_ready():
		iniciar_dialogo(dialogo_configurado_id)


func _configurar_interface_opcoes() -> void:
	botoes_opcoes.clear()
	rotulo_opcoes = null

	if dialogue_box == null:
		push_warning("DialogueBox não foi encontrado. Opções de diálogo indisponíveis.")
		return

	var encontrados: Array[Node] = dialogue_box.find_children("*", "Button", true, false)

	for node in encontrados:
		var botao := node as Button
		if botao != null:
			botoes_opcoes.append(botao)
			botao.visible = false
			botao.focus_mode = Control.FOCUS_ALL

	var rotulos: Array[Node] = dialogue_box.find_children("*", "Label", true, false)

	if not rotulos.is_empty():
		rotulo_opcoes = rotulos[0] as Label

	dialogue_box.visible = false


func iniciar_dialogo(id_dialogo: String) -> void:
	print("Abrindo diálogo:", id_dialogo)

	if not has_node("/root/Dialogos"):
		push_error("Autoload 'Dialogos' não encontrado.")
		return

	var dialogos = get_node("/root/Dialogos")
	falas = dialogos.get_conversa(id_dialogo)

	if falas.is_empty():
		push_warning("Diálogo vazio ou inexistente: " + id_dialogo)
		fechar_dialogo()
		return

	indice_atual = 0
	ativo = true
	visible = true
	_esconder_opcoes()
	_mostrar_fala_atual()


func _unhandled_input(event: InputEvent) -> void:
	if not ativo:
		return

	if opcoes_ativas:
		if event.is_action_pressed("ui_up"):
			_mover_selecao(-1)
			var viewport_atual := get_viewport()

			if viewport_atual != null:
				viewport_atual.set_input_as_handled()
			return

		if event.is_action_pressed("ui_down"):
			_mover_selecao(1)
			var viewport_atual := get_viewport()

			if viewport_atual != null:
				viewport_atual.set_input_as_handled()
			return

		if event.is_action_pressed("ui_accept"):
			if escrevendo:
				pular_escrita = true
			else:
				_confirmar_opcao()

			var viewport_atual := get_viewport()

			if viewport_atual != null:
				viewport_atual.set_input_as_handled()
			return

		if event.is_action_pressed("ui_cancel"):
			var viewport_atual := get_viewport()

			if viewport_atual != null:
				viewport_atual.set_input_as_handled()
			return

	if event.is_action_pressed("ui_accept"):
		if escrevendo:
			pular_escrita = true
		else:
			_avancar_dialogo()

		var viewport_atual := get_viewport()

		if viewport_atual != null:
			viewport_atual.set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		fechar_dialogo()
		var viewport_atual := get_viewport()

		if viewport_atual != null:
			viewport_atual.set_input_as_handled()


func _mostrar_fala_atual() -> void:
	if indice_atual < 0 or indice_atual >= falas.size():
		fechar_dialogo()
		return

	var fala: Dictionary = falas[indice_atual]

	nome_label.text = String(fala.get("speaker", ""))
	_esconder_opcoes()

	await _escrever_texto(String(fala.get("text", "")))

	if not ativo:
		return

	var opcoes: Array = fala.get("options", [])

	if not opcoes.is_empty():
		_exibir_opcoes(opcoes)
	else:
		dica_label.text = "Enter: avançar | Esc: fechar"


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


func _exibir_opcoes(opcoes: Array) -> void:
	_esconder_opcoes()

	if botoes_opcoes.is_empty():
		push_error("Não existem botões configurados dentro de DialogueBox.")
		dica_label.text = "Enter: avançar"
		return

	opcoes_atuais = opcoes.slice(0, mini(opcoes.size(), botoes_opcoes.size()))
	indice_opcao_selecionada = 0
	opcoes_ativas = true

	dialogue_box.visible = true

	for i in range(botoes_opcoes.size()):
		var botao: Button = botoes_opcoes[i]

		if i >= opcoes_atuais.size():
			botao.visible = false
			continue

		var opcao: Dictionary = opcoes_atuais[i]
		var conhecimento: String = String(opcao.get("knowledge", ""))
		var requer_especializacao: bool = not conhecimento.is_empty()
		var disponivel: bool = true

		if requer_especializacao:
			disponivel = (
				combatente != null
				and combatente.tem_especializacao(conhecimento)
			)

		botao.visible = true
		botao.disabled = not disponivel
		botao.text = String(opcao.get("text", "Continuar"))

		if not disponivel:
			botao.tooltip_text = "Requer especialização em " + conhecimento + "."
		else:
			botao.tooltip_text = ""

	_atualizar_selecao_opcao()

	dica_label.text = "↑/↓: escolher | Enter: confirmar"


func _atualizar_selecao_opcao() -> void:
	if not opcoes_ativas:
		return

	for i in range(opcoes_atuais.size()):
		var botao: Button = botoes_opcoes[i]
		var opcao: Dictionary = opcoes_atuais[i]
		var texto: String = String(opcao.get("text", "Continuar"))

		if i == indice_opcao_selecionada:
			botao.text = "▶ " + texto
		else:
			botao.text = texto

	var selecionada: Dictionary = opcoes_atuais[indice_opcao_selecionada]
	var conhecimento: String = String(selecionada.get("knowledge", ""))

	if not conhecimento.is_empty():
		var disponivel := (
			combatente != null
			and combatente.tem_especializacao(conhecimento)
		)

		if not disponivel:
			dica_label.text = "Requer especialização em " + conhecimento + "."
		else:
			dica_label.text = "↑/↓: escolher | Enter: testar " + conhecimento
	else:
		dica_label.text = "↑/↓: escolher | Enter: confirmar"


func _mover_selecao(direcao: int) -> void:
	if opcoes_atuais.is_empty():
		return

	indice_opcao_selecionada = (
		indice_opcao_selecionada + direcao + opcoes_atuais.size()
	) % opcoes_atuais.size()

	_atualizar_selecao_opcao()


func _confirmar_opcao() -> void:
	if not opcoes_ativas or opcoes_atuais.is_empty():
		return

	var opcao: Dictionary = opcoes_atuais[indice_opcao_selecionada]
	var conhecimento: String = String(opcao.get("knowledge", ""))

	if not conhecimento.is_empty():
		if combatente == null:
			dica_label.text = "Não há personagem ativo para realizar o teste."
			return

		if not combatente.tem_especializacao(conhecimento):
			dica_label.text = "Requer especialização em " + conhecimento + "."
			return

		var resultado: Dictionary = RolagemD6.calcular_teste_conhecimento(
			combatente,
			conhecimento
		)

		if resultado.is_empty():
			return

		print("Resultado do teste de conhecimento: ", resultado)

		var destino: String

		if resultado["sucesso"]:
			destino = String(opcao.get("success_dialogue", ""))
		else:
			destino = String(opcao.get("failure_dialogue", ""))

		if not destino.is_empty():
			iniciar_dialogo(destino)
		else:
			fechar_dialogo()

		return

	if bool(opcao.get("close_dialogue", false)):
		fechar_dialogo()
		return

	var proximo: String = String(opcao.get("next_dialogue", ""))

	if not proximo.is_empty():
		iniciar_dialogo(proximo)
	else:
		fechar_dialogo()


func _esconder_opcoes() -> void:
	opcoes_ativas = false
	opcoes_atuais.clear()

	if dialogue_box != null:
		dialogue_box.visible = false

	for botao in botoes_opcoes:
		botao.visible = false


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
	_esconder_opcoes()

	if fechar_para_selecao:
		get_tree().change_scene_to_file(
			"res://scenes/menu/EscolherPersonagem.tscn"
		)
