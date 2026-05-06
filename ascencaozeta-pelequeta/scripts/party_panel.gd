extends PanelContainer
class_name PartyPanel

# UI
@onready var vbox = VBoxContainer.new()
@onready var label_titulo = Label.new()
@onready var scroll_container = ScrollContainer.new()
@onready var lista_personagens = VBoxContainer.new()

var personagens: Array[Dictionary] = []
var cards_personagens: Dictionary = {}  # nome -> card node
var personagem_ativo_atual: Dictionary = {}

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
	label_titulo.text = "Partido"
	label_titulo.add_theme_font_size_override("font_size", 14)
	vbox.add_child(label_titulo)
	
	# Container de scroll para lista
	scroll_container.custom_minimum_size = Vector2(0, 200)
	scroll_container.clip_contents = true
	
	lista_personagens.add_theme_constant_override("separation", 4)
	scroll_container.add_child(lista_personagens)
	
	vbox.add_child(scroll_container)

# ============================================================================
# GERENCIAMENTO DE PERSONAGENS
# ============================================================================

func adicionar_personagem(personagem: Dictionary) -> void:
	"""Adiciona um personagem ao painel"""
	personagens.append(personagem)
	_criar_card_personagem(personagem)

func atualizar_personagem(personagem: Dictionary) -> void:
	"""Atualiza o visual de um personagem"""
	var chave = personagem["nome"]
	if chave in cards_personagens:
		var card = cards_personagens[chave]
		card.atualizar(personagem)

func remover_personagem(personagem: Dictionary) -> void:
	"""Remove um personagem do painel (derrotado)"""
	var chave = personagem["nome"]
	if chave in cards_personagens:
		cards_personagens[chave].queue_free()
		cards_personagens.erase(chave)
	
	personagens = personagens.filter(func(p): return p["nome"] != chave)

func limpar_personagens() -> void:
	"""Remove todos os personagens"""
	for card in cards_personagens.values():
		card.queue_free()
	cards_personagens.clear()
	personagens.clear()
	personagem_ativo_atual.clear()

# ============================================================================
# CRIAÇÃO DE CARDS
# ============================================================================

func _criar_card_personagem(personagem: Dictionary) -> void:
	"""Cria um card visual para um personagem"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 60)
	
	var vbox_card = VBoxContainer.new()
	vbox_card.add_theme_constant_override("separation", 2)
	card.add_child(vbox_card)
	
	# Nome
	var label_nome = Label.new()
	label_nome.text = personagem["nome"]
	label_nome.add_theme_font_size_override("font_size", 12)
	vbox_card.add_child(label_nome)
	
	# HP
	var label_hp = Label.new()
	label_hp.text = "HP: %d/%d" % [personagem["saude_atual"], personagem["saude_maxima"]]
	label_hp.add_theme_font_size_override("font_size", 10)
	vbox_card.add_child(label_hp)
	
	# Estresse
	var estresse_total = _calcular_estresse_total(personagem)
	var label_estresse = Label.new()
	label_estresse.text = "Estresse: %d" % estresse_total
	label_estresse.add_theme_font_size_override("font_size", 10)
	
	# Colorir estresse conforme valor
	if estresse_total >= 12:
		label_estresse.add_theme_color_override("font_color", Color.RED)
	elif estresse_total >= 8:
		label_estresse.add_theme_color_override("font_color", Color.YELLOW)
	
	vbox_card.add_child(label_estresse)
	
	# Armazenar referência para atualizar depois
	var card_wrapper = {
		"node": card,
		"label_hp": label_hp,
		"label_estresse": label_estresse,
		"atualizar": func(p: Dictionary):
			label_nome.text = p["nome"]
			label_hp.text = "HP: %d/%d" % [p["saude_atual"], p["saude_maxima"]]
			
			var est = _calcular_estresse_total(p)
			label_estresse.text = "Estresse: %d" % est
			
			if est >= 12:
				label_estresse.add_theme_color_override("font_color", Color.RED)
			elif est >= 8:
				label_estresse.add_theme_color_override("font_color", Color.YELLOW)
			else:
				label_estresse.remove_theme_color_override("font_color")
	}
	
	lista_personagens.add_child(card)
	cards_personagens[personagem["nome"]] = card_wrapper

# ============================================================================
# INDICADORES DE TURNO
# ============================================================================

func indicar_personagem_ativo(personagem: Dictionary) -> void:
	"""Destaca qual personagem tem turno ativo"""
	personagem_ativo_atual = personagem
	
	# Remover destaque anterior
	for card_info in cards_personagens.values():
		var card = card_info["node"]
		card.remove_theme_stylebox_override("panel")
	
	# Aplicar novo destaque
	if personagem["nome"] in cards_personagens:
		var card_info = cards_personagens[personagem["nome"]]
		var card = card_info["node"]
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color.YELLOW.darkened(0.5)
		style.border_color = Color.YELLOW

		style.set_border_width_all(2)
		card.add_theme_stylebox_override("panel", style)

func remover_destaque_turno() -> void:
	"""Remove o destaque de turno ativo"""
	for card_info in cards_personagens.values():
		var card = card_info["node"]
		card.remove_theme_stylebox_override("panel")
	
	personagem_ativo_atual.clear()

# ============================================================================
# ATUALIZAÇÃO
# ============================================================================

func atualizar_todos(personagens_novos: Array[Dictionary]) -> void:
	"""Atualiza toda a lista de personagens"""
	limpar_personagens()
	
	for personagem in personagens_novos:
		adicionar_personagem(personagem)

# ============================================================================
# UTILIDADES
# ============================================================================

func _calcular_estresse_total(personagem: Dictionary) -> int:
	"""Calcula o estresse total de um personagem"""
	var total = 0
	for valor in personagem["estresse_por_regiao"].values():
		total += valor
	return total

func obter_personagem_ativo() -> Dictionary:
	"""Retorna o personagem ativo"""
	return personagem_ativo_atual
