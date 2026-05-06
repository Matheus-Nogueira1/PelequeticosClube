extends Node
class_name CombatManager

# Tipos de ações conforme OBLIVIO
enum ActionType {
	ACAO_REGULAR,    # Ação simples (atacar, perícia básica)
	MOVIMENTO,       # Deslocar-se no campo
	EXTRA,           # Ação adicional se houver pontos
	COMPLETA         # Ação que consome tudo
}

# Sinais para comunicação entre painéis
signal turno_iniciado(combatente: Dictionary)
signal turno_finalizado(combatente: Dictionary)
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

# Estado do combate
var combatentes_jogador: Array[Dictionary] = []
var combatentes_inimigo: Array[Dictionary] = []
var ordem_turno: Array[Dictionary] = []
var indice_turno_atual: int = 0
var combatente_ativo: Dictionary = {}
var combate_ativo: bool = false

# Estado da ação atual
var acao_em_progresso: bool = false
var regioes_selecionadas: Array[String] = []
var alvo_selecionado: Dictionary = {}

func _ready() -> void:
	_conectar_sinais_paineis()
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
	
	# Preencher UI dos painéis
	if enemy_panel:
		enemy_panel.atualizar_todos(combatentes_inimigo)
	if party_panel:
		party_panel.atualizar_todos(combatentes_jogador)
	if regional_selector:
		regional_selector.desativar()
	
	# Calcular iniciativa
	_calcular_iniciativa()
	
	# Ordenar by iniciativa
	ordem_turno.sort_custom(func(a, b): return a["iniciativa"] > b["iniciativa"])
	
	combate_ativo = true
	combate_iniciado.emit()
	
	# Começar primeiro turno
	_avancar_turno()

func _setup_exemplo() -> void:
	"""Setup temporário com dados de exemplo"""
	combatentes_jogador = [
		{
			"nome": "Guerreiro",
			"tipo": "jogador",
			"saude_maxima": 15,
			"saude_atual": 15,
			"defesa_base": 2,
			"dano_arma": 2,
			"atributo_dano": 1,
			"estresse_por_regiao": {
				"Torso": 0,
				"Braço Direito": 0,
				"Braço Esquerdo": 0,
				"Perna Direita": 0,
				"Perna Esquerda": 0
			},
			"status": [],
			"iniciativa": 0
		}
	]
	
	combatentes_inimigo = [
		{
			"nome": "Goblin",
			"tipo": "inimigo",
			"saude_maxima": 8,
			"saude_atual": 8,
			"defesa_base": 1,
			"dano_arma": 1,
			"atributo_dano": 0,
			"estresse_por_regiao": {
				"Torso": 0,
				"Braço Direito": 0,
				"Braço Esquerdo": 0,
				"Perna Direita": 0,
				"Perna Esquerda": 0
			},
			"status": [],
			"iniciativa": 0
		}
	]
	
	# Unificar array de combatentes
	var todos = combatentes_jogador + combatentes_inimigo
	ordem_turno = todos.duplicate(true)

func _calcular_iniciativa() -> void:
	"""Cada combatente rola D6 para determinar ordem de turno"""
	for combatente in ordem_turno:
		combatente["iniciativa"] = randi_range(1, 6)
		log_panel.registrar_evento(
			"%s rolou iniciativa: %d" % [combatente["nome"], combatente["iniciativa"]],
			"info"
		)

func _conectar_sinais_paineis() -> void:
	"""Conecta os sinais dos painéis ao CombatManager"""
	if action_panel:
		action_panel.acao_atacar.connect(_iniciar_ataque)
		action_panel.acao_pericia.connect(_iniciar_pericia)
		action_panel.acao_habilidade.connect(_iniciar_habilidade)
		action_panel.acao_item.connect(_iniciar_item)
		action_panel.turno_passado.connect(_on_turno_passado)
	
	if regional_selector:
		regional_selector.regiao_selecionada.connect(_on_regiao_selecionada)
		regional_selector.selecao_confirmada.connect(_on_regioes_confirmadas)
		regional_selector.selecao_cancelada.connect(_on_selecao_cancelada)
	
	if enemy_panel:
		enemy_panel.inimigo_selecionado.connect(_on_inimigo_selecionado)

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
	turno_iniciado.emit(combatente_ativo)
	
	# Ativar painel de ações se for personagem jogador
	if combatente_ativo["tipo"] == "jogador":
		action_panel.ativar_para(combatente_ativo)
		party_panel.indicar_personagem_ativo(combatente_ativo)
		enemy_panel.desativar_seletor_alvo()
		log_panel.registrar_evento(
			"🎯 Turno de %s!" % combatente_ativo["nome"],
			"turno"
		)
		# Limpar seleções apenas ao iniciar turno do jogador
		alvo_selecionado.clear()
	else:
		party_panel.remover_destaque_turno()
		# TODO: IA para inimigos
		await get_tree().create_timer(1.5).timeout
		_executar_turno_inimigo()

