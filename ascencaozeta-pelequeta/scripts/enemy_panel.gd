extends PanelContainer
class_name EnemyPanel

# Sinais para comunicação com CombatManager
signal inimigo_selecionado(inimigo: Dictionary)
signal inimigo_deseleccionado

# UI
@onready var vbox = VBoxContainer.new()
@onready var label_titulo = Label.new()
@onready var scroll_container = ScrollContainer.new()
@onready var lista_inimigos = VBoxContainer.new()

var inimigos: Array[Dictionary] = []
var botoes_inimigos: Dictionary = {}  # nome -> botão
var inimigo_selecionado_atual: Dictionary = {}
var modo_seletor_ativo: bool = false

func _ready() -> void:
	_criar_layout()

# ============================================================================
# CRIAÇÃO DA UI
# ============================================================================

func _criar_layout() -> void:
	"""Cria o layout do painel de inimigos"""
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(vbox)
	
	# Título
	label_titulo.text = "Inimigos"
	label_titulo.add_theme_font_size_override("font_size", 14)
	label_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(label_titulo)
	
	# Container de scroll para lista
	scroll_container.custom_minimum_size = Vector2(0, 200)
	scroll_container.clip_contents = true
	scroll_container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	lista_inimigos.add_theme_constant_override("separation", 2)
	lista_inimigos.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll_container.add_child(lista_inimigos)
	
	vbox.add_child(scroll_container)
	
	# Começar desativado
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# ============================================================================
# GERENCIAMENTO DE INIMIGOS
# ============================================================================

func adicionar_inimigo(inimigo: Dictionary) -> void:
	"""Adiciona um inimigo à lista"""
	inimigos.append(inimigo)
	_criar_botao_inimigo(inimigo)

func atualizar_inimigo(inimigo: Dictionary) -> void:
	"""Atualiza o visual de um inimigo existente"""
	var chave = inimigo["nome"]
	if chave in botoes_inimigos:
		var botao = botoes_inimigos[chave]
		botao.text = _formatar_texto_inimigo(inimigo)

func remover_inimigo(inimigo: Dictionary) -> void:
	"""Remove um inimigo da lista (quando derrotado)"""
	var chave = inimigo["nome"]
	if chave in botoes_inimigos:
		botoes_inimigos[chave].queue_free()
		botoes_inimigos.erase(chave)
	
	inimigos = inimigos.filter(func(i): return i["nome"] != chave)
	
	if inimigo_selecionado_atual == inimigo:
		inimigo_selecionado_atual.clear()

func limpar_inimigos() -> void:
	"""Remove todos os inimigos da lista"""
	for botao in botoes_inimigos.values():
		botao.queue_free()
	botoes_inimigos.clear()
	inimigos.clear()
	inimigo_selecionado_atual.clear()

# ============================================================================
# CRIAÇÃO DE BOTÕES
# ============================================================================

func _criar_botao_inimigo(inimigo: Dictionary) -> void:
	"""Cria um botão visual para um inimigo"""
	var botao = Button.new()
	botao.text = _formatar_texto_inimigo(inimigo)
	botao.custom_minimum_size = Vector2(0, 36)
	botao.toggle_mode = true
	botao.mouse_filter = Control.MOUSE_FILTER_STOP
	botao.pressed.connect(_on_botao_inimigo_pressionado.bind(inimigo))
	
	lista_inimigos.add_child(botao)
	botoes_inimigos[inimigo["nome"]] = botao

func _formatar_texto_inimigo(inimigo: Dictionary) -> String:
	"""Formata o texto que aparece no botão do inimigo"""
	var saude = inimigo["saude_atual"]
	var saude_max = inimigo["saude_maxima"]
	var barra_saude = _criar_barra_saude(saude, saude_max)
	
	return "%s  HP: %d/%d  [%s]" % [
		inimigo["nome"],
		saude,
		saude_max,
		barra_saude
	]

func _criar_barra_saude(atual: int, maximo: int) -> String:
	"""Cria uma barra de saúde em texto ASCII"""
	var tamanho_barra = 10
	var blocos_cheios = int((float(atual) / float(maximo)) * tamanho_barra)
	blocos_cheios = clampi(blocos_cheios, 0, tamanho_barra)
	
	var barra = ""
	for i in range(tamanho_barra):
		if i < blocos_cheios:
			barra += "█"
		else:
			barra += "░"
	
	return barra

# ============================================================================
# SELEÇÃO DE ALVO
# ============================================================================

func ativar_seletor_alvo() -> void:
	"""Ativa o modo de seleção de alvo"""
	modo_seletor_ativo = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Destacar todos os botões como selecionáveis
	for botao in botoes_inimigos.values():
		botao.disabled = false
		botao.toggle_mode = true
		botao.mouse_filter = Control.MOUSE_FILTER_STOP

func desativar_seletor_alvo() -> void:
	"""Desativa o modo de seleção de alvo"""
	modo_seletor_ativo = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Desmarcar todos
	for botao in botoes_inimigos.values():
		botao.button_pressed = false
		botao.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_botao_inimigo_pressionado(inimigo: Dictionary) -> void:
	"""Chamado quando um botão de inimigo é pressionado"""
	if not modo_seletor_ativo:
		return
	
	# Desselecionar inimigo anterior
	if inimigo_selecionado_atual.has("nome"):
		var botao_anterior = botoes_inimigos.get(inimigo_selecionado_atual["nome"])
		if botao_anterior:
			botao_anterior.button_pressed = false
	
	# Selecionar novo inimigo
	inimigo_selecionado_atual = inimigo
	inimigo_selecionado.emit(inimigo)
	
	# Desativar seletor após seleção
	desativar_seletor_alvo()

func obter_inimigo_selecionado() -> Dictionary:
	"""Retorna o inimigo atualmente selecionado"""
	return inimigo_selecionado_atual

# ============================================================================
# ATUALIZAÇÃO E SINCRONIZAÇÃO
# ============================================================================

func atualizar_todos(inimigos_novos: Array[Dictionary]) -> void:
	"""Atualiza toda a lista de inimigos"""
	limpar_inimigos()
	
	for inimigo in inimigos_novos:
		adicionar_inimigo(inimigo)
