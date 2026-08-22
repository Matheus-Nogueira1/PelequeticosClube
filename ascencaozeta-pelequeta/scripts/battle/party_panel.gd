extends PanelContainer
class_name PartyPanel
signal aliado_selecionado(aliado: CombatenteData)
signal aliado_deselecionado
# UI
@onready var vbox = VBoxContainer.new()
@onready var label_titulo = Label.new()
@onready var scroll_container = ScrollContainer.new()
@onready var lista_personagens = VBoxContainer.new()

var personagens: Array[CombatenteData] = []
var cards_personagens: Dictionary = {}  # nome -> card node
var personagem_ativo_atual: CombatenteData = null
enum TipoAlvo {
	INIMIGO,
	ALIADO,
	QUALQUER
}
var aliado_selecionado_atual: CombatenteData = null
var modo_seletor_ativo := false
var tipo_alvo := TipoAlvo.ALIADO

## Monta o painel visual da party.
func _ready() -> void:
	_criar_layout()

# ============================================================================
# CRIAÇÃO DA UI
# ============================================================================

## Cria título, rolagem e container onde os cards dos personagens são inseridos.
func _criar_layout() -> void:
	"""Cria o layout do painel do partido"""
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)
	
	# Título
	label_titulo.text = "Party"
	label_titulo.add_theme_font_size_override("font_size", 18)
	vbox.add_child(label_titulo)
	
	# Container de scroll para lista
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.clip_contents = true
	
	lista_personagens.add_theme_constant_override("separation", 50)
	scroll_container.add_child(lista_personagens)
	
	vbox.add_child(scroll_container)

# ============================================================================
# GERENCIAMENTO DE PERSONAGENS
# ============================================================================
## Adiciona um personagem e cria seu card visual.
func adicionar_personagem(personagem: CombatenteData) -> void:
	"""Adiciona um personagem ao painel"""
	personagens.append(personagem)
	_criar_card_personagem(personagem)
## Atualiza o card do personagem ou remove-o quando ele morre.
func atualizar_personagem(personagem: CombatenteData) -> void:
	"""Atualiza o visual de um personagem. Remove se morreu."""
	var chave = personagem.nome
	
	# Se morreu, remover da party
	if personagem.morto:
		remover_personagem(personagem)
		return
	
	if chave in cards_personagens:
		var card_wrapper = cards_personagens[chave]
		if card_wrapper.has("atualizar"):
			card_wrapper["atualizar"].call(personagem)
## Remove um personagem derrotado da party e da interface.
func remover_personagem(personagem: CombatenteData) -> void:
	"""Remove um personagem do painel (derrotado)"""
	var chave = personagem.nome
	if chave in cards_personagens:
		cards_personagens[chave].queue_free()
		cards_personagens.erase(chave)
	
	personagens = personagens.filter(func(p): return p.nome != chave)
## Remove todos os cards e zera as referências da party visual.
func limpar_personagens() -> void:
	"""Remove todos os personagens"""
	for card in cards_personagens.values():
		card.queue_free()
	cards_personagens.clear()
	personagens.clear()
	personagem_ativo_atual = null

# ============================================================================
# CRIAÇÃO DE CARDS
# ============================================================================

