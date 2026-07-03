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

func _ready() -> void:
	_criar_layout()

# ============================================================================
# CRIAÇÃO DA UI
# ============================================================================

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
	scroll_container.clip_contents = true
	
	lista_personagens.add_theme_constant_override("separation", 4)
	scroll_container.add_child(lista_personagens)
	
	vbox.add_child(scroll_container)

# ============================================================================
# GERENCIAMENTO DE PERSONAGENS
# ============================================================================

func adicionar_personagem(personagem: CombatenteData) -> void:
	"""Adiciona um personagem ao painel"""
	personagens.append(personagem)
	_criar_card_personagem(personagem)

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

func remover_personagem(personagem: CombatenteData) -> void:
	"""Remove um personagem do painel (derrotado)"""
	var chave = personagem.nome
	if chave in cards_personagens:
		cards_personagens[chave].queue_free()
		cards_personagens.erase(chave)
	
	personagens = personagens.filter(func(p): return p.nome != chave)

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

func _criar_card_personagem(personagem: CombatenteData) -> void:
	"""Cria um card visual para um personagem"""
	
	var card = Button.new()
	card.flat = true
	card.toggle_mode = true
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.custom_minimum_size = Vector2(0, 50)
	card.pressed.connect(
		_on_card_personagem_pressionado.bind(personagem)
	)
	card.custom_minimum_size = Vector2(0, 50)
	
	var margin = MarginContainer.new()
	card.add_child(margin)
	var vbox_card = VBoxContainer.new()
	margin.add_child(vbox_card)
	
	# Nome (com status)
	var label_nome = Label.new()
	var status_text = personagem.nome
	if personagem.status != null:
		status_text += "\n"
		for status in personagem.status:
			status_text += "• %s\n" % status
	label_nome.text = status_text
	label_nome.add_theme_font_size_override("font_size", 18)
	vbox_card.add_child(label_nome)
	
	# ESTRESSE POR REGIÃO (OBLIVIO display)
	var label_regioes = RichTextLabel.new()
	label_regioes.bbcode_enabled = true
	label_regioes.fit_content = true
	label_regioes.scroll_active = false
	label_regioes.add_theme_font_size_override("font_size", 7)
	vbox_card.add_child(label_regioes)
	
	var label_pa = Label.new()
	label_pa.add_theme_font_size_override(
		"font_size",
		14
	)
	vbox_card.add_child(label_pa)
	
	# INDICADORES DE PRÓTESE E REGIÕES PERDIDAS
	var label_status_especial = Label.new()
	label_status_especial.add_theme_font_size_override("font_size", 15)
	label_status_especial.add_theme_color_override("font_color", Color.LIGHT_CYAN)
	vbox_card.add_child(label_status_especial)
	
	# Equipamentos atualmente utilizados
	var label_equipamentos = Label.new()
	label_equipamentos.add_theme_font_size_override("font_size", 13)
	label_equipamentos.add_theme_color_override(
		"font_color",
		Color.LIGHT_GREEN
	)
	vbox_card.add_child(label_equipamentos)
	var label_consumiveis = Label.new()
	label_consumiveis.add_theme_font_size_override("font_size",13)
	label_consumiveis.add_theme_color_override(
		"font_color",
		Color.AQUA
	)

	vbox_card.add_child(label_consumiveis)
	# Armazenar referência para atualizar depois
	var card_wrapper = {
		"node": card,
		"label_nome": label_nome,
		"label_regioes": label_regioes,
		"label_pa":label_pa,
		"label_status_especial": label_status_especial,
		"label_equipamentos": label_equipamentos,
		"label_consumiveis":label_consumiveis,
		"atualizar": func(p: CombatenteData):
			# Atualizar nome e status
			var novo_nome = p.nome
			if not p.status.is_empty():
				novo_nome += " [%s]" % ", ".join(p.status)
			label_nome.text = novo_nome
			
			# Construir display de regiões com estresse
			var regioes_text = ""
			var regioes_esgotadas = 0
			var estresse_total = 0
			var limite_total = 0
			
			var ordem_regioes = ["Torso", "Braço Direito", "Braço Esquerdo", "Perna Direita", "Perna Esquerda"]
			for regiao in ordem_regioes:
				if regiao in p.estresse_por_regiao:
					var reg_data = p.estresse_por_regiao[regiao]
					var est_atual = reg_data["atual"]
					var est_limite = reg_data["limite"]
					
					estresse_total += est_atual
					limite_total += est_limite
					
					# Mostrar região com cores

					var regiao_display = "%s %d/%d" % [
						regiao,
						est_atual,
						est_limite
					]
					
					# Colorir se esgotado ou perdido
					if est_limite == 0:
						regiao_display += " (PERDIDO)"
					elif est_atual >= est_limite:
						regioes_esgotadas += 1
						regiao_display = "[color=red]%s[/color]" % regiao_display
					elif float(est_atual) / float(est_limite) > 0.7:
						regiao_display = "[color=orange]%s[/color]" % regiao_display
					
					regioes_text += regiao_display + "\n"
			
			label_regioes.text = regioes_text
			label_pa.text = "PA: %d/%d" % [
				p.pontos_acao_atuais,
				p.pontos_acao_maximos
			]
			if p.arma_equipada != "":
				label_nome.text += "  ⚔ %s" % p.arma_equipada
			# Mostrar status especial (Sobrecarga, Próteses)
			var linhas: Array[String] = []

			if p.habilidade_sobrecarga_ativa:
				linhas.append("⚡ SOBRECARGA")
			if not p.proteses.is_empty():
				linhas.append("Próteses: %s" % ", ".join(p.proteses.keys()))
			if not p.regioes_perdidas.is_empty():
				linhas.append("Regiões Perdidas: %s" % ", ".join(p.regioes_perdidas))

				label_status_especial.text = "\n".join(linhas)
			var texto_equipamentos := ""
			if p.arma_equipada != "":
				texto_equipamentos += "Arma: %s" % p.arma_equipada
			else:
				texto_equipamentos = "Arma: Nenhuma"

			label_equipamentos.text = texto_equipamentos
			var texto_consumiveis := ""


			for item in p.inventario:

				texto_consumiveis += item + "\n"

			label_consumiveis.text = texto_consumiveis
	}
	
	lista_personagens.add_child(card)
	cards_personagens[personagem.nome] = card_wrapper
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.focus_mode = Control.FOCUS_NONE

