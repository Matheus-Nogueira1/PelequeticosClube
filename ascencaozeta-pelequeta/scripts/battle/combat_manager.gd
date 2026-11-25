extends Node
class_name CombatManager

# Importações
const RolagemDadosD6 = preload("res://scripts/battle/rolagens-dados-d6.gd")
const CENA_MAPA: String = "res://scenes/mapas/cabana-elizabeth.tscn"
const CENA_DADO_D6: PackedScene = preload(
    "res://scenes/testes/rolagem-dado.tscn"
)
const CENA_RESULTADO: PackedScene = preload(
	"res://scenes/battle/resultado_combate.tscn"
)
var dados_visuais: Array[RolagemD6] = []
var dados_em_animacao: bool = false
# Tipos de ações conforme OBLIVIO
enum ActionType {
	ACAO_REGULAR,    # Ação simples (atacar, perícia básica)
	MOVIMENTO,       # Deslocar-se no campo
	EXTRA,           # Ação adicional se houver pontos
	COMPLETA         # Ação que consome tudo
}

# Sinais para comunicação entre painéis
signal turno_iniciado(combatente: CombatenteData)
signal turno_finalizado(combatente: CombatenteData)
signal combate_iniciado
signal combate_finalizado(vencedor: String)
signal estado_atualizado
signal turno_passado
signal leitura_confirmada

# Painéis da cena
@onready var camada_resultado: CanvasLayer = %CamadaResultado
@onready var party_panel = %PartyPanel
@onready var enemy_panel = %EnemyPanel
@onready var battlefield = %Battlefield
@onready var regional_selector = %RegionalPanel
@onready var action_panel = %ActionPanel
@onready var log_panel: CombatLog = %ComunicacaoLog
@onready var comunicacao_panel: Control = %ComunicacaoPanel
@onready var indicador_sobrecarga: Control = get_node_or_null("%IndicadorSobrecarga") as Control
@onready var player_visual: Node = %Battlefield.find_child(
	"PlayerVisual", true, false
)
@onready var enemy_visual: Node = %Battlefield.find_child(
	"EnemyVisual", true, false
)
@onready var campo_batalha: Control = %BattleFieldContent
@onready var dica_continuar: Label = get_node_or_null("%DicaContinuar") as Label
@onready var ficha_inimigo: FichaInimigo = %FichaInimigo
@onready var dice_container: Control = %DiceContainer
@export var ajuda_automatica: bool = true
@onready var caixa_ajuda: CaixaAjuda = get_node_or_null("%CaixaAjuda") as CaixaAjuda
var animacao_jogador: CombatenteAnimation
var animacao_inimigo: CombatenteAnimation
var turno_inimigo_em_execucao: bool = false
var conhecimentos_ia_usados_turno: Array[String] = []

# Estado do combate
var combatentes_jogador: Array[CombatenteData] = []
var combatentes_inimigo: Array[CombatenteData] = []
var ordem_turno: Array[CombatenteData] = []
var indice_turno_atual := -1
var combatente_ativo: CombatenteData = null
var combate_ativo: bool = false
var conhecimento_pendente := ""
var fardos_iniciais: int = 0
var resumo_resultado: Array[String] = []
var estatisticas: EstatisticasCombate = EstatisticasCombate.new()
var resultado_pontuacao: Dictionary = {}
var _frame_confirmacao: int = -1
var painel_inimigos_ativo: bool = false  # Tab: painel que recebe Q e Espaço
# Ordem de iniciativa no início do combate. Nunca é modificada:
# serve só para dar a cada combatente uma posição fixa (contagem de rodadas).
var ordem_inicial: Array[CombatenteData] = []
# Estado da ação atual
var acao_em_progresso: bool = false
var regioes_selecionadas: Array[String] = []
var alvo_selecionado: Dictionary = {}
var aguardando_leitura: bool = false
var inimigos_derrotados: Array[String] = []

func _ready() -> void:
	_conectar_sinais_paineis()
	_conectar_botoes_ajuda()
	_conectar_alternancia_paineis()
	_conectar_cliques_campo()
	_inicializar_animacoes()
	_inicializar_combate()

# ============================================================================
# INICIALIZAÇÃO
# ============================================================================

func _inicializar_combate() -> void:
	"""Prepara o combate inicial: iniciativa, ordem de turno, etc"""
	print("[CombatManager] Inicializando combate...")

	# TODO: Carregar dados dos personagens e inimigos
	# Por enquanto, vou usar estrutura de exemplo
	# Estatísticas novas a cada combate (nada vaza entre combates).
	estatisticas = EstatisticasCombate.new()
	resultado_pontuacao = {}
	inimigos_derrotados.clear()
	_setup_exemplo()

	if combatentes_jogador.is_empty() or combatentes_inimigo.is_empty():
		push_error("[CombatManager] Combate cancelado: participantes não foram inicializados.")
		return

	# Preencher UI dos painéis
	if enemy_panel:
		var inimigos_dict: Array[Dictionary] = []
		for combatente in combatentes_inimigo:
			inimigos_dict.append(combatente.para_dictionary())
		enemy_panel.atualizar_todos(inimigos_dict)
	if party_panel:
		var jogadores_dict: Array[Dictionary] = []
		for combatente in combatentes_jogador:
			jogadores_dict.append(combatente.para_dictionary())
		party_panel.atualizar_todos(jogadores_dict)
	_atualizar_marcadores_painel()
	if regional_selector:
		regional_selector.desativar()

	# Calcular iniciativa
	_calcular_iniciativa()

	# Ordenar by iniciativa
	ordem_turno.sort_custom(func(a, b): return a.iniciativa > b.iniciativa)
	ordem_inicial.assign(ordem_turno)

	combate_ativo = true
	log_panel.registrar_evento(
	"Combate iniciado: %s contra %s." % [
		combatentes_jogador[0].nome,
		combatentes_inimigo[0].nome
	],
	"turno",
)
	_anunciar_ordem_iniciativa()
	combate_iniciado.emit()

	# Começar primeiro turno
	# O primeiro turno só começa depois da apresentação inicial.
	await _apresentar_pendentes()
	# O primeiro turno só começa depois da ajuda inicial (se houver).
	await _mostrar_ajuda_inicial()
	_avancar_turno()


func _setup_exemplo() -> void:
	"""Prepara o encontro inicial: personagem selecionado contra Dummy."""

	combatentes_jogador.clear()
	combatentes_inimigo.clear()
	ordem_turno.clear()

	# Recuperar o personagem principal selecionado pelo jogador.
	var escolhido: CombatenteData = GrupoAtual.obter_personagem_principal()

	if escolhido == null:
		push_error(
			"[CombatManager] Nenhum personagem principal foi definido em GrupoAtual."
		)
		return
		# Se desmaiou fora do combate (ex.: Estresse em diálogo), acorda com 1 a menos.
	if escolhido.desmaiado:
		escolhido.reviver()
	combatentes_jogador.append(escolhido)
	fardos_iniciais = escolhido.fardos.size()

	# Criar o Dummy reutilizando temporariamente os dados da Carcaça.
	var dummy: CombatenteData = InimigoData.criar_carcaca()
	dummy.nome = "Dummy"

	combatentes_inimigo.append(dummy)

	# Unificar os participantes para calcular a iniciativa.
	ordem_turno = combatentes_jogador + combatentes_inimigo

	print("[CombatManager] Encontro preparado:")
	print("  Jogador: ", escolhido.nome)
	print("  Inimigo: ", dummy.nome)
	print("  Total de combatentes: ", ordem_turno.size())

func _calcular_iniciativa() -> void:
	"""Cada combatente compara sua velociadade com os outros"""
	for combatente in ordem_turno:
		combatente.iniciativa = combatente.atributo_velocidade

func _conectar_sinais_paineis() -> void:
	"""Conecta os sinais dos painéis ao CombatManager"""
	if action_panel:
		action_panel.acao_atacar.connect(_iniciar_ataque)
		action_panel.acao_habilidade.connect(_iniciar_habilidade)
		action_panel.acao_item.connect(_iniciar_item)
		action_panel.conhecimento_escolhida.connect(_on_conhecimento_escolhida)
		action_panel.habilidade_escolhida.connect(_on_habilidade_escolhida)
		action_panel.turno_passado.connect(_on_turno_passado)
		action_panel.habilidade_sobrecarga.connect(_ativar_sobrecarga)
		action_panel.item_escolhido.connect(_on_item_escolhido)

	if regional_selector:
		regional_selector.regiao_selecionada.connect(_on_regiao_selecionada)
		regional_selector.selecao_confirmada.connect(_on_regioes_confirmadas)
		regional_selector.selecao_cancelada.connect(_on_selecao_cancelada)

	if enemy_panel:
		enemy_panel.inimigo_selecionado.connect(_on_inimigo_selecionado)
		enemy_panel.selecao_alvo_cancelada.connect(_on_alvo_cancelado)
		enemy_panel.modo_alvo_alterado.connect(_atualizar_marcadores_painel)
		enemy_panel.ficha_solicitada.connect(_alternar_ficha)


