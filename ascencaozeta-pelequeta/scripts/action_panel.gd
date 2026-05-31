extends PanelContainer
class_name ActionPanel

# Sinais para comunicação com CombatManager
signal acao_atacar
signal acao_pericia
signal acao_habilidade
signal acao_item
signal turno_passado
signal habilidade_sobrecarga

# Referências aos botões
@onready var vbox = VBoxContainer.new()
var botao_atacar: Button
var botao_pericia: Button
var botao_habilidade: Button
var botao_item: Button

# Menus popup
var menu_pericias: PopupMenu
var menu_habilidades: PopupMenu

var combatente_ativo: Dictionary = {}
var combatente_ref: CombatenteData = null
var acoes_habilitadas: bool = false

func _ready() -> void:
	_criar_layout()
	_criar_menus_popup()
	desabilitar_acoes()

# ============================================================================
# CRIAÇÃO DA UI
# ============================================================================

func _criar_layout() -> void:
	"""Cria o layout dos botões de ação"""
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)
	
	# ATACAR
	botao_atacar = _criar_botao(
		"⚔️  ATACAR",
		"Selecione regiões e alvo",
		_on_atacar_pressionado
	)
	vbox.add_child(botao_atacar)
	
	# PERÍCIA
	botao_pericia = _criar_botao(
		"✨ PERÍCIA",
		"Habilidades treinadas",
		_on_pericia_pressionado
	)
	vbox.add_child(botao_pericia)
	
	# HABILIDADE
	botao_habilidade = _criar_botao(
		"💥 HABILIDADE",
		"Poderes especiais",
		_on_habilidade_pressionada
	)
	vbox.add_child(botao_habilidade)
	
	# ITEM
	botao_item = _criar_botao(
		"🎒 ITEM",
		"Usar do inventário",
		_on_item_pressionado
	)
	vbox.add_child(botao_item)
	
	# Espaçador
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	vbox.add_child(spacer)
	
	# PASSAR TURNO (sempre disponível)
	var botao_passar = _criar_botao(
		"➡️  PASSAR TURNO",
		"Finaliza o turno",
		_on_passar_turno
	)
	vbox.add_child(botao_passar)

func _criar_botao(texto: String, tooltip_text: String, callback: Callable) -> Button:
	"""Helper para criar botões com estilo padrão"""
	var btn = Button.new()
	btn.text = texto
	btn.tooltip_text = tooltip_text
	btn.pressed.connect(callback)
	btn.custom_minimum_size = Vector2(0, 32)
	return btn

func _criar_menus_popup() -> void:
	"""Cria os PopupMenus para perícias e habilidades"""
	menu_pericias = PopupMenu.new()
	add_child(menu_pericias)
	menu_pericias.index_pressed.connect(_on_pericia_selecionada)
	
	menu_habilidades = PopupMenu.new()
	add_child(menu_habilidades)
	menu_habilidades.index_pressed.connect(_on_habilidade_selecionada)

# ============================================================================
# ATIVAÇÃO/DESATIVAÇÃO
# ============================================================================

func ativar_para(combatente: Dictionary, ref_combatente: CombatenteData = null) -> void:
	"""Ativa o painel de ações para um combatente específico"""
	combatente_ativo = combatente
	combatente_ref = ref_combatente
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	habilitar_acoes()
	
	# Mostrar informações do combatente
	print("[ActionPanel] Ativado para: %s" % combatente["nome"])

func habilitar_acoes() -> void:
	"""Habilita todos os botões de ação"""
	acoes_habilitadas = true
	botao_atacar.disabled = false
	botao_pericia.disabled = false
	botao_habilidade.disabled = false
	botao_item.disabled = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true

func desabilitar_acoes() -> void:
	"""Desabilita todos os botões de ação"""
	acoes_habilitadas = false
	botao_atacar.disabled = true
	botao_pericia.disabled = true
	botao_habilidade.disabled = true
	botao_item.disabled = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

# ============================================================================
# CALLBACKS DOS BOTÕES
# ============================================================================

func _on_atacar_pressionado() -> void:
	"""Callback do botão ATACAR"""
	desabilitar_acoes()
	acao_atacar.emit()

func _on_pericia_pressionado() -> void:
	"""Callback do botão PERÍCIA"""
	desabilitar_acoes()
	acao_pericia.emit()

func _on_habilidade_pressionada() -> void:
	"""Callback do botão HABILIDADE"""
	desabilitar_acoes()
	acao_habilidade.emit()

func _on_item_pressionado() -> void:
	"""Callback do botão ITEM"""
	desabilitar_acoes()
	acao_item.emit()

func _on_passar_turno() -> void:
	"""Callback do botão PASSAR TURNO - finaliza o turno"""
	print("[ActionPanel] Turno passado")
	turno_passado.emit()

