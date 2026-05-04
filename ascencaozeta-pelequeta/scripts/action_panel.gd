extends PanelContainer
class_name ActionPanel

# Sinais para comunicação com CombatManager
signal acao_atacar
signal acao_pericia
signal acao_habilidade
signal acao_item

# Referências aos botões
@onready var vbox = VBoxContainer.new()
var botao_atacar: Button
var botao_pericia: Button
var botao_habilidade: Button
var botao_item: Button

var combatente_ativo: Dictionary = {}
var acoes_habilitadas: bool = false

func _ready() -> void:
	_criar_layout()
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

# ============================================================================
# ATIVAÇÃO/DESATIVAÇÃO
# ============================================================================

func ativar_para(combatente: Dictionary) -> void:
	"""Ativa o painel de ações para um combatente específico"""
	combatente_ativo = combatente
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
	"""Callback do botão PASSAR - não desabilita"""
	print("[ActionPanel] Turno passado")
	# Aqui a lógica de passar turno será adicionada
	# junto com o sistema de custos de ação

# ============================================================================
# MENUS ESPECÍFICOS (Stubs para implementação futura)
# ============================================================================

func mostrar_menu_pericias(combatente: Dictionary) -> void:
	"""Mostra menu de perícias disponíveis"""
	print("[ActionPanel] Menu de perícias para %s" % combatente["nome"])
	# TODO: Criar menu de seleção de perícias
	# TODO: Exibir custo de ação de cada perícia
	# TODO: Retornar perícia selecionada ao CombatManager

func mostrar_menu_habilidades(combatente: Dictionary) -> void:
	"""Mostra menu de habilidades disponíveis"""
	print("[ActionPanel] Menu de habilidades para %s" % combatente["nome"])
	# TODO: Criar menu de seleção de habilidades
	# TODO: Exibir custo de ação de cada habilidade
	# TODO: Retornar habilidade selecionada ao CombatManager

func mostrar_menu_itens(combatente: Dictionary) -> void:
	"""Mostra menu de itens do inventário"""
	print("[ActionPanel] Menu de itens para %s" % combatente["nome"])
	# TODO: Criar menu de seleção de itens
	# TODO: Exibir custo de ação de cada item
	# TODO: Mostrar quantidade disponível
	# TODO: Retornar item selecionado ao CombatManager