func _buscar_sprite_animado(
	raiz: Node,
	nome_no: String
) -> AnimatedSprite2D:
	if raiz == null:
		return null

	var encontrado: Node = raiz.find_child(nome_no, true, false)

	if encontrado is AnimatedSprite2D:
		return encontrado as AnimatedSprite2D

	push_warning(
		"[CombatManager] AnimatedSprite2D '%s' não encontrado." % nome_no
	)
	return null


func _inicializar_animacoes() -> void:
	var sprite_jogador := _buscar_sprite_animado(
		player_visual, "AnimationEscolhido"
	)
	var sprite_inimigo := _buscar_sprite_animado(
		enemy_visual, "AnimationDummy"
	)

	if sprite_jogador != null:
		animacao_jogador = CombatenteAnimation.new()
		animacao_jogador.name = "AnimacaoJogador"
		add_child(animacao_jogador)
		animacao_jogador.configurar(sprite_jogador)

	if sprite_inimigo != null:
		animacao_inimigo = CombatenteAnimation.new()
		animacao_inimigo.name = "AnimacaoInimigo"
		add_child(animacao_inimigo)
		animacao_inimigo.configurar(sprite_inimigo)


# ============================================================================
# FLUXO DE TURNO
# ============================================================================

func _avancar_turno() -> void:
	"""Move para o próximo combatente com P.A. disponível"""
	if not combate_ativo:
		return
	# Fim do turno anterior: consolida a variedade dele (uma única vez).
	if combatente_ativo != null:
		estatisticas.finalizar_turno(combatente_ativo)
	acao_em_progresso = false
	regioes_selecionadas.clear()
	# Não limpar alvo_selecionado aqui - será limpo apenas quando mudar de turno de verdade

	# Procurar próximo combatente vivo
	var combatente_proximo = _encontrar_proximo_combatente()

	if not combatente_proximo:
		print("[CombatManager] Nenhum combatente disponível - possível empate")
		return
	
	combatente_ativo = combatente_proximo
	combatente_ativo.restaurar_pontos_acao()
	# Início do turno: o cursor da iniciativa avançou (conta rodada)
	# e o registro de variedade do aliado é aberto.
	estatisticas.registrar_avanco_iniciativa(ordem_inicial.find(combatente_ativo))
	estatisticas.iniciar_turno(combatente_ativo)
	_atualizar_indicador_sobrecarga()
	_restaurar_protecoes(combatente_ativo)
	turno_iniciado.emit(combatente_ativo)
	
	# Ativar painel de ações se for personagem jogador
	if combatente_ativo.tipo == "jogador":
		party_panel.atualizar_personagem(
			combatente_ativo.para_dictionary()
		)
		party_panel.indicar_personagem_ativo(
			combatente_ativo.para_dictionary()
		)
		party_panel.indicar_personagem_ativo(combatente_ativo.para_dictionary())
		enemy_panel.desativar_seletor_alvo()
		enemy_panel.remover_destaque_turno()
		# Limpar seleções apenas ao iniciar turno do jogador
		alvo_selecionado.clear()
		log_panel.registrar_evento(
			"🎯 Turno de %s!" % combatente_ativo.nome,
			"turno"
		)
		# O jogador lê o aviso antes de receber o controle.
		await _apresentar_pendentes()
		if not combate_ativo:
			return
		action_panel.ativar_para(combatente_ativo.para_dictionary(), combatente_ativo)
	else:
		party_panel.remover_destaque_turno()
		enemy_panel.indicar_inimigo_ativo(combatente_ativo.para_dictionary())
		action_panel.desabilitar_acoes()
		log_panel.registrar_evento(
			"Turno de %s." % combatente_ativo.nome,
			"turno"
		)
		await _apresentar_pendentes()
		await get_tree().create_timer(0.3).timeout
		if not combate_ativo:
			return
		await _executar_turno_inimigo()

func _restaurar_protecoes(combatente: CombatenteData) -> void:
	for alvo in combatentes_jogador:
		if alvo.atacante_que_quebrou_protecao == combatente.nome:
			alvo.reducao_protecao_temporaria = 0
			alvo.atacante_que_quebrou_protecao = ""
			party_panel.atualizar_personagem(
				alvo.para_dictionary()
			)
			log_panel.registrar_evento(
				"A proteção de %s foi restaurada." %
				alvo.nome,
				"info",
				false
			)
	for alvo in combatentes_inimigo:
		if alvo.atacante_que_quebrou_protecao == combatente.nome:
			alvo.reducao_protecao_temporaria = 0
			alvo.atacante_que_quebrou_protecao = ""
			enemy_panel.atualizar_inimigo(
				alvo.para_dictionary()
			)
			log_panel.registrar_evento(
				"A proteção de %s foi restaurada." %
				alvo.nome,
				"info",
				false
			)

func _encontrar_proximo_combatente() -> CombatenteData:
	"""Encontra o próximo combatente vivo na ordem"""
	var tentativas = 0
	var max_tentativas = ordem_turno.size() * 2
	if ordem_turno.is_empty():
		return null
	while tentativas < max_tentativas:
		indice_turno_atual = (indice_turno_atual + 1) % ordem_turno.size()
		var combatente = ordem_turno[indice_turno_atual]

		# Verificar se está vivo (não morto e não desmaiado permanentemente)
		if not combatente.morto and combatente.esta_consciente():
			return combatente

		tentativas += 1

	return null

func _executar_turno_inimigo() -> void:
	"""Executa ações da IA até acabar o PA ou o inimigo não poder continuar."""

	if combatente_ativo == null:
		return

	var inimigo: CombatenteData = combatente_ativo

	if inimigo.tipo != "inimigo":
		return

	turno_inimigo_em_execucao = true
	conhecimentos_ia_usados_turno.clear()

	print("[CombatManager] Turno da IA: %s" % inimigo.nome)

	while (
		combate_ativo
		and combatente_ativo == inimigo
		and not inimigo.morto
		and inimigo.esta_consciente()
	):
		if inimigo.pontos_acao_atuais <= 0:
			break

		var decisao: Dictionary = InimigoIA.decidir(
			inimigo,
			combatentes_jogador,
			conhecimentos_ia_usados_turno
		)

		print(
			"[IA] %s: %s | %s | PA: %d" % [
				inimigo.nome,
				decisao.get("tipo", "passar"),
				decisao.get("motivo", ""),
				inimigo.pontos_acao_atuais
			]
		)

		var tipo_acao: String = String(
			decisao.get("tipo", "passar")
		)

		if tipo_acao == "passar":
			log_panel.registrar_evento(
				"%s passou o turno. (%s)" % [
					inimigo.nome,
					decisao.get("motivo", "")
				],
				"turno"
			)

			await _apresentar_pendentes()
			break

		var alvo: CombatenteData = decisao.get("alvo")

		if (
			alvo == null
			or alvo.morto
			or not alvo.esta_consciente()
			or not combatentes_jogador.has(alvo)
		):
			continue

		match tipo_acao:
			"atacar":
				var regioes: Array[String] = decisao.get(
					"regioes",
					[] as Array[String]
				)

				if regioes.is_empty():
					break

				if not inimigo.consumir_pontos_acao(
					InimigoIA.CUSTO_PA_ATAQUE
				):
					break

				enemy_panel.atualizar_inimigo(
					inimigo.para_dictionary()
				)
				log_panel.registrar_evento(
					"%s atacou %s." % [
						inimigo.nome,
						alvo.nome
					],
					"acao"
				)
				await _apresentar_pendentes()
				if not combate_ativo:
					break
				await _processar_ataque(
					inimigo,
					alvo,
					regioes
				)
			"conhecimento":
				var nome_conhecimento: String = String(
					decisao.get("conhecimento", "")
				)
				if nome_conhecimento not in ["Duelo", "Rastro"]:
					break
				if not inimigo.consumir_pontos_acao(
					InimigoIA.CUSTO_PA_CONHECIMENTO
				):
					break
				conhecimentos_ia_usados_turno.append(
					nome_conhecimento
				)
				enemy_panel.atualizar_inimigo(
					inimigo.para_dictionary()
				)
				log_panel.registrar_evento(
					"%s utilizou %s contra %s." % [
						inimigo.nome,
						nome_conhecimento,
						alvo.nome
					],
					"acao"
				)
				await _apresentar_pendentes()
				if not combate_ativo:
					break
				if nome_conhecimento == "Duelo":
					await _executar_conhecimento_duelo(alvo)
				else:
					await _executar_conhecimento_rastro(alvo)
			_:
				break
	turno_inimigo_em_execucao = false
	if not combate_ativo:
		return
	turno_finalizado.emit(inimigo)
	await _avancar_turno()

