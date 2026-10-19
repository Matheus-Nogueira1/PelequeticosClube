extends Control

@onready var nome_label: Label = %NomeLabel
@onready var texto_label: RichTextLabel = %TextoLabel
@onready var dica_label: Label = %DicaLabel

@onready var dialogue_box: Control = %DialogueBox
@onready var painel_fala: Control = %Panel
@onready var light_button: Button = %LightButton
@onready var darkness_button: Button = %DarknessButton
@onready var darkness_button_2: Button = %DarknessButton2

@export var iniciar_intro_automaticamente: bool = true
@export var fechar_para_selecao: bool = true
signal dialogo_encerrado

var npc_responsavel: Node = null
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
var rolando_teste: bool = false

func _ready() -> void:
	print("CaixaDialogo pronta")

	if nome_label == null or texto_label == null or dica_label == null:
		push_error("Um ou mais nodes da caixa de diálogo não foram encontrados.")
		return

	texto_label.scroll_active = false
	texto_label.fit_content = true
	
	combatente = GrupoAtual.obter_personagem_principal()
	
	if combatente == null:
		push_warning("Nenhum personagem principal foi definido em GrupoAtual.")


	_configurar_interface_opcoes()

	# Se o diálogo foi configurado por outro script, usa essa configuração.
	if dialogo_configurado:
		iniciar_dialogo(dialogo_configurado_id)
	elif iniciar_intro_automaticamente:
		await get_tree().process_frame
		iniciar_dialogo("intro")
	else:
		visible = false



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

	rotulo_opcoes = %Label

	var botoes: Array[Button] = [
		light_button,
		darkness_button,
		darkness_button_2
	]

	for i in range(botoes.size()):
		var botao: Button = botoes[i]
		botoes_opcoes.append(botao)
		botao.hide()
		botao.focus_mode = Control.FOCUS_NONE
		botao.pressed.connect(_on_botao_opcao_pressionado.bind(i))
		botao.mouse_entered.connect(_on_botao_opcao_hover.bind(i))
	
	rotulo_opcoes.hide()
	dialogue_box.hide()
	# Limpa os textos de exemplo que vêm da cena.
	nome_label.text = ""
	texto_label.text = ""

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
	rolando_teste = false
	_travar_jogador(true)
	visible = true
	dica_label.show()
	# O painel padrão permanece visível; apenas as opções ficam ocultas.
	_esconder_opcoes()

	_mostrar_fala_atual()

func iniciar_dialogo_npc(
	personagem: CombatenteData,
	id_dialogo: String,
	npc: Node
) -> void:
	if ativo:
		return

	combatente = personagem
	npc_responsavel = npc
	fechar_para_selecao = false
	iniciar_intro_automaticamente = false

	iniciar_dialogo(id_dialogo)

func _unhandled_input(event: InputEvent) -> void:
	if not ativo:
		return
	if rolando_teste:
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
		dica_label.text = "E/Enter: avançar | Esc: fechar"


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
	rotulo_opcoes.text = texto_label.text
	rotulo_opcoes.show()
	painel_fala.hide()
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

	dica_label.text = "↑/↓: escolher | E/Enter: confirmar"


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
			dica_label.text = "↑/↓: escolher | E/Enter: testar " + conhecimento
	else:
		dica_label.text = "↑/↓: escolher | E/Enter: confirmar"


func _mover_selecao(direcao: int) -> void:
	if opcoes_atuais.is_empty():
		return

	indice_opcao_selecionada = (
		indice_opcao_selecionada + direcao + opcoes_atuais.size()
	) % opcoes_atuais.size()

	_atualizar_selecao_opcao()

func _on_botao_opcao_hover(indice: int) -> void:
	# Passar o mouse move a seleção (o ▶), igual às setas.
	if not opcoes_ativas or indice >= opcoes_atuais.size():
		return

	if botoes_opcoes[indice].disabled:
		return

	indice_opcao_selecionada = indice
	_atualizar_selecao_opcao()

func _on_botao_opcao_pressionado(indice: int) -> void:
	# Clique do mouse seleciona e confirma a opção.
	if not opcoes_ativas or indice >= opcoes_atuais.size():
		return

	indice_opcao_selecionada = indice
	_atualizar_selecao_opcao()
	_confirmar_opcao()

func _confirmar_opcao() -> void:
	if not opcoes_ativas or opcoes_atuais.is_empty():
		return

	var opcao: Dictionary = opcoes_atuais[indice_opcao_selecionada]
	var conhecimento: String = String(opcao.get("knowledge", ""))

	# Opções que exigem teste de conhecimento.
	if not conhecimento.is_empty():
		if combatente == null:
			dica_label.text = "Não há personagem ativo para realizar o teste."
			return

		if not combatente.tem_especializacao(conhecimento):
			dica_label.text = "Requer especialização em " + conhecimento + "."
			return

		var resultado_conhecimento: Dictionary = await _executar_teste_conhecimento(
			conhecimento
		)

		if resultado_conhecimento.is_empty():
			opcoes_ativas = true
			return

		var categoria_resultado: String = String(
	resultado_conhecimento.get("categoria", "")
)

