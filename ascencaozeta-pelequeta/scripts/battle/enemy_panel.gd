extends PanelContainer
class_name EnemyPanel

## PAINEL DE INIMIGOS
## Mostra lista dos inimigos com:
## - Nome de cada inimigo
## - Estresse total com barra visual (░▓▓▓▓░░░)
## - Botões para selecionar alvo em combate
## - Atualização em tempo real quando sofrem dano

## ===== SINAIS =====

## Emitido quando um inimigo é selecionado como alvo
signal alvo_selecionado(alvo: CombatenteData)
signal alvo_deselecionado
## Emitido quando um inimigo é deseleccionado
signal inimigo_deseleccionado

# UI
@onready var vbox = VBoxContainer.new()
@onready var label_titulo = Label.new()
@onready var scroll_container = ScrollContainer.new()
@onready var lista_combatentes = VBoxContainer.new()

var combatentes: Array[CombatenteData] = []
var botoes_alvos: Dictionary = {}
var alvo_selecionado_atual: CombatenteData = null
var modo_seletor_ativo: bool = false
enum TipoAlvo{
	INIMIGO,
	ALIADO,
	QUALQUER
}

var tipo_alvo := TipoAlvo.INIMIGO

## Monta o painel e deixa a seleção de alvos inicialmente bloqueada.
func _ready() -> void:
	_criar_layout()

# ============================================================================
# CRIAÇÃO DA UI
# ============================================================================
## Cria o título, a lista rolável e o estado inicial do painel.
func _criar_layout() -> void:
	"""Cria o layout do painel de inimigos"""
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(vbox)
	
	# Título
	label_titulo.text = "Inimigos"
	label_titulo.add_theme_font_size_override("font_size", 18)
	label_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(label_titulo)
	
	# Container de scroll para lista
	scroll_container.custom_minimum_size = Vector2(0, 300)
	scroll_container.clip_contents = true
	scroll_container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	lista_combatentes.add_theme_constant_override("separation", 2)
	lista_combatentes.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll_container.add_child(lista_combatentes)
	
	vbox.add_child(scroll_container)
	
	# Começar desativado
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# ============================================================================
# GERENCIAMENTO DE INIMIGOS
# ============================================================================
## Adiciona um combatente à lista visual de inimigos.
func adicionar_combatente(combatente: CombatenteData) -> void:
	"""Adiciona um inimigo à lista"""
	combatentes.append(combatente)
	_criar_botao_combatente(combatente)

## Atualiza o texto do inimigo existente sem recriar sua lista.
func atualizar_combatente(combatente: CombatenteData) -> void:
	var chave = combatente.nome
	for i in range(combatentes.size()):
		if combatentes[i].nome == chave:
			combatentes[i] = combatente
			break
	if chave in botoes_alvos:
		var botao = botoes_alvos[chave]
		botao.text = _formatar_texto_combatente(combatente)
## Remove um inimigo derrotado e limpa sua referência de seleção.
func remover_combatente(combatente: CombatenteData) -> void:
	"""Remove um inimigo da lista (quando derrotado)"""
	var chave = combatente.nome
	if chave in botoes_alvos:
		botoes_alvos[chave].queue_free()
		botoes_alvos.erase(chave)
	
	combatentes = combatentes.filter(func(i): return i.nome != chave)
	
	if alvo_selecionado_atual == combatente:
		alvo_selecionado_atual = null

## Remove todos os botões e limpa o alvo atualmente selecionado.
func limpar_combatente() -> void:
	for botao in botoes_alvos.values():
		botao.queue_free()
	botoes_alvos.clear()
	alvo_selecionado_atual = null

# ============================================================================
# CRIAÇÃO DE BOTÕES
# ============================================================================
func _criar_botao_combatente(inimigo: CombatenteData) -> void:
	"""Cria um botão visual para um inimigo"""
	var botao = Button.new()
	botao.add_theme_font_size_override(
	"font_size",
	20
	)
	botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
	botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	botao.text = _formatar_texto_combatente(inimigo)
	botao.custom_minimum_size = Vector2(0, 120)
	botao.toggle_mode = true
	botao.mouse_filter = Control.MOUSE_FILTER_STOP
	botao.pressed.connect(_on_botao_combatente_pressionado.bind(inimigo))
	
	lista_combatentes.add_child(botao)
	botoes_alvos[inimigo.nome] = botao