func _encontrar_proximo_combatente() -> Dictionary:
	"""Encontra o próximo combatente vivo na ordem"""
	var tentativas = 0
	var max_tentativas = ordem_turno.size() * 2
	
	while tentativas < max_tentativas:
		indice_turno_atual = (indice_turno_atual + 1) % ordem_turno.size()
		var combatente = ordem_turno[indice_turno_atual]
		
		# Verificar se está vivo
		if combatente["saude_atual"] > 0:
			return combatente
		
		tentativas += 1
	
	return {}

func _executar_turno_inimigo() -> void:
	"""Executa turno automático do inimigo (placeholder)"""
	print("[CombatManager] Turno do inimigo: %s" % combatente_ativo["nome"])
	
	# TODO: Implementar IA
	# Por enquanto, passa o turno
	await get_tree().create_timer(1.0).timeout
	turno_finalizado.emit(combatente_ativo)
	_avancar_turno()

# ============================================================================
# AÇÕES DO COMBATENTE
# ============================================================================

func _iniciar_ataque() -> void:
	"""Inicia sequência de ataque: seleciona regiões → seleciona alvo → rola dados"""
	if acao_em_progresso or combatente_ativo["tipo"] != "jogador":
		return
	
	acao_em_progresso = true
	action_panel.desabilitar_acoes()
	log_panel.registrar_evento("Selecione as regiões de ataque...", "acao")
	
	# Ativar seletor de corpo
	regional_selector.ativar_para_ataque()
	regional_selector.modo = "selecionar_ataque"

func _iniciar_pericia() -> void:
	"""Inicia uso de perícia"""
	if acao_em_progresso or combatente_ativo["tipo"] != "jogador":
		return
	
	acao_em_progresso = true
	log_panel.registrar_evento("Menu de perícias aberto...", "acao")
	
	# TODO: Mostrar menu de perícias disponíveis
	action_panel.mostrar_menu_pericias(combatente_ativo)

func _iniciar_habilidade() -> void:
	"""Inicia uso de habilidade especial"""
	if acao_em_progresso or combatente_ativo["tipo"] != "jogador":
		return
	
	acao_em_progresso = true
	log_panel.registrar_evento("Menu de habilidades aberto...", "acao")
	
	# TODO: Mostrar menu de habilidades disponíveis
	action_panel.mostrar_menu_habilidades(combatente_ativo)

func _iniciar_item() -> void:
	"""Inicia uso de item"""
	if acao_em_progresso or combatente_ativo["tipo"] != "jogador":
		return
	
	acao_em_progresso = true
	log_panel.registrar_evento("Menu de itens aberto...", "acao")
	
	# TODO: Mostrar inventário
	action_panel.mostrar_menu_itens(combatente_ativo)

# ============================================================================
# CALLBACKS DE SELEÇÃO
# ============================================================================

func _on_regiao_selecionada(nome_regiao: String, indice: int) -> void:
	"""Chamado quando jogador seleciona uma região de ataque"""
	if nome_regiao not in regioes_selecionadas:
		regioes_selecionadas.append(nome_regiao)
		log_panel.registrar_evento("Região selecionada: %s" % nome_regiao, "info")
	else:
		regioes_selecionadas.erase(nome_regiao)
		log_panel.registrar_evento("Região removida: %s" % nome_regiao, "info")
	
	# Atualiza o jogador para confirmar ou cancelar
	if regioes_selecionadas.size() > 0:
		log_panel.registrar_evento("Confirme as regiões selecionadas ou cancele.", "info")
	else:
		log_panel.registrar_evento("Selecione as regiões de ataque...", "acao")

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
	if not combatente_ativo.is_empty() and combatente_ativo["tipo"] == "jogador":
		log_panel.registrar_evento("Turno passado.", "info")
		action_panel.desabilitar_acoes()
		turno_finalizado.emit(combatente_ativo)
		await get_tree().create_timer(1.0).timeout
		_avancar_turno()