## Cria um card e fecha sobre ele a função de atualizar todos os dados visuais.
func _criar_card_personagem(personagem: CombatenteData) -> void:
	"""Cria um card visual para um personagem"""
	
	var card = Button.new()

	card.toggle_mode = true

	card.alignment = HORIZONTAL_ALIGNMENT_LEFT

	card.flat = false

	card.custom_minimum_size = Vector2(0, 200)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	card.focus_mode = Control.FOCUS_NONE

	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var estilo = StyleBoxFlat.new()

	estilo.bg_color = Color(0.10,0.10,0.10)

	estilo.border_color = Color(0.25,0.25,0.25)

	estilo.set_border_width_all(2)

	estilo.corner_radius_top_left = 8
	estilo.corner_radius_top_right = 8
	estilo.corner_radius_bottom_left = 8
	estilo.corner_radius_bottom_right = 8

	card.add_theme_stylebox_override("normal", estilo)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",12)
	margin.add_theme_constant_override("margin_right",12)
	margin.add_theme_constant_override("margin_top",10)
	margin.add_theme_constant_override("margin_bottom",10)
	card.add_child(margin)

	var vbox_card = VBoxContainer.new()

	margin.add_child(vbox_card)
	vbox_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_card.add_theme_constant_override(
		"separation",
		8
	)
	var linha_superior = HBoxContainer.new()
	linha_superior.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_card.add_child(linha_superior)
	
	# Nome (com status)
	var label_nome = Label.new()

	label_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	label_nome.add_theme_font_size_override(
		"font_size",
		21
	)

	label_nome.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	linha_superior.add_child(label_nome)
	
	var label_arma = Label.new()

	label_arma.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	label_arma.add_theme_font_size_override(
		"font_size",
		15
	)

	label_arma.add_theme_color_override(
		"font_color",
		Color(1.0,0.85,0.2)
	)
	label_arma.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	linha_superior.add_child(label_arma)
	var linha_atributos = HBoxContainer.new()
	linha_atributos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_card.add_child(linha_atributos)
	
	var separador = HSeparator.new()
	vbox_card.add_child(separador)
	
	var label_pa = Label.new()
	linha_atributos.add_child(label_pa)
	label_pa.add_theme_font_size_override(
		"font_size",
		15
	)
	label_pa.add_theme_color_override(
		"font_color",
		Color(0.7,1,0.7)
	)
	
	var espacador = Control.new()

	espacador.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	linha_atributos.add_child(espacador)
	
	var label_protecao = Label.new()
	linha_atributos.add_child(label_protecao)
	label_protecao.add_theme_font_size_override(
		"font_size",
		15
	)
	label_protecao.add_theme_color_override(
		"font_color",
		Color(0.6,0.85,1.0)
	)
	
	var caixa_regioes = VBoxContainer.new()
	caixa_regioes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caixa_regioes.add_theme_constant_override(
		"separation",
		8
	)
	vbox_card.add_child(caixa_regioes)
	
	# ESTRESSE POR REGIÃO (OBLIVIO display)
	var labels_regioes = {}
	for regiao in CombatenteData.REGIOES:

		var label = Label.new()

		label.add_theme_font_size_override(
			"font_size",
			20
		)

		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		caixa_regioes.add_child(label)

		labels_regioes[regiao] = label

	var separador_status = HSeparator.new()
	vbox_card.add_child(separador_status)
		
	var label_status = Label.new()

	label_status.add_theme_font_size_override(
		"font_size",
		15
	)

	label_status.add_theme_color_override(
		"font_color",
		Color.LIGHT_CYAN
	)

	vbox_card.add_child(label_status)
	
	# Armazenar referência para atualizar depois
	var card_wrapper = {
		"node": card,
		"label_nome":label_nome,
		"label_arma":label_arma,
		"label_pa":label_pa,
		"label_protecao":label_protecao,
		"labels_regioes":labels_regioes,
		"label_status":label_status,
		"atualizar": func(p: CombatenteData):
		# ==========================================
		# Nome
		# ==========================================

		label_nome.text = p.nome

		if p.status.size() > 0:
			label_nome.text += " [%s]" % ", ".join(p.status)


		# ==========================================
		# Arma equipada
		# ==========================================

		if p.arma_equipada != "":
			label_arma.text = "⚔ " + p.arma_equipada
		else:
			label_arma.text = "⚔ Desarmado"


		# ==========================================
		# PA
		# ==========================================

		label_pa.text = "PA %d/%d" % [
			p.pontos_acao_atuais,
			p.pontos_acao_maximos
		]


		# ==========================================
		# Proteção
		# ==========================================

		label_protecao.text = "Proteção %d/%d" % [
			p.obter_protecao_atual(),
			p.atributo_protecao
		]


		# ==========================================
		# Regiões
		# ==========================================

		for regiao in CombatenteData.REGIOES:

			if not labels_regioes.has(regiao):
				continue

			var dados = p.estresse_por_regiao[regiao]

			var atual = dados["atual"]

			var limite = dados["limite"]

			var texto = "%-18s %d/%d" % [
				regiao,
				atual,
				limite
			]

			var label = labels_regioes[regiao]

			label.text = texto


			if limite == 0:

				label.modulate = Color.GRAY

			elif atual >= limite:

				label.modulate = Color.RED

			elif float(atual)/float(limite) >= 0.70:

				label.modulate = Color.ORANGE

			else:

				label.modulate = Color.WHITE


		# ==========================================
		# Status especiais
		# ==========================================

		var especiais : Array[String] = []


		if p.habilidade_sobrecarga_ativa:
			especiais.append("⚡ Sobrecarga")


		if not p.proteses.is_empty():
			especiais.append(
				"Próteses: %s"
				%
				", ".join(p.proteses.keys())
			)


		if not p.regioes_perdidas.is_empty():
			especiais.append(
				"Perdidas: %s"
				%
				", ".join(p.regioes_perdidas)
			)


		label_status.text = "\n".join(especiais)
		}
	lista_personagens.add_child(card)
	card.pressed.connect(
		_on_card_personagem_pressionado.bind(personagem)
	)
	card_wrapper["atualizar"].call(personagem)
	cards_personagens[personagem.nome] = card_wrapper
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.focus_mode = Control.FOCUS_NONE

# ============================================================================
# INDICADORES DE TURNO
# ============================================================================