# ============================================================================
# AÇÕES DO COMBATENTE
# ============================================================================

func _iniciar_ataque() -> void:
	"""Inicia sequência de ataque: seleciona regiões → seleciona alvo → rola dados"""
	if acao_em_progresso or combatente_ativo == null:
		return
	if combatente_ativo.tipo != "jogador":
		return
	if combatente_ativo.pontos_acao_atuais < 2:
		log_panel.registrar_evento(
			"PA insuficiente: o ataque padrão custa 2 PA.",
			"aviso"
		)
		await _devolver_acoes_apos_leitura()
		return
	acao_em_progresso = true
	action_panel.desabilitar_acoes()
	log_panel.registrar_evento("Selecione as regiões de ataque...", "acao", false)
	regional_selector.ativar_para_ataque(combatente_ativo)
	regional_selector.modo = "selecionar_ataque"

func _iniciar_conhecimento() -> void:
	"""Inicia uso de perícia"""
	if acao_em_progresso or combatente_ativo.tipo != "jogador":
		return

	acao_em_progresso = true
	log_panel.registrar_evento("Menu de perícias aberto...", "acao", false)

	# TODO: Mostrar menu de perícias disponíveis
	action_panel.mostrar_menu_conhecimentos(combatente_ativo.para_dictionary())

func _iniciar_habilidade() -> void:
	"""Inicia uso de habilidade especial"""
	if acao_em_progresso or combatente_ativo.tipo != "jogador":
		return

	acao_em_progresso = true
	log_panel.registrar_evento("Menu de habilidades aberto...", "acao", false)

	# A seleção visual fica no ActionPanel para manter o mesmo fluxo das Perícias:
	# Menu Principal -> Lista -> Detalhes -> Confirmar Uso.
	# O CombatManager só volta a atuar quando a habilidade for confirmada.
	action_panel.mostrar_menu_habilidades(combatente_ativo.para_dictionary())

func _ativar_sobrecarga() -> void:
	if combatente_ativo == null or combatente_ativo.habilidade_sobrecarga_ativa:
		return

	combatente_ativo.habilidade_sobrecarga_ativa = true
	acao_em_progresso = false
	party_panel.atualizar_personagem(combatente_ativo.para_dictionary())
	_atualizar_indicador_sobrecarga()

	log_panel.registrar_evento(
		"⚡ %s entrou em SOBRECARGA!" % combatente_ativo.nome,
		"critico"
	)
	await _devolver_acoes_apos_leitura()


# Mostra o indicador visual (nó do editor) enquanto a Sobrecarga estiver ativa.
func _atualizar_indicador_sobrecarga() -> void:
	if indicador_sobrecarga != null:
		indicador_sobrecarga.visible = (
			combatente_ativo != null
			and combatente_ativo.habilidade_sobrecarga_ativa
		)

func _on_habilidade_escolhida(nome_habilidade: String) -> void:
	# Recebe apenas habilidades confirmadas na tela de detalhes do ActionPanel.
	# A validação de PA e conhecimento permanece aqui porque altera estado real
	# do combatente e deve ficar centralizada no fluxo de combate.
	if combatente_ativo == null:
		return

	var habilidade_data = HabilidadeData.new()
	var resultado = habilidade_data.usar_habilidade(
		combatente_ativo,
		nome_habilidade
	)

	if not resultado["sucesso"]:
		acao_em_progresso = false
		log_panel.registrar_evento(
			resultado["erro"],
			"aviso"
		)
		await _devolver_acoes_apos_leitura()
		return

	acao_em_progresso = false
	log_panel.registrar_evento(
		"%s usou %s (%d PA)." % [
			combatente_ativo.nome,
			resultado["habilidade"],
			resultado["custo_pa"]
		],
		"acao"
	)
	log_panel.registrar_evento(
		resultado["efeito"],
		"info"
	)

	# Atualiza o painel da party porque usar habilidade pode consumir PA agora e,
	# futuramente, também poderá aplicar cura, dano ou estados.
	party_panel.atualizar_personagem(
		combatente_ativo.para_dictionary()
	)
	await _devolver_acoes_apos_leitura()

func _iniciar_item() -> void:
	"""Inicia uso de item"""
	if acao_em_progresso or combatente_ativo.tipo != "jogador":
		return

	acao_em_progresso = true
	log_panel.registrar_evento("Menu de itens aberto...", "acao", false)

	# TODO: Mostrar inventário
	action_panel.mostrar_menu_itens(combatente_ativo.para_dictionary())

func _on_item_escolhido(nome_item: String) -> void:
	if combatente_ativo == null or combatente_ativo.tipo != "jogador":
		return

	var item: ItemData.Item = ItemData.obter_item(nome_item)
	if item == null or not ItemData.tem_item(combatente_ativo, nome_item):
		log_panel.registrar_evento("Item indisponível.", "aviso")
		await _devolver_acoes_apos_leitura()
		return
	if combatente_ativo.pontos_acao_atuais < 1:
		log_panel.registrar_evento(
			"PA insuficiente: usar um item custa 1 PA.",
			"aviso"
		)
		await _devolver_acoes_apos_leitura()
		return
	# Beta: o Frasco Estus age na região com mais estresse.
	var regiao_alvo := ""
	var maior_estresse := 0
	for regiao in combatente_ativo.estresse_por_regiao.keys():
		var atual: int = combatente_ativo.estresse_por_regiao[regiao]["atual"]
		if atual > maior_estresse:
			maior_estresse = atual
			regiao_alvo = regiao

	if regiao_alvo == "":
		log_panel.registrar_evento(
			"%s não tem estresse para recuperar." % combatente_ativo.nome,
			"aviso"
		)
		await _devolver_acoes_apos_leitura()
		return
	var estresse_antes_item: int = combatente_ativo.get_estresse_total()
	var resultado: Dictionary = ItemData.usar_item(combatente_ativo, item, regiao_alvo)
	if not resultado.get("sucesso", false):
		log_panel.registrar_evento(
			String(resultado.get("mensagem", "Falha ao usar o item.")),
			"aviso"
		)
		await _devolver_acoes_apos_leitura()
		return
	if not combatente_ativo.consumir_pontos_acao(1):
		return
	# Cura efetiva = Estresse realmente removido. No Frasco Estus, o item
	# só conta como ação se a cura efetiva for maior que zero.
	var cura_item: int = estresse_antes_item - combatente_ativo.get_estresse_total()
	estatisticas.registrar_cura(cura_item)
	if cura_item > 0:
		estatisticas.registrar_acao(combatente_ativo, EstatisticasCombate.CATEGORIA_ITEM)
	ItemData.remover_item(combatente_ativo, nome_item)
	log_panel.registrar_evento(String(resultado["mensagem"]), "sucesso")
	party_panel.atualizar_personagem(combatente_ativo.para_dictionary())
	_finalizar_acao()

func _executar_conhecimento_duelo(alvo: CombatenteData) -> void:
	if alvo == null:
		return

	var conhecimento = ConhecimentoData.new()

	var dado_visual: int = await _rolar_dado_conhecimento("Duelo")
	var resultado = conhecimento.executar_duelo(
		combatente_ativo,
		alvo,
		dado_visual
	)

	match resultado["resultado"]:

		"Falha Crítica":
			log_panel.registrar_evento(
				"%s interpretou errado os movimentos do inimigo." %
				combatente_ativo.nome,
				"critico"
			)

		"Falha":
			log_panel.registrar_evento(
				"%s não encontrou nenhuma abertura." %
				combatente_ativo.nome,
				"info"
			)

		"Sucesso":
			log_panel.registrar_evento(
				"%s analisou %s. Proteção atual: %d" % [
					combatente_ativo.nome,
					alvo.nome,
					alvo.obter_protecao_atual()
				],
				"info"
			)
			alvo.informacoes_reveladas = true
			_atualizar_painel_combatente(alvo)

		"Sucesso Extremo":
			alvo.reducao_protecao_temporaria += 1
			if alvo.obter_protecao_atual() <= 0:
				alvo.atacante_que_quebrou_protecao = combatente_ativo.nome
				log_panel.registrar_evento(
					"%s quebrou completamente a proteção de %s!" % [
						combatente_ativo.nome,
						alvo.nome
					],
					"critico"
				)
			log_panel.registrar_evento(
				"%s encontrou uma brecha em %s." % [
					combatente_ativo.nome,
					alvo.nome
				],
				"critico"
			)

			log_panel.registrar_evento(
				"Proteção reduzida para %d." %
				alvo.obter_protecao_atual(),
				"critico"
			)
			alvo.informacoes_reveladas = true
			_atualizar_painel_combatente(alvo)

	await _apresentar_pendentes()
	await _finalizar_acao()