# ============================================================================
# MENUS ESPECÍFICOS (Stubs para implementação futura)
# ============================================================================

func mostrar_menu_pericias(combatente: Dictionary) -> void:
	"""Mostra menu de perícias disponíveis"""
	if combatente_ref == null:
		print("[ActionPanel] Combatente não possui referência")
		return
	
	menu_pericias.clear()
	
	# Preencher menu com perícias treinadas (nível > 0)
	var index = 0
	for pericia in combatente_ref.conhecimentos_treino.keys():
		var nivel = combatente_ref.conhecimentos_treino[pericia]
		if nivel > 0:
			menu_pericias.add_item("%s (Nível %d)" % [pericia, nivel], index)
			index += 1
	
	if index == 0:
		menu_pericias.add_item("[Nenhuma perícia treinada]", 0)
		menu_pericias.set_item_disabled(0, true)
	
	# Exibir menu centralizado
	menu_pericias.popup_centered_ratio(0.3)
	print("[ActionPanel] Menu de perícias para %s" % combatente["nome"])

func mostrar_menu_habilidades(combatente: Dictionary) -> void:
	"""Mostra menu de habilidades disponíveis, separadas por tipo"""
	if combatente_ref == null:
		print("[ActionPanel] Combatente não possui referência")
		return
	
	menu_habilidades.clear()
	
	# Preencher menu com habilidades classificadas
	var index = 0
	
	# PRINCIPAL
	var habilidades_principal = HabilidadeData.obter_habilidades_por_tipo(
		combatente_ref.habilidades,
		HabilidadeData.TipoHabilidade.PRINCIPAL
	)
	if habilidades_principal.size() > 0:
		menu_habilidades.add_item("[HABILIDADE PRINCIPAL]", index)
		menu_habilidades.set_item_disabled(index, true)
		index += 1
		for hab in habilidades_principal:
			menu_habilidades.add_item("  %s" % hab, index)
			index += 1
		menu_habilidades.add_separator()
		index += 1
	
	# ÚNICA
	var habilidades_unica = HabilidadeData.obter_habilidades_por_tipo(
		combatente_ref.habilidades,
		HabilidadeData.TipoHabilidade.UNICA
	)
	if habilidades_unica.size() > 0:
		menu_habilidades.add_item("[HABILIDADES ÚNICAS]", index)
		menu_habilidades.set_item_disabled(index, true)
		index += 1
		for hab in habilidades_unica:
			menu_habilidades.add_item("  %s" % hab, index)
			index += 1
		menu_habilidades.add_separator()
		index += 1
	
	# GERAL
	var habilidades_geral = HabilidadeData.obter_habilidades_por_tipo(
		combatente_ref.habilidades,
		HabilidadeData.TipoHabilidade.GERAL
	)
	if habilidades_geral.size() > 0:
		menu_habilidades.add_item("[HABILIDADES GERAIS]", index)
		menu_habilidades.set_item_disabled(index, true)
		index += 1
		for hab in habilidades_geral:
			menu_habilidades.add_item("  %s" % hab, index)
			index += 1
	
	# Sobrecarga (Ir Além) especial
	if combatente_ref.habilidade_sobrecarga_ativa:
		menu_habilidades.add_separator()
		menu_habilidades.add_item("⚡ SOBRECARGA (Ir Além)", index)
		index += 1
	
	if index == 0:
		menu_habilidades.add_item("[Nenhuma habilidade disponível]", 0)
		menu_habilidades.set_item_disabled(0, true)
	
	# Exibir menu centralizado
	menu_habilidades.popup_centered_ratio(0.35)
	print("[ActionPanel] Menu de habilidades para %s" % combatente["nome"])

func mostrar_menu_itens(combatente: Dictionary) -> void:
	"""Mostra menu de itens do inventário"""
	if combatente_ref == null:
		print("[ActionPanel] Combatente não possui referência")
		return
	
	print("[ActionPanel] Menu de itens para %s" % combatente["nome"])
	# TODO: Criar menu de seleção de itens
	# TODO: Exibir custo de ação de cada item
	# TODO: Mostrar quantidade disponível
	# TODO: Retornar item selecionado ao CombatManager

func _on_pericia_selecionada(index: int) -> void:
	"""Callback quando uma perícia é selecionada"""
	var pericia_nome = menu_pericias.get_item_text(index)
	print("[ActionPanel] Perícia selecionada: %s" % pericia_nome)
	habilitar_acoes()

func _on_habilidade_selecionada(index: int) -> void:
	var habilidade_nome = menu_habilidades.get_item_text(index).strip_edges()
	if habilidade_nome.contains("SOBRECARGA"):
		habilidade_sobrecarga.emit()
		return
	print("[ActionPanel] Habilidade selecionada: %s" % habilidade_nome)
	habilitar_acoes()
