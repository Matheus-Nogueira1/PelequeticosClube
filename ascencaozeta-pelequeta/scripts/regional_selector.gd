extends PanelContainer
class_name RegionalSelector

# Sinais para comunicação com CombatManager
signal regiao_selecionada(nome_regiao: String, indice: int)
signal selecao_confirmada(regioes: Array[String])
signal selecao_cancelada

# Array de regiões do corpo
var regioes: Array[String] = [
	"Torso",
	"Braço Direito",
	"Braço Esquerdo",
	"Perna Direita",
	"Perna Esquerda"
]

# Estado da seleção
var selecionadas: Array[bool] = [false, false, false, false, false]
var regioes_finais: Array[String] = []
var modo: String = "desativado"  # desativado, selecionar_ataque, selecionar_defesa

# UI
@onready var vbox = VBoxContainer.new()
@onready var label_titulo = Label.new()
@onready var grid_regioes = GridContainer.new()
@onready var label_info = Label.new()
var botoes_regiao: Array[Button] = []

func _ready() -> void:
	_criar_layout()
	desativar()

# ============================================================================
# CRIAÇÃO DA UI
# ============================================================================

func _criar_layout() -> void:
	"""Cria o layout do seletor de regiões"""
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)
	
	# Título
	label_titulo.text = "Selecione Regiões"
	label_titulo.add_theme_font_size_override("font_size", 16)
	vbox.add_child(label_titulo)
	
	# Grid de regiões
	grid_regioes.columns = 2
	grid_regioes.add_theme_constant_override("h_separation", 4)
	grid_regioes.add_theme_constant_override("v_separation", 4)
	
	for i in range(regioes.size()):
		var botao = _criar_botao_regiao(regioes[i], i)
		botoes_regiao.append(botao)
		grid_regioes.add_child(botao)
	
	vbox.add_child(grid_regioes)
	
	# Label informativo (mostra estresse)
	label_info.text = "Clique para selecionar (max 3)"
	label_info.add_theme_font_size_override("font_size", 10)
	vbox.add_child(label_info)
	
	# Espaçador
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 4
	vbox.add_child(spacer)
	
	# Botões de ação
	var hbox_botoes = HBoxContainer.new()
	hbox_botoes.add_theme_constant_override("separation", 4)
	
	var botao_confirmar = Button.new()
	botao_confirmar.text = "✓ Confirmar"
	botao_confirmar.pressed.connect(_on_confirmar)
	hbox_botoes.add_child(botao_confirmar)
	
	var botao_cancelar = Button.new()
	botao_cancelar.text = "✗ Cancelar"
	botao_cancelar.pressed.connect(_on_cancelar)
	hbox_botoes.add_child(botao_cancelar)
	
	vbox.add_child(hbox_botoes)

func _criar_botao_regiao(nome: String, indice: int) -> Button:
	"""Helper para criar botão de região"""
	var botao = Button.new()
	botao.text = nome
	botao.custom_minimum_size = Vector2(100, 32)
	botao.toggle_mode = true
	botao.pressed.connect(_on_regiao_clicada.bindv([indice, nome]))
	return botao

# ============================================================================
# ATIVAÇÃO/DESATIVAÇÃO
# ============================================================================

func ativar_para_ataque() -> void:
	"""Ativa o seletor para modo de ataque"""
	modo = "selecionar_ataque"
	label_titulo.text = "Selecione Regiões de Ataque"
	label_info.text = "Clique para selecionar (1-3 regiões)"
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	_resetar_selecao()

func ativar_para_defesa() -> void:
	"""Ativa o seletor para modo de defesa"""
	modo = "selecionar_defesa"
	label_titulo.text = "Selecione Regiões em Defesa"
	label_info.text = "Clique para proteger (1-3 regiões)"
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	_resetar_selecao()

func desativar() -> void:
	"""Desativa o seletor"""
	modo = "desativado"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
	_resetar_selecao()

# ============================================================================
# CALLBACKS
# ============================================================================

func _on_regiao_clicada(indice: int, nome_regiao: String) -> void:
	"""Chamado quando um botão de região é clicado"""
	if modo == "desativado":
		return
	
	# Alternância da seleção
	selecionadas[indice] = !selecionadas[indice]
	
	# Verificar limite de 3 regiões
	var quantidade_selecionadas = selecionadas.count(true)
	if quantidade_selecionadas > 3:
		selecionadas[indice] = false
		botoes_regiao[indice].button_pressed = false
		label_info.text = "[MÁXIMO 3 REGIÕES!] Desselecione uma."
		return
	
	# Atualizar visual do botão
	_atualizar_visual_botao(indice)
	
	# Emitir sinal
	regiao_selecionada.emit(nome_regiao, indice)
	
	# Atualizar label de info
	_atualizar_info_label()

func _on_confirmar() -> void:
	"""Callback do botão Confirmar"""
	if modo == "desativado":
		return
	
	# Coletar regiões selecionadas
	regioes_finais.clear()
	for i in range(selecionadas.size()):
		if selecionadas[i]:
			regioes_finais.append(regioes[i])
	
	if regioes_finais.is_empty():
		label_info.text = "Selecione pelo menos uma região!"
		return
	
	# Emitir sinal de confirmação
	selecao_confirmada.emit(regioes_finais)
	
	# Desativar
	desativar()

func _on_cancelar() -> void:
	"""Callback do botão Cancelar"""
	selecao_cancelada.emit()
	desativar()

# ============================================================================
# ATUALIZAÇÕES VISUAIS
# ============================================================================

func _atualizar_visual_botao(indice: int) -> void:
	"""Atualiza o visual de um botão de região"""
	var botao = botoes_regiao[indice]
	
	if selecionadas[indice]:
		# Botão selecionado
		botao.add_theme_color_override("font_color", Color.BLACK)
		botao.add_theme_color_override("font_focus_color", Color.BLACK)
		# Usar um StyleBox para marcar como selecionado
	else:
		# Botão não selecionado
		botao.remove_theme_color_override("font_color")
		botao.remove_theme_color_override("font_focus_color")

func _atualizar_info_label() -> void:
	"""Atualiza o label informativo com contagem"""
	var quantidade = selecionadas.count(true)
	var texto_regioes = []
	for i in range(selecionadas.size()):
		if selecionadas[i]:
			texto_regioes.append(regioes[i])
	
	var texto = ", ".join(texto_regioes) if texto_regioes.size() > 0 else "nenhuma"
	label_info.text = "[%d/3] - Selecionadas: %s" % [quantidade, texto]

func _resetar_selecao() -> void:
	"""Reseta toda a seleção"""
	selecionadas = [false, false, false, false, false]
	regioes_finais.clear()
	
	for botao in botoes_regiao:
		botao.button_pressed = false
		botao.remove_theme_color_override("font_color")
		botao.remove_theme_color_override("font_focus_color")
	
	label_info.text = "Clique para selecionar (1-3 regiões)"

# ============================================================================
# UTILIDADES
# ============================================================================

func obter_regioes_selecionadas() -> Array[String]:
	"""Retorna array de regiões atualmente selecionadas"""
	var resultado: Array[String] = []
	for i in range(selecionadas.size()):
		if selecionadas[i]:
			resultado.append(regioes[i])
	return resultado

func contar_selecionadas() -> int:
	"""Retorna quantidade de regiões selecionadas"""
	return selecionadas.count(true)