## Destaca visualmente o card do personagem cujo turno está ativo.
func indicar_personagem_ativo(
	personagem: CombatenteData
) -> void:

	personagem_ativo_atual = personagem

	for wrapper in cards_personagens.values():

		var card = wrapper["node"]

		var estilo = StyleBoxFlat.new()

		estilo.bg_color = Color(
			0.10,
			0.10,
			0.10
		)

		estilo.border_color = Color(
			0.25,
			0.25,
			0.25
		)

		estilo.set_border_width_all(2)

		estilo.corner_radius_top_left = 8
		estilo.corner_radius_top_right = 8
		estilo.corner_radius_bottom_left = 8
		estilo.corner_radius_bottom_right = 8

		card.add_theme_stylebox_override(
			"normal",
			estilo
		)

	if personagem.nome in cards_personagens:

		var card = cards_personagens[
			personagem.nome
		]["node"]

		var ativo = StyleBoxFlat.new()

		ativo.bg_color = Color(
			0.30,
			0.24,
			0.05
		)

		ativo.border_color = Color(1.0,0.85,0.15)

		ativo.set_border_width_all(4)

		ativo.corner_radius_top_left = 8
		ativo.corner_radius_top_right = 8
		ativo.corner_radius_bottom_left = 8
		ativo.corner_radius_bottom_right = 8
		ativo.shadow_size = 12
		ativo.shadow_color = Color(1.0,0.85,0.15,0.35)
		card.add_theme_stylebox_override(
			"normal",
			ativo
		)

## Restaura o estilo normal de todos os cards e remove o personagem ativo.
func remover_destaque_turno() -> void:

	for wrapper in cards_personagens.values():

		var card = wrapper["node"]

		var estilo = StyleBoxFlat.new()

		estilo.bg_color = Color(
			0.10,
			0.10,
			0.10
		)

		estilo.border_color = Color(
			0.25,
			0.25,
			0.25
		)

		estilo.set_border_width_all(2)

		estilo.corner_radius_top_left = 8
		estilo.corner_radius_top_right = 8
		estilo.corner_radius_bottom_left = 8
		estilo.corner_radius_bottom_right = 8

		card.add_theme_stylebox_override(
			"normal",
			estilo
		)

	personagem_ativo_atual = null

# ============================================================================
# ATUALIZAÇÃO
# ============================================================================
## Reconstrói a lista completa de personagens recebida pelo gerenciador.
func atualizar_todos(personagens_novos: Array[CombatenteData]) -> void:
	"""Atualiza toda a lista de personagens"""
	limpar_personagens()
	
	for personagem in personagens_novos:
		adicionar_personagem(personagem)

## Libera os cards para escolher um aliado como alvo.
func ativar_seletor_aliado() -> void:

	modo_seletor_ativo = true
	aliado_selecionado_atual = null

	mouse_filter = Control.MOUSE_FILTER_STOP

	for card_info in cards_personagens.values():

		var card = card_info["node"]

		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.focus_mode = Control.FOCUS_ALL
		card.disabled = false
	await get_tree().process_frame

	if cards_personagens.size() > 0:
		cards_personagens.values()[0]["node"].grab_focus()

## Bloqueia a seleção de aliados e remove marcações visuais.
func desativar_seletor_aliado() -> void:

	modo_seletor_ativo = false

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	for card_info in cards_personagens.values():

		var card = card_info["node"]

		card.button_pressed = false
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.focus_mode = Control.FOCUS_NONE

## Emite o aliado escolhido e desativa o seletor após o clique.
func _on_card_personagem_pressionado(
	aliado: CombatenteData
) -> void:
	if not modo_seletor_ativo:
		return
	if aliado_selecionado_atual != null:
		var anterior = cards_personagens[
			aliado_selecionado_atual.nome
		]["node"]

		anterior.button_pressed = false

	aliado_selecionado_atual = aliado
	for wrapper in cards_personagens.values():
		var botao = wrapper["node"]

		botao.button_pressed = false
	cards_personagens[
		aliado.nome
	]["node"].button_pressed = true
	aliado_selecionado.emit(aliado)

	desativar_seletor_aliado()

## Retorna o último aliado escolhido pelo seletor.
func obter_aliado_selecionado() -> CombatenteData:
	return aliado_selecionado_atual

# ============================================================================
# UTILIDADES
# ============================================================================
## Retorna o personagem marcado como dono do turno atual.
func obter_personagem_ativo() -> CombatenteData:
	"""Retorna o personagem ativo"""
	return personagem_ativo_atual

## Mantém compatibilidade usando o mesmo seletor de aliados para itens.
func ativar_seletor_item() -> void:
	ativar_seletor_aliado()

## Abre a seleção de destinatário de um item.
func ativar_seletor_alvo_item() -> void:
	ativar_seletor_aliado()