func _executar_conhecimento_rastro(alvo: CombatenteData) -> void:
	"""Rastro: igual ao Duelo, mas só revela as informações do inimigo."""
	if alvo == null:
		return
	var conhecimento = ConhecimentoData.new()
	var dado_visual: int = await _rolar_dado_conhecimento("Rastro")
	var resultado: Dictionary = conhecimento.testar_conhecimento(
		combatente_ativo,
		"Rastro",
		0,
		dado_visual
	)

	log_panel.registrar_evento(
		"Rastro: D6 %d → %d (%s)" % [
			int(resultado.get("dado", 0)),
			int(resultado.get("resultado_final", 0)),
			String(resultado.get("resultado", "?"))
		],
		"info"
	)

	if bool(resultado.get("sucesso", false)):
		alvo.informacoes_reveladas = true
		log_panel.registrar_evento(
			"%s examinou %s. Proteção atual: %d" % [
				combatente_ativo.nome,
				alvo.nome,
				alvo.obter_protecao_atual()
			],
			"info"
		)
		_atualizar_painel_combatente(alvo)
	else:
		log_panel.registrar_evento(
			"%s não percebeu nada de útil em %s." % [
				combatente_ativo.nome,
				alvo.nome
			],
			"info"
		)

	await _apresentar_pendentes()
	await _finalizar_acao()

func _tentar_fugir() -> void:
	"""Bandidagem: em sucesso foge da batalha e volta ao mapa."""
	if acao_em_progresso:
		return
	if combatente_ativo.pontos_acao_atuais < 1:
		log_panel.registrar_evento(
			"PA insuficiente: usar um conhecimento custa 1 PA.",
			"aviso"
		)
		await _devolver_acoes_apos_leitura()
		return
	if not combatente_ativo.consumir_pontos_acao(1):
		return
	party_panel.atualizar_personagem(
		combatente_ativo.para_dictionary()
	)
	acao_em_progresso = true
	# Bloqueia o ActionPanel antes da rolagem (ele ficava ativo durante a animação).
	action_panel.desabilitar_acoes()

	var conhecimento = ConhecimentoData.new()

	# Rola visualmente o D6 e utiliza exatamente esse resultado no teste.
	var dado_visual: int = await _rolar_dado_conhecimento("Bandidagem")

	if dado_visual < 1 or dado_visual > 6:
		push_error("[CombatManager] Falha ao realizar a rolagem visual de Bandidagem.")
		acao_em_progresso = false
		await _devolver_acoes_apos_leitura()
		return

	var resultado: Dictionary = conhecimento.testar_conhecimento(
		combatente_ativo,
		"Bandidagem",
		0,
		dado_visual
	)

	log_panel.registrar_evento(
		"%s tenta fugir (Bandidagem): D6 %d → %d (%s)" % [
			combatente_ativo.nome,
			int(resultado.get("dado", 0)),
			int(resultado.get("resultado_final", 0)),
			String(resultado.get("resultado", "?"))
		],
		"acao"
	)

	if bool(resultado.get("sucesso", false)):
		log_panel.registrar_evento(
			"%s escapou da batalha!" % combatente_ativo.nome,
			"sucesso"
		)
		_finalizar_combate("Fuga")
		return

	log_panel.registrar_evento(
		"%s não encontrou uma saída." % combatente_ativo.nome,
		"aviso"
	)

	_finalizar_acao()

func _on_alvo_cancelado() -> void:
	"""Esc durante a escolha do alvo: volta ao menu de ações"""
	conhecimento_pendente = ""
	acao_em_progresso = false
	regioes_selecionadas.clear()
	log_panel.registrar_evento("Seleção de alvo cancelada.", "aviso", false)
	action_panel.habilitar_acoes()

func _on_conhecimento_escolhida(nome_conhecimento: String) -> void:

	if combatente_ativo == null:
		return

	match nome_conhecimento:

		"Duelo", "Rastro":
			conhecimento_pendente = nome_conhecimento

			log_panel.registrar_evento(
				"Selecione o alvo de %s. (Esc cancela)" % nome_conhecimento,
				"acao",
				false
			)

			# Esconde o menu de ações: a escolha agora é só o alvo.
			action_panel.desabilitar_acoes()
			enemy_panel.ativar_seletor_alvo()

		"Bandidagem":
			_tentar_fugir()

		_:
			log_panel.registrar_evento(
				"Conhecimento %s ainda não implementado." % nome_conhecimento,
				"info",
				false
			)

# ============================================================================
# CALLBACKS DE SELEÇÃO
# ============================================================================

func _on_regiao_selecionada(nome_regiao: String, indice: int) -> void:

	if combatente_ativo.habilidade_sobrecarga_ativa:
		regioes_selecionadas.append(nome_regiao)

		log_panel.registrar_evento(
			"⚡ Sobrecarga: %s arriscada novamente!" % nome_regiao,
			"critico",
			false
		)

	else:
		if nome_regiao not in regioes_selecionadas:
			regioes_selecionadas.append(nome_regiao)
		else:
			regioes_selecionadas.erase(nome_regiao)

func _on_regioes_confirmadas(regioes: Array[String]) -> void:
	"""Chamado quando o jogador confirma as regiões selecionadas"""
	regioes_selecionadas = regioes.duplicate()
	log_panel.registrar_evento("Regiões confirmadas: %s" % ", ".join(regioes_selecionadas), "acao", false)
	log_panel.registrar_evento("Selecione o inimigo alvo...", "acao", false)
	regional_selector.desativar()
	enemy_panel.ativar_seletor_alvo()

func _on_selecao_cancelada() -> void:
	"""Chamado quando o jogador cancela a seleção de regiões"""
	acao_em_progresso = false
	regioes_selecionadas.clear()
	alvo_selecionado.clear()
	log_panel.registrar_evento("Seleção de regiões cancelada.", "aviso", false)
	regional_selector.desativar()
	action_panel.habilitar_acoes()

func _on_turno_passado() -> void:
	"""Chamado quando o jogador clica em PASSAR TURNO"""
	if combatente_ativo and combatente_ativo.tipo == "jogador":
		log_panel.registrar_evento(
			"%s passou o turno." % combatente_ativo.nome,
			"turno"
		)
		action_panel.desabilitar_acoes()
		turno_finalizado.emit(combatente_ativo)
		await _apresentar_pendentes()
		if not combate_ativo:
			return
		_avancar_turno()

