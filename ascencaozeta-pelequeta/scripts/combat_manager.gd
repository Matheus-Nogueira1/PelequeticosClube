extends Node
class_name CombatManager

# Importações
const RolagemDadosD6 = preload("res://scripts/rolagens-dados-d6.gd")

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

# Estado do combate
var combatentes_jogador: Array[CombatenteData] = []
var combatentes_inimigo: Array[CombatenteData] = []
var ordem_turno: Array[CombatenteData] = []
var indice_turno_atual := -1
var combatente_ativo: CombatenteData = null
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
	"""Setup temporário com dados de exemplo usando CombatenteData"""
	
	# Criar os 3 personagens principais
	var mob = PersonagensData.criar_mob()
	var escolhido = PersonagensData.criar_escolhido()
	var jp = PersonagensData.criar_JP()
	
	combatentes_jogador = [mob, escolhido, jp]
	
	# Criar inimigos usando templates
	combatentes_inimigo = [
		InimigoData.criar_carcaca()
	]
	
	# Unificar array de combatentes
	var todos = combatentes_jogador + combatentes_inimigo
	ordem_turno = todos.duplicate()

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
		action_panel.acao_pericia.connect(_iniciar_pericia)
		action_panel.acao_habilidade.connect(_iniciar_habilidade)
		action_panel.acao_item.connect(_iniciar_item)
		action_panel.turno_passado.connect(_on_turno_passado)
		action_panel.habilidade_sobrecarga.connect(_ativar_sobrecarga)
	
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
		# TODO: IA para inimigos
		await get_tree().create_timer(1.5).timeout
		_executar_turno_inimigo()

func _encontrar_proximo_combatente() -> CombatenteData:
	"""Encontra o próximo combatente vivo na ordem"""
	var tentativas = 0
	var max_tentativas = ordem_turno.size() * 2
	
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
	await get_tree().create_timer(1.0).timeout
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

func _iniciar_pericia() -> void:
	"""Inicia uso de perícia"""
	if acao_em_progresso or combatente_ativo.tipo != "jogador":
		return
	
	acao_em_progresso = true
	log_panel.registrar_evento("Menu de perícias aberto...", "acao")
	
	# TODO: Mostrar menu de perícias disponíveis
	action_panel.mostrar_menu_pericias(combatente_ativo.para_dictionary())

func _iniciar_habilidade() -> void:
	"""Inicia uso de habilidade especial"""
	if acao_em_progresso or combatente_ativo.tipo != "jogador":
		return
	
	acao_em_progresso = true
	log_panel.registrar_evento("Menu de habilidades aberto...", "acao")
	
	# TODO: Mostrar menu de habilidades disponíveis
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

func _iniciar_item() -> void:
	"""Inicia uso de item"""
	if acao_em_progresso or combatente_ativo.tipo != "jogador":
		return
	
	acao_em_progresso = true
	log_panel.registrar_evento("Menu de itens aberto...", "acao")
	
	# TODO: Mostrar inventário
	action_panel.mostrar_menu_itens(combatente_ativo.para_dictionary())

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
	"""Chamado quando jogador seleciona um inimigo"""
	if regioes_selecionadas.is_empty():
		log_panel.registrar_evento("Nenhuma região selecionada! Confirme antes de selecionar alvo.", "aviso")
		return
	
	if not inimigo_dict.has("nome"):
		log_panel.registrar_evento("Inimigo inválido selecionado!", "aviso")
		return
	
	# Encontrar o CombatenteData correspondente
	var alvo = null
	for inimigo in combatentes_inimigo:
		if inimigo.nome == inimigo_dict["nome"]:
			alvo = inimigo
			break
	
	if not alvo:
		log_panel.registrar_evento("Inimigo não encontrado!", "aviso")
		return
	
	alvo_selecionado = alvo.para_dictionary()
	log_panel.registrar_evento("Alvo selecionado: %s" % alvo.nome, "info")
	regional_selector.desativar()
	
	# Proceder com ataque
	_processar_ataque(combatente_ativo, alvo, regioes_selecionadas)

# ============================================================================
# PROCESSAMENTO DE ATAQUE
# ============================================================================

func _processar_ataque(atacante: CombatenteData, alvo: CombatenteData, regioes: Array[String]) -> void:
	"""Executa a lógica de ataque: rola dados D6, calcula dano, aplica efeitos (mesma lógica do seletor)"""
	
	# Usar RolagemDadosD6 para teste de combate (como no seletor-corpo.gd)
	var rolagem = RolagemDadosD6.new()
	var resultado_combate = rolagem.rolar_teste_combate_d6(
		regioes,
		2,  # protecao_alvo (padrão)
		2,  # dano_arma (padrão)
		atacante.atributo_dano
	)
	
	# Log detalhado de cada região - aplicar efeitos
	for res_regiao in resultado_combate["resultados_por_regiao"]:
		var mensagem = "Região: %s → D6: %d (%s)" % [
			res_regiao["regiao"],
			res_regiao["dado"],
			res_regiao["categoria"]
		]
		log_panel.registrar_evento(mensagem, "ataque")
		
		# FALHA: Apenas o atacante sofre (arriscou e perdeu)
		if res_regiao["categoria"] in ["Falha Regular", "Falha Crítica"]:
			var estresse_gerado = 2 if res_regiao["categoria"] == "Falha Crítica" else 1
			atacante.aplicar_estresse(res_regiao["regiao"], estresse_gerado)
			log_panel.registrar_evento("%s sofre %d de estresse em %s (ataque falhou)" % [
				atacante.nome, estresse_gerado, res_regiao["regiao"]
			], "aviso")
		
		# SUCESSO: Alvo sofre estresse (defesa falhou)
		elif res_regiao["categoria"] in ["Sucesso Regular", "Sucesso Extremo"]:
			var estresse_gerado = 1 if res_regiao["categoria"] == "Sucesso Regular" else 2
			alvo.aplicar_estresse(res_regiao["regiao"], estresse_gerado)
			log_panel.registrar_evento("%s sofre %d de estresse em %s (defesa falhou)" % [
				alvo.nome, estresse_gerado, res_regiao["regiao"]
			], "dano")
	
	# Resumo do ataque
	log_panel.registrar_evento("Sucessos: %d | Falhas: %d (simples: %d, críticas: %d)" % [
		resultado_combate["total_sucessos"],
		resultado_combate["falhas_regulares"] + resultado_combate["falhas_criticas"],
		resultado_combate["falhas_regulares"],
		resultado_combate["falhas_criticas"]
	], "info")
	
	# Atualizar painéis (tanto atacante quanto alvo)
	party_panel.atualizar_personagem(atacante.para_dictionary())
	party_panel.atualizar_personagem(alvo.para_dictionary())
	var inimigos_atualizado: Array[Dictionary] = []
	inimigos_atualizado.append(alvo.para_dictionary())
	enemy_panel.atualizar_todos(inimigos_atualizado)
	
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
	"""Remove combatente derrotado e verifica fim de combate"""
	
	log_panel.registrar_evento(
		"⚠️  %s foi derrotado!" % combatente.nome,
		"critico"
	)
	
	# Sincronizar remoção nos painéis
	if combatente.tipo == "inimigo":
		enemy_panel.remover_inimigo(combatente.para_dictionary())
	else:
		party_panel.remover_personagem(combatente.para_dictionary())
	
	estado_atualizado.emit()
	
	# Verificar se combate acabou
	_verificar_fim_combate()

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
	else:
		# Continuar combate normalmente - próxima ação ou próximo turno
		if combatente_ativo.tipo == "jogador":
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