func _on_inimigo_selecionado(inimigo: Dictionary) -> void:
	"""Chamado quando jogador seleciona um inimigo"""
	if regioes_selecionadas.is_empty():
		log_panel.registrar_evento("Nenhuma região selecionada! Confirme antes de selecionar alvo.", "aviso")
		return
	
	if not inimigo.has("nome"):
		log_panel.registrar_evento("Inimigo inválido selecionado!", "aviso")
		return
	
	alvo_selecionado = inimigo
	log_panel.registrar_evento("Alvo selecionado: %s" % inimigo["nome"], "info")
	regional_selector.desativar()
	
	# Proceder com ataque
	_processar_ataque(combatente_ativo, alvo_selecionado, regioes_selecionadas)

# ============================================================================
# PROCESSAMENTO DE ATAQUE
# ============================================================================

func _processar_ataque(atacante: Dictionary, alvo: Dictionary, regioes: Array[String]) -> void:
	"""Executa a lógica de ataque: rola dados, calcula dano, aplica efeitos"""
	print("[CombatManager] Ataque de %s contra %s nas regiões: %s" % [
		atacante["nome"], alvo["nome"], ", ".join(regioes)
	])
	
	# TODO: Implementar sistema de rolagem D6
	# Por enquanto, simulamos um resultado
	var resultado_simulado = {
		"atacante": atacante["nome"],
		"alvo": alvo["nome"],
		"regiao": regioes[0],
		"dado": randi_range(1, 6),
		"categoria": _avaliar_categoria_resultado(randi_range(1, 6)),
		"dano_aplicado": 2,
		"estresse_gerado": 1
	}
	
	log_panel.registrar_ataque(resultado_simulado)
	
	# Aplicar dano ao alvo
	alvo["saude_atual"] = max(0, alvo["saude_atual"] - resultado_simulado["dano_aplicado"])
	
	# Aplicar estresse ao alvo
	if resultado_simulado["estresse_gerado"] > 0:
		for regiao in regioes:
			alvo["estresse_por_regiao"][regiao] += resultado_simulado["estresse_gerado"]
	
	# Sincronizar atualização nos painéis
	enemy_panel.atualizar_inimigo(alvo)
	enemy_panel.desativar_seletor_alvo()
	estado_atualizado.emit()
	
	# Verificar se alvo morreu
	if alvo["saude_atual"] <= 0:
		_derrotar_combatente(alvo)
	else:
		# Permitir próxima ação ou finalizar turno
		acao_em_progresso = false
		regioes_selecionadas.clear()
		action_panel.habilitar_acoes()
		log_panel.registrar_evento("Ação pronta. Escolha a próxima ação ou passe o turno.", "info")

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

func _derrotar_combatente(combatente: Dictionary) -> void:
	"""Remove combatente derrotado e verifica fim de combate"""
	log_panel.registrar_evento(
		"⚠️  %s foi derrotado!" % combatente["nome"],
		"critico"
	)
	
	combatente["saude_atual"] = 0
	
	# Sincronizar remoção nos painéis
	if combatente["tipo"] == "inimigo":
		enemy_panel.remover_inimigo(combatente)
	else:
		party_panel.remover_personagem(combatente)
	
	estado_atualizado.emit()
	
	# Verificar se combate acabou
	_verificar_fim_combate()

func _verificar_fim_combate() -> void:
	"""Verifica se um dos lados foi completamente derrotado"""
	var jogadores_vivos = combatentes_jogador.filter(func(c): return c["saude_atual"] > 0)
	var inimigos_vivos = combatentes_inimigo.filter(func(c): return c["saude_atual"] > 0)
	
	if jogadores_vivos.is_empty():
		_finalizar_combate("Derrota")
	elif inimigos_vivos.is_empty():
		_finalizar_combate("Vitória")
	else:
		# Continuar combate normalmente - próxima ação ou próximo turno
		if combatente_ativo["tipo"] == "jogador":
			action_panel.habilitar_acoes()
			log_panel.registrar_evento("Escolha a próxima ação ou passe o turno.", "info")

func _finalizar_combate(resultado: String) -> void:
	"""Encerra o combate e retorna ao menu/mapa"""
	combate_ativo = false
	log_panel.registrar_evento(
		"═══ COMBATE FINALIZADO: %s ═══" % resultado,
		"critico"
	)
	
	combate_finalizado.emit(resultado)
	
	# TODO: Tela de resultado, experience, loot
	print("[CombatManager] Combate finalizado com resultado: %s" % resultado)

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
