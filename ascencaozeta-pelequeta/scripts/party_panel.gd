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
	# Validar dados
	if not personagem.has("nome"):
		print("[PartyPanel] ERRO: Personagem sem nome")
		return
	if not personagem.has("estresse_por_regiao"):
		print("[PartyPanel] ERRO: Personagem '%s' sem dados de estresse" % personagem["nome"])
		return
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 60)
	
	var vbox_card = VBoxContainer.new()
	vbox_card.add_theme_constant_override("separation", 2)
	card.add_child(vbox_card)
	
	# Nome (com status)
	var label_nome = Label.new()
	var status_text = personagem["nome"]
	if personagem.has("status") and not personagem["status"].is_empty():
		status_text += " [%s]" % ", ".join(personagem["status"])
	label_nome.text = status_text
	label_nome.add_theme_font_size_override("font_size", 12)
	vbox_card.add_child(label_nome)
	
	# ESTRESSE TOTAL (métrica principal em OBLIVIO)
	var label_estresse = Label.new()
	label_estresse.add_theme_font_size_override("font_size", 10)
	vbox_card.add_child(label_estresse)
	
	# Armazenar referência para atualizar depois
	var card_wrapper = {
		"node": card,
		"label_nome": label_nome,
		"label_estresse": label_estresse,
		"atualizar": func(p: Dictionary):
			# Validar antes de atualizar
			if not p.has("nome") or not p.has("estresse_por_regiao"):
				print("[PartyPanel] ERRO: Dados inválidos ao atualizar personagem")
				return
			
			# Atualizar nome e status
			if p.has("status") and not p["status"].is_empty():
				status_text += " [%s]" % ", ".join(p["status"])
			label_nome.text = status_text
			
			# Calcular estresse total
			var estresse_total = 0
			var limite_total = 0
			var regioes_esgotadas = 0
			
			for regiao_est in p["estresse_por_regiao"].values():
				estresse_total += regiao_est["atual"]
				limite_total += regiao_est["limite"]
				if regiao_est["atual"] >= regiao_est["limite"]:
					regioes_esgotadas += 1
			
			# Mostrar estresse total
			var est_str = "Estresse: %d/%d" % [estresse_total, limite_total]
			
			# Mostrar se tem regiões esgotadas (fadiga)
			if regioes_esgotadas > 0:
				est_str += " (%d regiões esgotadas)" % regioes_esgotadas
			
			# Colorir baseado em fadiga
			if regioes_esgotadas >= 5:  # Todas esgotadas = desmaiado
				label_estresse.add_theme_color_override("font_color", Color.RED)
				est_str += " [DESMAIADO]"
			elif regioes_esgotadas >= 3:
				label_estresse.add_theme_color_override("font_color", Color.YELLOW)
			elif float(estresse_total) / float(limite_total) > 0.7:
				label_estresse.add_theme_color_override("font_color", Color.ORANGE)
			else:
				label_estresse.remove_theme_color_override("font_color")
			
			label_estresse.text = est_str
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

func obter_personagem_ativo() -> Dictionary:
	"""Retorna o personagem ativo"""
	return personagem_ativo_atual