func _on_inimigo_selecionado(inimigo_dict: Dictionary) -> void:

	if not inimigo_dict.has("nome"):
		log_panel.registrar_evento(
			"Inimigo inválido selecionado!",
			"aviso",
			false
		)
		return

	# =====================================================
	# PERÍCIAS QUE PRECISAM DE ALVO
	# =====================================================

	if conhecimento_pendente == "Duelo" or conhecimento_pendente == "Rastro":

		var alvo: CombatenteData = null

		for inimigo in combatentes_inimigo:
			if inimigo.nome == inimigo_dict["nome"]:
				alvo = inimigo
				break

		if alvo == null:
			return

		var conhecimento_usado := conhecimento_pendente
		conhecimento_pendente = ""

		if combatente_ativo.pontos_acao_atuais < 1:
			log_panel.registrar_evento(
				"PA insuficiente: usar um conhecimento custa 1 PA.",
				"aviso"
			)
			acao_em_progresso = false
			enemy_panel.desativar_seletor_alvo()
			await _devolver_acoes_apos_leitura()
			return

		if not combatente_ativo.consumir_pontos_acao(1):
			return

		party_panel.atualizar_personagem(
			combatente_ativo.para_dictionary()
		)

		if conhecimento_usado == "Rastro":
			_executar_conhecimento_rastro(alvo)
		else:
			_executar_conhecimento_duelo(alvo)

		return

	# =====================================================
	# ATAQUE NORMAL
	# =====================================================

	if regioes_selecionadas.is_empty():
		log_panel.registrar_evento(
			"Nenhuma região selecionada! Confirme antes de selecionar alvo.",
			"aviso",
			false
		)
		return

	var alvo: CombatenteData = null

	for inimigo in combatentes_inimigo:
		if inimigo.nome == inimigo_dict["nome"]:
			alvo = inimigo
			break

	if alvo == null:
		log_panel.registrar_evento(
			"Alvo não encontrado.",
			"aviso",
			false
		)
		return
	if combatente_ativo.pontos_acao_atuais < 2:
		log_panel.registrar_evento(
			"PA insuficiente: o ataque padrão custa 2 PA.",
			"aviso"
		)
		regioes_selecionadas.clear()
		acao_em_progresso = false
		enemy_panel.desativar_seletor_alvo()
		await _devolver_acoes_apos_leitura()
		return

	if not combatente_ativo.consumir_pontos_acao(2):
		return

	party_panel.atualizar_personagem(
		combatente_ativo.para_dictionary()
	)
	log_panel.registrar_evento(
		"%s atacou %s." % [combatente_ativo.nome, alvo.nome],
		"acao"
	)
	await _apresentar_pendentes()
	_processar_ataque(
		combatente_ativo,
		alvo,
		regioes_selecionadas
	)
# ============================================================================
# PROCESSAMENTO DE ATAQUE
# ============================================================================
func _limpar_dados_visuais() -> void:
	for dado in dados_visuais:
		if is_instance_valid(dado):
			dado.queue_free()

	dados_visuais.clear()


func _rolar_dados_visuais(regioes: Array[String], valores_fixos: Array[int] = []) -> Array[int]:
	if dados_em_animacao:
		return []

	dados_em_animacao = true
	_limpar_dados_visuais()

	var resultados: Array[int] = []

	if valores_fixos.is_empty():
		# Sorteia uma única vez. Os mesmos valores serão usados no combate.
		for i in range(clampi(regioes.size(), 1, 5)):
			resultados.append(randi_range(1, 6))
	else:
		# Valores já sorteados (ex.: dano da arma): só anima, sem novo sorteio.
		for i in range(mini(valores_fixos.size(), 5)):
			resultados.append(valores_fixos[i])

	var quantidade: int = resultados.size()

	var espacamento: float = 20.0
	var largura_total: float = (quantidade - 1) * espacamento
	var inicio_x: float = -largura_total / 2.0

	for i in range(quantidade):
		var instancia := CENA_DADO_D6.instantiate()
		var dado := instancia as RolagemD6

		if dado == null:
			push_error(
                "[CombatManager] A cena do dado não possui o script RolagemD6."
			)
			instancia.queue_free()
			_limpar_dados_visuais()
			dados_em_animacao = false
			return []

		dice_container.add_child(dado)
		dado.position = Vector2(
			dice_container.size.x / 2.0 + inicio_x + i * espacamento,
			dice_container.size.y / 2.0
		)
		dado.scale = Vector2(1, 1)
		dados_visuais.append(dado)

	# Anima todos os dados; cada face corresponde ao resultado sorteado.
	for i in range(dados_visuais.size()):
		await dados_visuais[i].rodar_e_mostrar_face(resultados[i])
	# Pausa para o jogador ver a face final antes de _finalizar_acao()
	# liberar os dados.
	await get_tree().create_timer(0.8).timeout
	dados_em_animacao = false
	return resultados

func _obter_regiao_atingida(resultado_d6: int) -> String:
	match resultado_d6:
		1, 2:
			return "Torso"
		3:
			return "Braço Direito"
		4:
			return "Braço Esquerdo"
		5:
			return "Perna Direita"
		6:
			return "Perna Esquerda"
		_:
			return ""

func _rolar_dado_conhecimento(nome: String) -> int:
	"""Anima 1 dado e devolve o valor bruto (0 se a rolagem falhar)."""
	var rotulo: Array[String] = [nome]
	var valores: Array[int] = await _rolar_dados_visuais(rotulo)
	if valores.is_empty():
		return 0
	return valores[0]

# Anima os dados de dano da arma com os valores JÁ sorteados.
# O sprite só tem faces 1 a 6: armas de outras faces (ex.: d10) não animam.
func _rolar_dados_dano_visuais(nome_arma: String, valores: Array[int]) -> void:
	var arma = ArmaData.obter_arma(nome_arma)
	if arma == null or arma.dano_faces != 6 or valores.is_empty():
		return
	var sem_rotulos: Array[String] = []
	await _rolar_dados_visuais(sem_rotulos, valores)

