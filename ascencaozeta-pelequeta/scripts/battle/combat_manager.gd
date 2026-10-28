extends Node
class_name CombatManager

# Importações
const RolagemDadosD6 = preload("res://scripts/battle/rolagens-dados-d6.gd")
const CENA_MAPA: String = "res://scenes/mapas/CabanaElizabeth.tscn"
const CENA_DADO_D6: PackedScene = preload(
    "res://scenes/testes/rolagem-dado.tscn"
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

# Painéis da cena
@onready var party_panel = %PartyPanel
@onready var enemy_panel = %EnemyPanel
@onready var battlefield = %Battlefield
@onready var regional_selector = %RegionalPanel
@onready var action_panel = %ActionPanel
@onready var log_panel: CombatLog = $MarginContainer/VBoxContainer/LogPanel/RichTextLabel

@onready var player_visual: Node = %Battlefield.find_child(
	"PlayerVisual", true, false
)
@onready var enemy_visual: Node = %Battlefield.find_child(
	"EnemyVisual", true, false
)

var animacao_jogador: CombatenteAnimation
var animacao_inimigo: CombatenteAnimation


# Estado do combate
var combatentes_jogador: Array[CombatenteData] = []
var combatentes_inimigo: Array[CombatenteData] = []
var ordem_turno: Array[CombatenteData] = []
var indice_turno_atual := -1
var combatente_ativo: CombatenteData = null
var combate_ativo: bool = false
var conhecimento_pendente := ""

# Estado da ação atual
var acao_em_progresso: bool = false
var regioes_selecionadas: Array[String] = []
var alvo_selecionado: Dictionary = {}


func _ready() -> void:
	_conectar_sinais_paineis()
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
	if regional_selector:
		regional_selector.desativar()

	# Calcular iniciativa
	_calcular_iniciativa()

	# Ordenar by iniciativa
	ordem_turno.sort_custom(func(a, b): return a.iniciativa > b.iniciativa)

	combate_ativo = true
	combate_iniciado.emit()

	# Começar primeiro turno
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
		log_panel.registrar_evento(
			"%s iniciativa: %d" % [combatente.nome, combatente.iniciativa],
			"info"
		)

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

	acao_em_progresso = false
	regioes_selecionadas.clear()
	# Não limpar alvo_selecionado aqui - será limpo apenas quando mudar de turno de verdade

	# Procurar próximo combatente vivo
	var combatente_proxximo = _encontrar_proximo_combatente()

	if not combatente_proxximo:
		print("[CombatManager] Nenhum combatente disponível - possível empate")
		return

	combatente_ativo = combatente_proxximo
	_restaurar_protecoes(combatente_ativo)
	turno_iniciado.emit(combatente_ativo)

	# Ativar painel de ações se for personagem jogador
	if combatente_ativo.tipo == "jogador":
		action_panel.ativar_para(combatente_ativo.para_dictionary(), combatente_ativo)
		party_panel.indicar_personagem_ativo(combatente_ativo.para_dictionary())
		enemy_panel.desativar_seletor_alvo()
		log_panel.registrar_evento(
			"🎯 Turno de %s!" % combatente_ativo.nome,
			"turno"
		)
		# Limpar seleções apenas ao iniciar turno do jogador
		alvo_selecionado.clear()
	else:
		party_panel.remover_destaque_turno()
		action_panel.desabilitar_acoes()
		# TODO: IA para inimigos
		await get_tree().create_timer(0.3).timeout
		_executar_turno_inimigo()

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
				"info"
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
				"info"
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
	"""Executa turno automático do inimigo (placeholder)"""
	print("[CombatManager] Turno do inimigo: %s" % combatente_ativo.nome)

	# TODO: Implementar IA
	# Por enquanto, passa o turno
	await get_tree().create_timer(0.2).timeout
	turno_finalizado.emit(combatente_ativo)
	_avancar_turno()

# ============================================================================
# AÇÕES DO COMBATENTE
# ============================================================================

func _iniciar_ataque() -> void:
	"""Inicia sequência de ataque: seleciona regiões → seleciona alvo → rola dados"""
	if acao_em_progresso or combatente_ativo.tipo != "jogador":
		return

	acao_em_progresso = true
	action_panel.desabilitar_acoes()
	log_panel.registrar_evento("Selecione as regiões de ataque...", "acao")

	# Ativar seletor de corpo com validação de Próteses/Regiões Perdidas/Sobrecarga
	regional_selector.ativar_para_ataque(combatente_ativo)
	regional_selector.modo = "selecionar_ataque"

func _iniciar_conhecimento() -> void:
	"""Inicia uso de perícia"""
	if acao_em_progresso or combatente_ativo.tipo != "jogador":
		return

	acao_em_progresso = true
	log_panel.registrar_evento("Menu de perícias aberto...", "acao")

	# TODO: Mostrar menu de perícias disponíveis
	action_panel.mostrar_menu_conhecimentoss(combatente_ativo.para_dictionary())

func _iniciar_habilidade() -> void:
	"""Inicia uso de habilidade especial"""
	if acao_em_progresso or combatente_ativo.tipo != "jogador":
		return

	acao_em_progresso = true
	log_panel.registrar_evento("Menu de habilidades aberto...", "acao")

	# A seleção visual fica no ActionPanel para manter o mesmo fluxo das Perícias:
	# Menu Principal -> Lista -> Detalhes -> Confirmar Uso.
	# O CombatManager só volta a atuar quando a habilidade for confirmada.
	action_panel.mostrar_menu_habilidades(combatente_ativo.para_dictionary())

func _ativar_sobrecarga() -> void:
	if combatente_ativo == null:
		return

	combatente_ativo.habilidade_sobrecarga_ativa = true

	acao_em_progresso = false

	log_panel.registrar_evento(
		"⚡ %s entrou em SOBRECARGA!" % combatente_ativo.nome,
		"critico"
	)

	action_panel.habilitar_acoes()

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
		action_panel.habilitar_acoes()
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
	action_panel.habilitar_acoes()

func _iniciar_item() -> void:
	"""Inicia uso de item"""
	if acao_em_progresso or combatente_ativo.tipo != "jogador":
		return

	acao_em_progresso = true
	log_panel.registrar_evento("Menu de itens aberto...", "acao")

	# TODO: Mostrar inventário
	action_panel.mostrar_menu_itens(combatente_ativo.para_dictionary())

func _on_item_escolhido(nome_item: String) -> void:
	if combatente_ativo == null or combatente_ativo.tipo != "jogador":
		return

	var item: ItemData.Item = ItemData.obter_item(nome_item)
	if item == null or not ItemData.tem_item(combatente_ativo, nome_item):
		log_panel.registrar_evento("Item indisponível.", "aviso")
		action_panel.habilitar_acoes()
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
		action_panel.habilitar_acoes()
		return

	var resultado: Dictionary = ItemData.usar_item(combatente_ativo, item, regiao_alvo)
	if not resultado.get("sucesso", false):
		log_panel.registrar_evento(
			String(resultado.get("mensagem", "Falha ao usar o item.")),
			"aviso"
		)
		action_panel.habilitar_acoes()
		return

	ItemData.remover_item(combatente_ativo, nome_item)
	log_panel.registrar_evento(String(resultado["mensagem"]), "sucesso")
	party_panel.atualizar_personagem(combatente_ativo.para_dictionary())
	_finalizar_acao()

func _executar_conhecimento_duelo(alvo: CombatenteData) -> void:
	if alvo == null:
		return

	var conhecimento = ConhecimentoData.new()

	var resultado = conhecimento.executar_duelo(
		combatente_ativo,
		alvo
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
			alvo.analisado_por_duelo = true
			enemy_panel.atualizar_inimigo(
				alvo.para_dictionary()
			)

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
			alvo.analisado_por_duelo = true
			enemy_panel.atualizar_inimigo(
				alvo.para_dictionary()
			)

	_finalizar_acao()

func _executar_conhecimento_rastro(alvo: CombatenteData) -> void:
	"""Rastro: igual ao Duelo, mas só revela as informações do inimigo."""
	if alvo == null:
		return

	var conhecimento = ConhecimentoData.new()
	var resultado: Dictionary = conhecimento.testar_conhecimento(
		combatente_ativo,
		"Rastro"
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
		alvo.analisado_por_duelo = true
		log_panel.registrar_evento(
			"%s examinou %s. Proteção atual: %d" % [
				combatente_ativo.nome,
				alvo.nome,
				alvo.obter_protecao_atual()
			],
			"info"
		)
		enemy_panel.atualizar_inimigo(
			alvo.para_dictionary()
		)
	else:
		log_panel.registrar_evento(
			"%s não percebeu nada de útil em %s." % [
				combatente_ativo.nome,
				alvo.nome
			],
			"info"
		)

	_finalizar_acao()

func _tentar_fugir() -> void:
	"""Bandidagem: em sucesso foge da batalha e volta ao mapa. Falha gasta o turno."""
	var conhecimento = ConhecimentoData.new()
	var resultado: Dictionary = conhecimento.testar_conhecimento(
		combatente_ativo,
		"Bandidagem"
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
	log_panel.registrar_evento("Seleção de alvo cancelada.", "aviso")
	action_panel.habilitar_acoes()

func _on_conhecimento_escolhida(nome_conhecimento: String) -> void:

	if combatente_ativo == null:
		return

	match nome_conhecimento:

		"Duelo", "Rastro":
			conhecimento_pendente = nome_conhecimento

			log_panel.registrar_evento(
				"Selecione o alvo de %s. (Esc cancela)" % nome_conhecimento,
				"acao"
			)

			# Esconde o menu de ações: a escolha agora é só o alvo.
			action_panel.desabilitar_acoes()
			enemy_panel.ativar_seletor_alvo()

		"Bandidagem":
			_tentar_fugir()

		_:
			log_panel.registrar_evento(
				"Conhecimento %s ainda não implementado." % nome_conhecimento,
				"info"
			)

# ============================================================================
# CALLBACKS DE SELEÇÃO
# ============================================================================

func _on_regiao_selecionada(nome_regiao: String, indice: int) -> void:

	if combatente_ativo.habilidade_sobrecarga_ativa:
		regioes_selecionadas.append(nome_regiao)

		log_panel.registrar_evento(
			"⚡ Sobrecarga: %s arriscada novamente!" % nome_regiao,
			"critico"
		)

	else:
		if nome_regiao not in regioes_selecionadas:
			regioes_selecionadas.append(nome_regiao)
		else:
			regioes_selecionadas.erase(nome_regiao)

func _on_regioes_confirmadas(regioes: Array[String]) -> void:
	"""Chamado quando o jogador confirma as regiões selecionadas"""
	regioes_selecionadas = regioes.duplicate()
	log_panel.registrar_evento("Regiões confirmadas: %s" % ", ".join(regioes_selecionadas), "acao")
	log_panel.registrar_evento("Selecione o inimigo alvo...", "acao")
	regional_selector.desativar()
	enemy_panel.ativar_seletor_alvo()

func _on_selecao_cancelada() -> void:
	"""Chamado quando o jogador cancela a seleção de regiões"""
	acao_em_progresso = false
	regioes_selecionadas.clear()
	alvo_selecionado.clear()
	log_panel.registrar_evento("Seleção de regiões cancelada.", "aviso")
	regional_selector.desativar()
	action_panel.habilitar_acoes()

func _on_turno_passado() -> void:
	"""Chamado quando o jogador clica em PASSAR TURNO"""
	if combatente_ativo and combatente_ativo.tipo == "jogador":
		log_panel.registrar_evento("Turno passado.", "info")
		action_panel.desabilitar_acoes()
		turno_finalizado.emit(combatente_ativo)
		await get_tree().create_timer(1.0).timeout
		_avancar_turno()

func _on_inimigo_selecionado(inimigo_dict: Dictionary) -> void:

	if not inimigo_dict.has("nome"):
		log_panel.registrar_evento(
			"Inimigo inválido selecionado!",
			"aviso"
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
			"aviso"
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
			"aviso"
		)
		return

	enemy_panel.desativar_seletor_alvo()

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


func _rolar_dados_visuais(regioes: Array[String]) -> Array[int]:
	if dados_em_animacao:
		return []

	dados_em_animacao = true
	_limpar_dados_visuais()

	var quantidade: int = clampi(regioes.size(), 1, 5)
	var resultados: Array[int] = []

	# Sorteia uma única vez. Os mesmos valores serão usados no combate.
	for i in range(quantidade):
		resultados.append(randi_range(1, 6))

	var espacamento: float = 23.0
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

		battlefield.add_child(dado)
		dado.position = Vector2(
			battlefield.size.x / 2.0 + inicio_x + i * espacamento,
			battlefield.size.y / 2.0 - 40.0
		)
		dado.scale = Vector2(1.25, 1.25)
		dados_visuais.append(dado)

	# Anima todos os dados; cada face corresponde ao resultado sorteado.
	for i in range(dados_visuais.size()):
		await dados_visuais[i].rodar_e_mostrar_face(resultados[i])

	dados_em_animacao = false
	return resultados

func _processar_ataque(
	atacante: CombatenteData,
	alvo: CombatenteData,
	regioes: Array[String]
) -> void:
	if atacante.tipo == "jogador":
		if animacao_jogador != null:
			await animacao_jogador.tocar_ataque()
	else:
		if animacao_inimigo != null:
			await animacao_inimigo.tocar_ataque()
	# Exibe os dados e guarda os resultados reais da rolagem.
	var resultados_dados: Array[int] = await _rolar_dados_visuais(regioes)

	if resultados_dados.is_empty():
		push_error("[CombatManager] Não foi possível concluir a rolagem dos dados.")
		_limpar_dados_visuais()
		_finalizar_acao()
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

	for res_regiao in resultado_combate["resultados_por_regiao"]:
		log_panel.registrar_evento(
			"Região: %s → D6: %d (%s)" % [
				res_regiao["regiao"],
				res_regiao["dado"],
				res_regiao["categoria"]
			],
			"ataque"
		)
		if res_regiao["categoria"] in ["Falha Regular", "Falha Crítica"]:
			var estresse_gerado := 1
			if res_regiao["categoria"] == "Falha Crítica":
				estresse_gerado = 2
			var resultado_estresse = atacante.aplicar_estresse(
				res_regiao["regiao"],
				estresse_gerado
			)
			if resultado_estresse.has("regiao_esgotada"):
				log_panel.registrar_evento(
					"%s: %s" % [
						atacante.nome,
						resultado_estresse["mensagem"]
					],
					"aviso"
				)
			log_panel.registrar_evento(
				"%s sofre %d de estresse em %s (ataque falhou)" % [
					atacante.nome,
					estresse_gerado,
					res_regiao["regiao"]
				],
				"aviso"
			)
			if not resultado_estresse.is_empty():
				log_panel.registrar_evento(
					resultado_estresse["mensagem"],
					"critico"
				)
				if resultado_estresse.has("resultado_fardo"):
					log_panel.registrar_evento(
						resultado_estresse["resultado_fardo"]["mensagem"],
						"critico"
					)

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
			party_panel.atualizar_personagem(
				atacante.para_dictionary()
			)
			_verificar_fim_combate()

		if not combate_ativo:
			return

		_finalizar_acao()
		return

	# ============================================================
	# PROCESSAR SUCESSOS
	# ============================================================

	var sucessos = resultado_combate["total_sucessos"]
	if sucessos <= 0:
		log_panel.registrar_evento(
			"Nenhum sucesso obtido.",
			"info"
		)
	else:
		var protecao_atual = alvo.obter_protecao_atual()
		log_panel.registrar_evento(
			"Proteção de %s: %d/%d" % [
				alvo.nome,
				protecao_atual,
				alvo.atributo_protecao
			],
			"info"
		)
		log_panel.registrar_evento(
			"Sucessos obtidos: %d" % sucessos,
			"info"
		)
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
			var dano_atributo = atacante.atributo_dano
			var dano_arma = 0
			log_panel.registrar_evento(
				"Proteção quebrada!" ,
				"critico"
			)

			log_panel.registrar_evento(
				"Proteção: %d → 0" % protecao_atual,
				"critico"
			)
			if atacante.arma_equipada != "":
				dano_arma = ArmaData.rolar_dano_arma(
					atacante.arma_equipada
				)
			var dano_total = dano_atributo + dano_arma
			log_panel.registrar_evento(
				"Dano Base: %d | Dano Arma: %d | Total: %d" % [
					dano_atributo,
					dano_arma,
					dano_total
				],
				"info"
			)
			alvo.reducao_protecao_temporaria = alvo.atributo_protecao
			if alvo.tipo == "jogador":
				if animacao_jogador != null:
					animacao_jogador.tocar_dano()
			else:
				if animacao_inimigo != null:
					animacao_inimigo.tocar_dano()
			var resultado_estresse = alvo.aplicar_estresse(
				"Torso",
				dano_total
			)
			log_panel.registrar_evento(
				"%s causou %d de estresse em %s." % [
					atacante.nome,
					dano_total,
					alvo.nome
				],
				"dano"
			)
			if not resultado_estresse.is_empty():
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
		"info"
	)
	party_panel.atualizar_personagem(atacante.para_dictionary())
	if alvo.tipo == "jogador":
		party_panel.atualizar_personagem(alvo.para_dictionary())
	var inimigos_atualizado: Array[Dictionary] = []
	for inimigo in combatentes_inimigo:
		enemy_panel.atualizar_inimigo(
		inimigo.para_dictionary()
	)

	if alvo.morto:
		await _derrotar_combatente(alvo)

	if not combate_ativo:
		return

	_finalizar_acao()
	return
func _finalizar_acao() -> void:
	_limpar_dados_visuais()
	acao_em_progresso = false
	regioes_selecionadas.clear()
	enemy_panel.desativar_seletor_alvo()
	action_panel.habilitar_acoes()
	_avancar_turno()

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
	log_panel.registrar_evento(
		"═══ COMBATE FINALIZADO: %s ═══" % resultado,
		"critico"
	)

	combate_finalizado.emit(resultado)

	# TODO: Tela de resultado, experience, loot
	print("[CombatManager] Combate finalizado com resultado: %s" % resultado)
	log_panel.registrar_evento("Retornando ao mapa...", "info")
	_voltar_ao_mapa(resultado)

func _voltar_ao_mapa(resultado: String) -> void:
	action_panel.desabilitar_acoes()
	enemy_panel.desativar_seletor_alvo()

	await get_tree().create_timer(2.5).timeout

	var principal: CombatenteData = GrupoAtual.obter_personagem_principal()
	if principal != null:
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