# Falha crítica em Esforço: aplica 1 Estresse ao Torso.
		if conhecimento == "Esforço" and categoria_resultado == "Falha Crítica":
			var resultado_estresse: Dictionary = combatente.aplicar_estresse(
				"Torso",
				1
			)

			print(
				"Falha crítica em Esforço: +1 Estresse no Torso. Estado: ",
				combatente.estresse_por_regiao["Torso"]["atual"],
				"/",
				combatente.estresse_por_regiao["Torso"]["limite"]
			)

			if not resultado_estresse.is_empty():
				print("Consequência do Estresse: ", resultado_estresse)

				# Falha em opção com "failure_stress": aplica Estresse ao Torso.
		var estresse_falha: int = int(opcao.get("failure_stress", 0))

		if estresse_falha > 0 and categoria_resultado in ["Falha Regular", "Falha Crítica"]:
			combatente.aplicar_estresse("Torso", estresse_falha)

			print(
				"Falha em %s: +%d Estresse no Torso. Estado: %d/%d" % [
					conhecimento,
					estresse_falha,
					combatente.estresse_por_regiao["Torso"]["atual"],
					combatente.estresse_por_regiao["Torso"]["limite"]
				]
			)
		var id_dialogo_resultado: String = ""

		match categoria_resultado:
			"Falha Crítica":
				id_dialogo_resultado = String(
					opcao.get(
						"critical_failure_dialogue",
						opcao.get("failure_dialogue", "")
					)
				)

			"Falha Regular":
				id_dialogo_resultado = String(
					opcao.get("failure_dialogue", "")
				)

			"Sucesso Regular":
				id_dialogo_resultado = String(
					opcao.get("success_dialogue", "")
				)

			"Sucesso Extremo":
				id_dialogo_resultado = String(
					opcao.get(
						"extreme_success_dialogue",
						opcao.get("success_dialogue", "")
					)
				)

			_:
				push_warning(
					"Categoria de teste desconhecida: "
					+ categoria_resultado
				)
				rolando_teste = false
				opcoes_ativas = true
				return

		await get_tree().create_timer(1.0).timeout
		var dado_oculto := get_tree().get_first_node_in_group("dado_d6") as CanvasItem
		if dado_oculto != null:
			dado_oculto.visible = false
		if not ativo:
			return

		if not id_dialogo_resultado.is_empty():
			iniciar_dialogo(id_dialogo_resultado)
		else:
			fechar_dialogo()

		return

	# Opções que não exigem teste de conhecimento.
	if bool(opcao.get("close_dialogue", false)):
		fechar_dialogo()
		return

	var id_proximo_dialogo: String = String(
		opcao.get("next_dialogue", "")
	)

	if not id_proximo_dialogo.is_empty():
		iniciar_dialogo(id_proximo_dialogo)
	else:
		fechar_dialogo()

func _esconder_opcoes() -> void:
	opcoes_ativas = false
	if painel_fala != null:
		painel_fala.show()
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
	rolando_teste = false
	_travar_jogador(false)
	nome_label.text = ""
	texto_label.text = ""
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

	dialogo_encerrado.emit()

func _travar_jogador(travar: bool) -> void:
	# Trava ou libera o movimento de quem estiver no grupo "player".
	for jogador in get_tree().get_nodes_in_group("player"):
		if jogador.has_method("travar"):
			jogador.travar(travar)

func _executar_teste_conhecimento(conhecimento: String) -> Dictionary:
	if combatente == null:
		dica_label.text = "Não há personagem ativo para realizar o teste."
		return {}

	if not combatente.tem_especializacao(conhecimento):
		dica_label.text = "Requer especialização em " + conhecimento + "."
		return {}

	var resultado: Dictionary = RolagemD6.calcular_teste_conhecimento(
		combatente,
		conhecimento
	)

	if resultado.is_empty():
		dica_label.text = "Não foi possível realizar o teste."
		return {}

	# Fecha o painel de opções e volta para o painel da fala (com a dica visível).
	dialogue_box.hide()
	painel_fala.show()

	# Impede qualquer confirmação até o resultado ser mostrado.
	opcoes_ativas = false
	rolando_teste = true

	var dado_visual := get_tree().get_first_node_in_group("dado_d6") as RolagemD6

	if dado_visual != null:
		dado_visual.visible = true
		var camera := get_viewport().get_camera_2d()
		if camera != null:
			dado_visual.global_position = camera.get_screen_center_position() + Vector2(0, -20)

		dica_label.text = "ENTER ou E: rolar o dado"
		await dado_visual.aguardar_confirmacao()

		dica_label.text = "Rolando..."
		await dado_visual.rodar_e_mostrar_face(int(resultado["dado"]))
	else:
		push_warning("Nenhum nó do dado foi encontrado no grupo 'dado_d6'.")

	dica_label.text = (
		"D6: %d + bônus %d = %d — %s"
		% [
			int(resultado["dado"]),
			int(resultado["bonus_total"]),
			int(resultado["total"]),
			String(resultado["categoria"])
		]
	)

	print("Resultado do teste de conhecimento: ", resultado)

	return resultado

func mostrar_dica_interacao() -> void:
	if ativo:
		return

	visible = true
	dica_label.text = "E ou ENTER — Conversar"
	dica_label.show()


func ocultar_dica_interacao() -> void:
	if ativo:
		return

	dica_label.hide()
	visible = false