# ============================================================
# PROCESSAMENTO DO ATAQUE
# Sequência: (1) rola e anima os dados, um por região arriscada
# -> (2) calcula o resultado D6 -> (3) aplica Estresse de falhas
# no atacante -> (4) anima o ataque -> (5) compara sucessos com a
# Proteção ATUAL do alvo: quebrou = dano no Torso + animação de
# dano; não teve acerto = esquiva. Os campos de dano de
# rolar_teste_combate_d6 NÃO são usados (Proteção fixa em 2).
# ============================================================
func _processar_ataque(
	atacante: CombatenteData,
	alvo: CombatenteData,
	regioes: Array[String]
) -> void:
	# Exibe os dados e guarda os resultados reais da rolagem.
	var resultados_dados: Array[int] = await _rolar_dados_visuais(regioes)

	if resultados_dados.is_empty():
		push_error("[CombatManager] Não foi possível concluir a rolagem dos dados.")
		_limpar_dados_visuais()
		await _finalizar_acao()
		return

	# A lógica utiliza exatamente os resultados mostrados na animação.
	var rolagem = RolagemDadosD6.new()
	var resultado_combate: Dictionary = rolagem.rolar_teste_combate_d6(
		regioes,
		2,
		2,
		atacante.atributo_dano,
		resultados_dados
	)
	
	# O nó não está na árvore e só serviu para calcular o resultado.
	rolagem.free()
	# ============================================================
	# LOG DAS REGIÕES
	# ============================================================
	var linhas_falha: Array[String] = []
	for res_regiao in resultado_combate["resultados_por_regiao"]:
		log_panel.registrar_evento(
			"Região: %s → D6: %d (%s)" % [
				res_regiao["regiao"],
				res_regiao["dado"],
				res_regiao["categoria"]
			],
			"ataque",
		)
		if res_regiao["categoria"] in ["Falha Regular", "Falha Crítica"]:
			var estresse_gerado := 1
			if res_regiao["categoria"] == "Falha Crítica":
				estresse_gerado = 2
			var resultado_estresse = _aplicar_estresse_registrado(
				atacante,
				res_regiao["regiao"],
				estresse_gerado,
				true
			)
			linhas_falha.append("%s sofreu %d de estresse em %s." % [
				atacante.nome,
				estresse_gerado,
				res_regiao["regiao"]
			])
			log_panel.registrar_evento(
				"%s sofre %d de estresse em %s (ataque falhou)" % [
					atacante.nome,
					estresse_gerado,
					res_regiao["regiao"]
				],
				"aviso",
				false
			)
			if resultado_estresse.has("regiao_esgotada"):
				linhas_falha.append("%s: %s" % [atacante.nome, resultado_estresse["mensagem"]])
			elif resultado_estresse.has("mensagem"):
				linhas_falha.append(String(resultado_estresse["mensagem"]))
			if resultado_estresse.has("resultado_fardo"):
				linhas_falha.append(String(resultado_estresse["resultado_fardo"]["mensagem"]))
	# Consequências das falhas do atacante, numa única mensagem.
	if not linhas_falha.is_empty():
		log_panel.registrar_evento("\n".join(linhas_falha), "aviso")
	await _apresentar_pendentes()
	# ============================================================
	# APÓS TODAS AS FALHAS
	# VERIFICA SE O ATACANTE AINDA CONSEGUE CONTINUAR
	# ============================================================

	if atacante.morto or not atacante.esta_consciente():
		log_panel.registrar_evento(
			"%s não consegue concluir o ataque." % atacante.nome,
			"critico"
		)

		if atacante.morto:
			await _derrotar_combatente(atacante)
		else:
			_atualizar_painel_combatente(atacante)
			_verificar_fim_combate()

		if not combate_ativo:
			return

		await _finalizar_acao()
		return

	# ============================================================
	# PROCESSAR SUCESSOS
	# ============================================================

	var sucessos = resultado_combate["total_sucessos"]
	# Com os dados já mostrados, o atacante executa a animação.
	await _animar_atacante(atacante)
	# Proteção do alvo neste ataque (0 = já quebrada, ex.: Duelo extremo).
	var protecao_atual: int = alvo.obter_protecao_atual()
	if sucessos <= 0 and protecao_atual > 0:
		log_panel.registrar_evento(
			"Nenhum sucesso obtido.",
			"info"
		)
		await _animar_esquiva(alvo)
	else:
		log_panel.registrar_evento(
			"Proteção de %s: %d/%d" % [
				alvo.nome,
				protecao_atual,
				alvo.atributo_protecao
			],
			"info",
			false
		)
		var texto_acertos: String = "1 acerto obtido!"
		if sucessos != 1:
			texto_acertos = "%d acertos obtidos!" % sucessos
		log_panel.registrar_evento(texto_acertos, "sucesso")
		if sucessos < protecao_atual:
			var protecao_antes = protecao_atual

			alvo.reducao_protecao_temporaria += sucessos

			var protecao_depois = alvo.obter_protecao_atual()

			log_panel.registrar_evento(
				"Proteção reduzida: %d → %d" % [
					protecao_antes,
					protecao_depois
				],
				"info"
			)
		else:
			alvo.atacante_que_quebrou_protecao = atacante.nome
			log_panel.registrar_evento(
				"Proteção quebrada!",
				"critico"
			)

			# Apresenta ataque, acertos e quebra ANTES da rolagem de dano.
			await _apresentar_pendentes()

			# Sorteia o dano da arma uma vez; a animação mostra esses mesmos valores.
			var dano_atributo: int = atacante.atributo_dano
			var dados_arma: Array[int] = []
			var dano_arma: int = 0
			if atacante.arma_equipada != "":
				dados_arma = ArmaData.rolar_dados_arma(atacante.arma_equipada)
				for valor in dados_arma:
					dano_arma += valor
				await _rolar_dados_dano_visuais(atacante.arma_equipada, dados_arma)
			var dano_total: int = dano_atributo + dano_arma

			# Só depois da rolagem: dano base e dano da arma.
			log_panel.registrar_evento(
				"Dano base: %d | Dano da arma: %d" % [dano_atributo, dano_arma],
				"info"
			)
			await _apresentar_pendentes()

			# A Proteção foi quebrada. Sorteia a região atingida pelo ataque.
			var resultado_localizacao: int = await _rolar_dado_conhecimento(
				"Localização do golpe"
			)

			if resultado_localizacao < 1 or resultado_localizacao > 6:
				push_error("[CombatManager] Falha ao determinar a localização do golpe.")
				await _finalizar_acao()
				return

			var regiao_atingida: String = _obter_regiao_atingida(
				resultado_localizacao
			)

			if regiao_atingida.is_empty():
				push_error("[CombatManager] Região atingida inválida.")
				await _finalizar_acao()
				return

			log_panel.registrar_evento(
				"Localização do golpe: D6 %d → %s." % [
					resultado_localizacao,
					regiao_atingida
				],
				"ataque"
			)

			await _apresentar_pendentes()

			alvo.reducao_protecao_temporaria = alvo.atributo_protecao
			await _animar_dano(alvo)

			# Aplica o dano na região sorteada.
			# O excedente de membros continua transbordando para o Torso.
			var estresse_antes: int = alvo.get_estresse_total()

			var resultado_estresse = _aplicar_estresse_registrado(
				alvo,
				regiao_atingida,
				dano_total
			)

			var dano_efetivo: int = (
				alvo.get_estresse_total() - estresse_antes
			)

			log_panel.registrar_evento(
				"%s sofreu %d pontos de dano em %s." % [
					alvo.nome,
					dano_efetivo,
					regiao_atingida
				],
				"dano"
			)

			if resultado_estresse.has("regiao_esgotada"):
				log_panel.registrar_evento(
					String(resultado_estresse["mensagem"]),
					"aviso"
				)

			if resultado_estresse.has("resultado_fardo"):
				log_panel.registrar_evento(
					resultado_estresse["resultado_fardo"]["mensagem"],
					"critico"
				)
	# ============================================================
	# RESUMO
	# ============================================================

	log_panel.registrar_evento(
		"Sucessos: %d | Falhas: %d (simples: %d, críticas: %d)" % [
			resultado_combate["total_sucessos"],
			resultado_combate["falhas_regulares"] + resultado_combate["falhas_criticas"],
			resultado_combate["falhas_regulares"],
			resultado_combate["falhas_criticas"]
		],
		"info",
		false
	)
	_atualizar_painel_combatente(atacante)
	if alvo.tipo == "jogador":
		_atualizar_painel_combatente(alvo)
	var inimigos_atualizado: Array[Dictionary] = []
	for inimigo in combatentes_inimigo:
		enemy_panel.atualizar_inimigo(
		inimigo.para_dictionary()
	)

	if alvo.morto:
		await _derrotar_combatente(alvo)
	elif alvo.tipo == "jogador" and not alvo.esta_consciente():
		_verificar_fim_combate()

	if not combate_ativo:
		return

	await _finalizar_acao()
	return

# Animação do atacante: só roda depois da rolagem visual.
func _animar_atacante(atacante: CombatenteData) -> void:
	var anim: CombatenteAnimation = animacao_jogador if atacante.tipo == "jogador" else animacao_inimigo
	if anim != null:
		await anim.tocar_ataque()

# Reação do alvo ao dano: o fluxo só continua quando o Hit termina.
func _animar_dano(alvo: CombatenteData) -> void:
	var anim: CombatenteAnimation = animacao_jogador if alvo.tipo == "jogador" else animacao_inimigo
	if anim != null:
		await anim.tocar_dano()

# Esquiva do alvo: usada quando a Proteção não foi quebrada.
func _animar_esquiva(alvo: CombatenteData) -> void:
	var anim: CombatenteAnimation = animacao_jogador if alvo.tipo == "jogador" else animacao_inimigo
	if anim != null:
		await anim.tocar_esquiva()

func _finalizar_acao() -> void:
	_limpar_dados_visuais()
	acao_em_progresso = false
	regioes_selecionadas.clear()
	enemy_panel.desativar_seletor_alvo()
	# Aguarda o jogador ler as mensagens da ação.
	await _aguardar_leitura()
	if not combate_ativo:
		return
	await _retomar_ou_encerrar_turno()

func _retomar_ou_encerrar_turno() -> void:
	if not combate_ativo or combatente_ativo == null:
		return

	# Durante o turno inimigo, o loop da IA decide a próxima ação.
	if (
		combatente_ativo.tipo == "inimigo"
		and turno_inimigo_em_execucao
	):
		return

	if (
		combatente_ativo.tipo == "jogador"
		and combatente_ativo.esta_consciente()
		and combatente_ativo.pontos_acao_atuais > 0
	):
		action_panel.ativar_para(
			combatente_ativo.para_dictionary(),
			combatente_ativo
		)
		return

	action_panel.desabilitar_acoes()
	turno_finalizado.emit(combatente_ativo)
	await _avancar_turno()

func _avaliar_categoria_resultado(dado: int) -> String:
	"""Categoriza o resultado do dado conforme OBLIVIO"""
	match dado:
		6:
			return "Sucesso Extremo"
		4, 5:
			return "Sucesso Regular"
		2, 3:
			return "Falha Regular"
		1:
			return "Falha Crítica"
		_:
			return "Indefinido"

# ============================================================
# LEITURA DA COMUNICAÇÃO E CLIQUES NO CAMPO
# Depois de uma ação, a comunicação fica na tela até o jogador
# confirmar (Enter/Espaço ou clique no campo ou na caixa).
# Com a escolha de alvo aberta, um clique no campo a cancela.
# ============================================================
func _conectar_cliques_campo() -> void:
	campo_batalha.gui_input.connect(_on_campo_gui_input)
	log_panel.gui_input.connect(_on_campo_gui_input)


func _on_campo_gui_input(event: InputEvent) -> void:
	var clique := event as InputEventMouseButton
	if clique == null or not clique.pressed or clique.button_index != MOUSE_BUTTON_LEFT:
		return
	if aguardando_leitura:
		_confirmar_leitura()
	elif enemy_panel.modo_seletor_ativo:
		enemy_panel.cancelar_selecao_alvo()