## Formata estresse, proteção e estado de análise para exibição no botão.
func _formatar_texto_combatente(combatente: CombatenteData) -> String:
	var nome = combatente.nome

	var estresse_total := 0
	var limite_total := 0
	var analisado := combatente.analisado_por_duelo
	if not analisado:

		for regiao_data in combatente.estresse_por_regiao.values():
			estresse_total += regiao_data.atual
			limite_total += regiao_data.limite
		var barra = _criar_barra_estresse(
			estresse_total,
			limite_total
		)
		return """
	%s

	ESTRESSE %d/%d
	%s

	PROTEÇÃO ???

	Torso ............. ??/?
	Braço Direito ..... ??/?
	Braço Esquerdo .... ??/?
	Perna Direita ..... ??/?
	Perna Esquerda .... ??/?
	""" % [
			nome,
			estresse_total,
			limite_total,
			barra
		]
	for regiao_data in combatente.estresse_por_regiao.values():
		estresse_total += regiao_data.atual
		limite_total += regiao_data.limite
	var barra = _criar_barra_estresse(
		estresse_total,
		limite_total
	)
	var protecao_base: int = combatente.atributo_protecao
	var reducao := combatente.reducao_protecao_temporaria
	var protecao_atual: int = max(
		0,
		protecao_base - reducao
	)
	var torso = combatente.estresse_por_regiao["Torso"]
	var bd = combatente.estresse_por_regiao["Braço Direito"]
	var be = combatente.estresse_por_regiao["Braço Esquerdo"]
	var pd = combatente.estresse_por_regiao["Perna Direita"]
	var pe = combatente.estresse_por_regiao["Perna Esquerda"]

	return """
%s

ESTRESSE %d/%d
%s

PROTEÇÃO %d/%d

Torso ............. %d/%d
Braço Direito ..... %d/%d
Braço Esquerdo .... %d/%d
Perna Direita ..... %d/%d
Perna Esquerda .... %d/%d
""" % [
		nome,
		estresse_total,
		limite_total,
		barra,
		protecao_atual,
		protecao_base,
		torso["atual"], torso["limite"],
		bd["atual"], bd["limite"],
		be["atual"], be["limite"],
		pd["atual"], pd["limite"],
		pe["atual"], pe["limite"]
	]
## Gera uma barra textual de saúde com dez posições.
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

## Gera uma barra textual de estresse com dez posições preenchidas.
func _criar_barra_estresse(atual: int, maximo: int) -> String:
	"""Cria uma barra de estresse em texto ASCII"""
	var tamanho_barra = 10
	var blocos_cheios = int((float(atual) / float(maximo)) * tamanho_barra)
	blocos_cheios = clampi(blocos_cheios, 0, tamanho_barra)
	
	var barra = ""
	for i in range(tamanho_barra):
		if i < blocos_cheios:
			barra += "▓"  # Blocos mais densos para estresse
		else:
			barra += "░"
	
	return barra

# ============================================================================
# SELEÇÃO DE ALVO
# ============================================================================
## Ativa o modo de seleção para a lista de alvos recebida.
func ativar_seletor_alvo(
	alvos_recebidos: Array[CombatenteData],
	tipo: TipoAlvo = TipoAlvo.INIMIGO
) -> void:
	## Ativa os botões recebidos e define se o alvo será inimigo, aliado ou qualquer.
	if combatentes.is_empty():
		atualizar_todos(alvos_recebidos)
	tipo_alvo = tipo
	match tipo_alvo:
		TipoAlvo.INIMIGO:
			label_titulo.text = "Inimigos"

		TipoAlvo.ALIADO:
			label_titulo.text = "Aliados"

		TipoAlvo.QUALQUER:
			label_titulo.text = "Selecionar alvo"

	modo_seletor_ativo = true

	mouse_filter = Control.MOUSE_FILTER_STOP

	for botao in botoes_alvos.values():
		botao.focus_mode = Control.FOCUS_ALL

	await get_tree().process_frame

	if botoes_alvos.size() > 0:
		botoes_alvos.values()[0].grab_focus()
## Desativa a seleção e desfaz as marcações dos botões.
func desativar_seletor_alvo() -> void:
	"""Desativa o modo de seleção de alvo"""
	modo_seletor_ativo = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Desmarcar todos
	for botao in botoes_alvos.values():
		botao.button_pressed = false
		botao.mouse_filter = Control.MOUSE_FILTER_IGNORE

## Emite o alvo clicado e encerra o modo de seleção após a escolha.
func _on_botao_combatente_pressionado(alvo: CombatenteData) -> void:

	if not modo_seletor_ativo:
		return

	if alvo_selecionado_atual != null:

		var anterior = botoes_alvos.get(
			alvo_selecionado_atual.nome
		)

		if anterior:
			anterior.button_pressed = false

	alvo_selecionado_atual = alvo

	alvo_selecionado.emit(alvo)

	desativar_seletor_alvo()
## Retorna o inimigo atualmente selecionado, se houver.
func obter_alvo_selecionado() -> CombatenteData:
	return alvo_selecionado_atual

# ============================================================================
# ATUALIZAÇÃO E SINCRONIZAÇÃO
# ============================================================================
## Substitui a lista atual e recria todos os botões de inimigos.
func atualizar_todos(combatentes_novos: Array[CombatenteData]) -> void:
	"""Atualiza toda a lista de inimigos"""
	limpar_combatente()
	combatentes.clear()
	for combatente in combatentes_novos:
		adicionar_combatente(combatente)