# ============================================================================
# INDICADORES DE TURNO
# ============================================================================

func indicar_personagem_ativo(personagem: CombatenteData) -> void:
	"""Destaca qual personagem tem turno ativo"""
	personagem_ativo_atual = personagem
	
	# Remover destaque anterior
	for card_info in cards_personagens.values():
		var card = card_info["node"]
		card.remove_theme_stylebox_override("panel")
	
	# Aplicar novo destaque
	if personagem.nome in cards_personagens:
		var card_info = cards_personagens[personagem.nome]
		var card = card_info["node"]
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.35, 0.3, 0.05)
		style.border_color = Color.GOLD
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		style.border_color = Color.YELLOW

		style.set_border_width_all(2)
		card.add_theme_stylebox_override("panel", style)

func remover_destaque_turno() -> void:
	"""Remove o destaque de turno ativo"""
	for card_info in cards_personagens.values():
		var card = card_info["node"]
		card.remove_theme_stylebox_override("panel")
	
	personagem_ativo_atual = null

# ============================================================================
# ATUALIZAÇÃO
# ============================================================================

func atualizar_todos(personagens_novos: Array[CombatenteData]) -> void:
	"""Atualiza toda a lista de personagens"""
	limpar_personagens()
	
	for personagem in personagens_novos:
		adicionar_personagem(personagem)

func ativar_seletor_aliado() -> void:

	modo_seletor_ativo = true

	mouse_filter = Control.MOUSE_FILTER_STOP

	for card_info in cards_personagens.values():

		var card = card_info["node"]

		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.focus_mode = Control.FOCUS_ALL

	await get_tree().process_frame

	if cards_personagens.size() > 0:
		cards_personagens.values()[0]["node"].grab_focus()

func desativar_seletor_aliado() -> void:

	modo_seletor_ativo = false

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	for card_info in cards_personagens.values():

		var card = card_info["node"]

		card.button_pressed = false
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.focus_mode = Control.FOCUS_NONE

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

	aliado_selecionado.emit(aliado)

	desativar_seletor_aliado()

func obter_aliado_selecionado() -> CombatenteData:
	return aliado_selecionado_atual

# ============================================================================
# UTILIDADES
# ============================================================================

func obter_personagem_ativo() -> CombatenteData:
	"""Retorna o personagem ativo"""
	return personagem_ativo_atual