func _unhandled_input(event: InputEvent) -> void:
	if caixa_ajuda != null and caixa_ajuda.esta_aberta():
		return
	if aguardando_leitura and event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_confirmar_leitura()


func _aguardar_leitura() -> void:
	if not combate_ativo:
		return
	await _apresentar_pendentes()

# Apresenta a fila uma mensagem por vez. Sem pendências, não espera.
func _apresentar_pendentes() -> void:
	var mensagens: Array[Dictionary] = log_panel.retirar_pendentes()
	if mensagens.is_empty():
		return
	action_panel.desabilitar_acoes()
	for i in range(mensagens.size()):
		log_panel.mostrar_mensagem(
			String(mensagens[i]["mensagem"]),
			String(mensagens[i]["tipo"])
		)
		_definir_dica_leitura(true, i, mensagens.size())
		aguardando_leitura = true
		await leitura_confirmada
	_definir_dica_leitura(false)
	log_panel.limpar_apresentacao()

func _confirmar_leitura() -> void:
	if not aguardando_leitura:
		return
	# Um clique ou tecla faz uma única coisa por vez.
	var frame: int = Engine.get_process_frames()
	if frame == _frame_confirmacao:
		return
	_frame_confirmacao = frame

	# Primeiro gesto durante a digitação: completa o texto.
	if log_panel.escrevendo:
		log_panel.pular_escrita = true
		return

	aguardando_leitura = false
	leitura_confirmada.emit()

func _definir_dica_leitura(ativa: bool, indice: int = 0, total: int = 0) -> void:
	if dica_continuar == null:
		return
	dica_continuar.visible = ativa
	if not ativa:
		return
	if indice < total - 1:
		dica_continuar.text = "(%d/%d) Enter ou clique: avançar" % [indice + 1, total]
	else:
		dica_continuar.text = "Enter ou clique: continuar"

# Variante para ações que não terminam o turno (habilidade, item
# inválido, Sobrecarga): lê a mensagem e devolve o ActionPanel.
func _devolver_acoes_apos_leitura() -> void:
	await _aguardar_leitura()
	if not combate_ativo:
		return
	_retomar_ou_encerrar_turno()

# ============================================================================
# SISTEMA DE COMBATENTES
# ============================================================================
func _derrotar_combatente(combatente: CombatenteData) -> void:
	if not ordem_turno.has(combatente):
		return

	# Executa a animação de morte antes de remover o personagem.
	if combatente.tipo == "jogador":
		if animacao_jogador != null:
			await animacao_jogador.tocar_morte()
	else:
		if animacao_inimigo != null:
			await animacao_inimigo.tocar_morte()

	log_panel.registrar_evento(
		"⚠️ %s foi derrotado!" % combatente.nome,
		"critico"
	)

	var indice_removido = ordem_turno.find(combatente)
	ordem_turno.erase(combatente)

	if indice_removido <= indice_turno_atual:
		indice_turno_atual -= 1

	if combatente.tipo == "inimigo":
		inimigos_derrotados.append(combatente.nome)
		combatentes_inimigo.erase(combatente)
		enemy_panel.remover_inimigo(
			combatente.para_dictionary()
		)
	else:
		combatentes_jogador.erase(combatente)
		party_panel.remover_personagem(
			combatente.para_dictionary()
		)

	_verificar_fim_combate()

	if not combate_ativo:
		return

func _verificar_fim_combate() -> void:
	"""Verifica se um dos lados foi completamente derrotado"""
	var jogadores_vivos = combatentes_jogador.filter(
		func(c): return not c.morto and c.esta_consciente()
	)
	var inimigos_vivos = combatentes_inimigo.filter(
		func(c): return not c.morto and c.esta_consciente()
	)

	if jogadores_vivos.is_empty():
		_finalizar_combate("Derrota")
	elif inimigos_vivos.is_empty():
		_finalizar_combate("Vitória")


func _finalizar_combate(resultado: String) -> void:
	"""Encerra o combate e retorna ao menu/mapa"""
	if not combate_ativo:
		return
	combate_ativo = false
	# A música muda assim que o combate termina.
	AudioManager.tocar_musica(&"ciclo")
	# O resumo é capturado antes da linha de encerramento, que repetiria o título.
	resumo_resultado = log_panel.obter_resumo(6)
	# Se o combate acabou durante o turno de um aliado, consolida o estilo dele.
	if combatente_ativo != null:
		estatisticas.finalizar_turno(combatente_ativo)
	# Calculado uma única vez (esta função só roda com combate_ativo).
	resultado_pontuacao = estatisticas.montar_resultado(
		ClassificacaoCombate.new(),
		resultado
	)
	log_panel.registrar_evento(
		"═══ COMBATE FINALIZADO: %s ═══" % resultado,
		"critico",
		false
	)

	combate_finalizado.emit(resultado)

	# TODO: Tela de resultado, experience, loot
	print("[CombatManager] Combate finalizado com resultado: %s" % resultado)
	log_panel.registrar_evento("Retornando ao mapa...", "info", false)
	_voltar_ao_mapa(resultado)

func _voltar_ao_mapa(resultado: String) -> void:
	action_panel.desabilitar_acoes()
	enemy_panel.desativar_seletor_alvo()

	await _apresentar_pendentes()
	var itens_recebidos: Array[Dictionary] = await _mostrar_resultado(resultado)
	var principal: CombatenteData = GrupoAtual.obter_personagem_principal()
	if principal != null:
		_entregar_itens(principal, itens_recebidos)
		# O Estresse acumulado é mantido ao voltar ao mapa.
		principal.limpar_efeitos_combate()
		# Só na derrota o personagem descansa por completo.
		if resultado == "Derrota":
			principal.recuperar_apos_combate()

	var erro := get_tree().change_scene_to_file(CENA_MAPA)
	if erro != OK:
		push_error("[CombatManager] Não foi possível voltar ao mapa. Erro: %s" % erro)
# ============================================================================
# UTILIDADES
# ============================================================================

func calcular_estresse_total(combatente: Dictionary) -> int:
	"""Calcula estresse acumulado de todas as regiões"""
	var total = 0
	for regiao in combatente["estresse_por_regiao"].values():
		total += regiao
	return total

func aplicar_status(combatente: Dictionary, status_nome: String, duracao: int = 1) -> void:
	"""Aplica um status ao combatente"""
	var status = {
		"nome": status_nome,
		"duracao": duracao
	}

	if not status in combatente["status"]:
		combatente["status"].append(status)
		log_panel.registrar_evento(
			"%s está [%s]!" % [combatente["nome"], status_nome],
			"aviso"
		)

func remover_status(combatente: Dictionary, status_nome: String) -> void:
	"""Remove um status do combatente"""
	combatente["status"] = combatente["status"].filter(
		func(s): return s["nome"] != status_nome
	)

# ============================================================
# ALTERNÂNCIA DOS PAINÉIS INFERIORES
# ComunicacaoPanel ocupa a mesma região de ActionPanel e
# RegionalPanel e só aparece quando nenhum dos dois está visível.
# É o único ponto que controla a visibilidade da comunicação.
# O ActionPanel continua dono do próprio estado.
# ============================================================
func _conectar_alternancia_paineis() -> void:
	action_panel.visibility_changed.connect(_sincronizar_paineis_inferiores)
	regional_selector.visibility_changed.connect(_sincronizar_paineis_inferiores)
	_sincronizar_paineis_inferiores()

# ============================================================
# NAVEGAÇÃO ENTRE CARDS (Q / Espaço / Tab)
# Fica em _input para ser tratada antes da GUI: assim o Espaço
# não aciona o botão focado (ui_accept) e o Tab não move o foco.
# Só vale com o combate ativo; fora dele o Espaço continua sendo
# confirmação normal (ex.: tela de resultados).
# ============================================================
func _input(event: InputEvent) -> void:
	# Ajuda aberta: o combate fica totalmente parado.
	if caixa_ajuda != null and caixa_ajuda.esta_aberta():
		return
	if InputMap.has_action("abrir_ajuda") and event.is_action_pressed("abrir_ajuda") \
			and not event.is_echo():
		get_viewport().set_input_as_handled()
		if _pode_abrir_ajuda():
			caixa_ajuda.abrir("combate")
		return
	if not combate_ativo:
		return
	if event.is_action_pressed("ver_ficha") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_alternar_ficha()
		return
	# Com a ficha aberta, Q, Espaço e Tab não navegam nos cards.
	if ficha_inimigo.visible:
		return
	var anterior: bool = event.is_action_pressed("card_anterior", true)
	var proximo: bool = event.is_action_pressed("card_proximo", true)
	var alternar: bool = event.is_action_pressed("alternar_painel", true)
	if not (anterior or proximo or alternar):
		return

	get_viewport().set_input_as_handled()
	if event.is_echo():
		return

	if alternar:
		_alternar_painel()
	elif proximo:
		_navegar_card(1)
	else:
		_navegar_card(-1)


# Na escolha de alvo o painel de inimigos recebe a navegação sempre.
func _navegar_card(passo: int) -> void:
	if enemy_panel.modo_seletor_ativo or painel_inimigos_ativo:
		enemy_panel.navegar(passo)
	else:
		party_panel.navegar(passo)


func _alternar_painel() -> void:
	if enemy_panel.modo_seletor_ativo:
		return
	painel_inimigos_ativo = not painel_inimigos_ativo
	_atualizar_marcadores_painel()

func _atualizar_marcadores_painel(_modo_alvo: bool = false) -> void:
	var inimigos: bool = painel_inimigos_ativo or enemy_panel.modo_seletor_ativo

	party_panel.definir_marcador(not inimigos)
	enemy_panel.definir_marcador(inimigos)

func _sincronizar_paineis_inferiores() -> void:
	comunicacao_panel.visible = not (action_panel.visible or regional_selector.visible)

# ============================================================
# ESTATÍSTICAS DE COMBATE (pontuação)
# Único ponto que aplica Estresse e registra o que REALMENTE
# mudou (variação do total, já com limite e transbordamento).
# Não usa o CombatLog como fonte.
# ============================================================
func _aplicar_estresse_registrado(
	alvo: CombatenteData,
	regiao: String,
	quantidade: int,
	por_falha: bool = false
) -> Dictionary:
	var total_antes: int = alvo.get_estresse_total()
	var desmaiado_antes: bool = alvo.desmaiado
	var resultado: Dictionary = alvo.aplicar_estresse(regiao, quantidade)
	var efetivo: int = alvo.get_estresse_total() - total_antes

	if not por_falha or EstatisticasCombate.CONTAR_ESTRESSE_DE_FALHA:
		if alvo.tipo == "inimigo":
			estatisticas.registrar_dano_causado(efetivo)
		else:
			estatisticas.registrar_dano_recebido(efetivo)

	# Só a transição real ativo -> desmaiado de um aliado conta
	# (inclusive quando causada pelas falhas do próprio atacante).
	if alvo.tipo != "inimigo" and not desmaiado_antes and alvo.desmaiado:
		estatisticas.registrar_desmaio()
	return resultado


# Reanimação válida: só conta se o aliado estava desmaiado (e vivo)
# e voltou ao estado ativo. Ainda não é chamada: não existe mecânica
# de reanimação em combate. Quem a criar deve usar esta função.
func _reanimar_combatente(alvo: CombatenteData) -> bool:
	if alvo == null or alvo.morto or not alvo.desmaiado:
		return false
	alvo.reviver()
	if alvo.desmaiado:
		return false
	estatisticas.registrar_reanimacao()
	return true

# ============================================================
# TELA DE RESULTADOS
# ============================================================
# Abre a tela de resultados e espera o jogador confirmar.
func _mostrar_resultado(resultado: String) -> Array[Dictionary]:
	var itens: Array[Dictionary] = []
	var instancia := CENA_RESULTADO.instantiate()
	var tela := instancia as ResultadoCombate
	if tela == null:
		push_error("[CombatManager] resultado_combate.tscn sem o script ResultadoCombate.")
		instancia.queue_free()
		return itens

	camada_resultado.add_child(tela)
	tela.configurar(_montar_dados_resultado(resultado))

	await tela.confirmado
	itens.append_array(tela.itens_obtidos)
	tela.queue_free()
	return itens

func _atualizar_painel_combatente(
	combatente: CombatenteData
) -> void:
	if combatente == null:
		return

	if combatente.tipo == "jogador":
		party_panel.atualizar_personagem(
			combatente.para_dictionary()
		)
	else:
		enemy_panel.atualizar_inimigo(
			combatente.para_dictionary()
		)

# Contrato de dados da tela. "almas" e "itens" ficam de fora
# até existirem sistemas definidos para eles.
func _montar_dados_resultado(resultado: String) -> Dictionary:
	return {
		"resultado": resultado,
		"resumo": resumo_resultado,
		"estatisticas": resultado_pontuacao,
		"recompensa_habilitada": resultado == "Vitória",
		"inimigos_derrotados": inimigos_derrotados,
		"fardos": _fardos_obtidos()
	}

# Fardos adquiridos nesta batalha (compara com o estado inicial).
func _fardos_obtidos() -> Array[String]:
	var nomes: Array[String] = []
	var principal: CombatenteData = GrupoAtual.obter_personagem_principal()
	if principal == null:
		return nomes
	for i in range(fardos_iniciais, principal.fardos.size()):
		nomes.append(String(principal.fardos[i].nome))
	return nomes

# Anuncia a ordem real de atuação (a mesma usada por _avancar_turno).
func _anunciar_ordem_iniciativa() -> void:
	var linhas: Array[String] = []
	for i in range(ordem_turno.size()):
		var combatente: CombatenteData = ordem_turno[i]
		linhas.append("%d. %s (Velocidade %d)" % [i + 1, combatente.nome, combatente.iniciativa])
	log_panel.registrar_evento("Ordem de atuação:\n" + "\n".join(linhas), "turno")

# Abre ou fecha a ficha do inimigo que está no card.
# Não abre durante a leitura de mensagens nem durante a rolagem dos dados.
func _alternar_ficha() -> void:
	if ficha_inimigo.visible:
		ficha_inimigo.fechar()
		return

	if aguardando_leitura or dados_em_animacao:
		return

	var inimigo: Dictionary = enemy_panel.obter_inimigo_exibido()

	if inimigo.is_empty():
		return

	# A ficha completa só pode ser consultada após a análise.
	var analisado: bool = bool(
		inimigo.get("informacoes_reveladas", false)
	)

	if not analisado:
		log_panel.registrar_evento(
			"Você ainda não conhece informações suficientes sobre este inimigo.",
			"info"
		)
		await _devolver_acoes_apos_leitura()
		return

	ficha_inimigo.abrir(inimigo)

# Entrega os itens ao personagem principal. O inventário é uma lista de
# nomes: repetir o nome é a quantidade (sem tocar em ItemData.adicionar_item).
func _entregar_itens(destino: CombatenteData, itens: Array[Dictionary]) -> void:
	for item in itens:
		for i in range(int(item.get("quantidade", 1))):
			destino.inventario.append(String(item["nome"]))

# ============================================================
# AJUDA CONTEXTUAL
# A janela só abre no turno do jogador esperando comando.
# Enquanto estiver aberta, _input e _unhandled_input não agem,
# e o fundo da janela bloqueia os cliques.
# ============================================================
func _conectar_botoes_ajuda() -> void:
	for botao in get_tree().get_nodes_in_group("botao_ajuda"):
		if botao is BotaoAjuda:
			botao.solicitado.connect(_on_ajuda_solicitada)


func _on_ajuda_solicitada(painel: String, ancora: String) -> void:
	if _pode_abrir_ajuda():
		caixa_ajuda.abrir(painel, ancora)


func _pode_abrir_ajuda() -> bool:
	if caixa_ajuda == null or caixa_ajuda.esta_aberta():
		return false
	if not combate_ativo or aguardando_leitura or dados_em_animacao or acao_em_progresso:
		return false
	if combatente_ativo == null or combatente_ativo.tipo != "jogador":
		return false
	if not action_panel.visible or enemy_panel.modo_seletor_ativo:
		return false
	# Ficha de inimigo (se existir na sua cena).
	var ficha := get_node_or_null("%FichaInimigo") as Control
	return ficha == null or not ficha.visible


# Ajuda de combate do primeiro combate. Veja a limitação do salvamento.
func _mostrar_ajuda_inicial() -> void:
	if caixa_ajuda == null or not ajuda_automatica or _ajuda_combate_ja_vista():
		return
	caixa_ajuda.abrir("combate")
	await caixa_ajuda.fechada
	_registrar_ajuda_combate_vista()


func _ajuda_combate_ja_vista() -> bool:
	# TODO (salvamento): consultar o dado persistente do salvamento atual.
	return false


func _registrar_ajuda_combate_vista() -> void:
	# TODO (salvamento): gravar no salvamento que a ajuda de combate foi vista.
	pass
