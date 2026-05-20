extends PanelContainer
class_name RegionalSelector

# Sinais para comunicação com CombatManager
signal regiao_selecionada(nome_regiao: String, indice: int)
signal selecao_confirmada(regioes: Array[String])
signal selecao_cancelada

# Referência ao combatente ativo (para validar próteses e regiões perdidas)
var combatente_ativo: CombatenteData = null

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
var permite_multiplas_mesma_regiao: bool = false  # Sobrecarga ativa

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
	label_info.text = "Clique para selecionar"
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

func ativar_para_ataque(combatente: CombatenteData) -> void:
	"""Ativa o seletor para modo de ataque"""
	combatente_ativo = combatente
	modo = "selecionar_ataque"
	label_titulo.text = "Selecione Regiões de Ataque"
	label_info.text = "Clique para selecionar"
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	_resetar_selecao()
	
	# Ativar Sobrecarga se o combatente tem a habilidade
	permite_multiplas_mesma_regiao = combatente.habilidade_sobrecarga_ativa
	
	# Atualizar visual dos botões (desabilitar regiões perdidas/próteses destruídas)
	_atualizar_estado_botoes()


## ===== VALIDAÇÃO DE REGIÕES =====

func _pode_arriscar_regiao(regiao: String) -> bool:
	"""Valida se uma região pode ser arriscada em combate"""
	if combatente_ativo == null:
		return false
	
	# Verifica se é uma região perdida
	if regiao in combatente_ativo.regioes_perdidas:
		return false
	
	# Se tem prótese, verifica se não foi destruída
	if combatente_ativo.proteses.has(regiao):
		var protese = combatente_ativo.proteses[regiao]
		return not protese.destruida
	
	return true

func _atualizar_estado_botoes() -> void:
	"""Atualiza o estado visual dos botões (habilitado/desabilitado)"""
	for i in range(regioes.size()):
		var regiao = regioes[i]
		var botao = botoes_regiao[i]
		var pode_arriscar = _pode_arriscar_regiao(regiao)
		
		if not pode_arriscar:
			botao.disabled = true
			if regiao in combatente_ativo.regioes_perdidas:
				botao.text = regioes[i] + " (PERDIDO)"
				botao.add_theme_color_override("font_disabled_color", Color.RED)
			elif combatente_ativo.proteses.has(regiao) and combatente_ativo.proteses[regiao].destruida:
				botao.text = regioes[i] + " (PRÓTESE DESTRUÍDA)"
				botao.add_theme_color_override("font_disabled_color", Color.DARK_RED)
		else:
			botao.disabled = false
			# Se tem prótese, mostrar indicador
			if combatente_ativo.proteses.has(regiao):
				botao.text = regioes[i] + " [PR]"
				botao.add_theme_color_override("font_disabled_color", Color.YELLOW)
			else:
				botao.text = regioes[i]
				botao.remove_theme_color_override("font_disabled_color")


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
	
	# Validar se pode arriscar a região
	if not _pode_arriscar_regiao(nome_regiao):
		label_info.text = "Essa região não pode ser arriscada!"
		return
	
	# Se Sobrecarga está ativo, permite múltiplas seleções da mesma região
	# Senão, apenas uma seleção por botão (toggle normal)
	if not permite_multiplas_mesma_regiao:
		# Modo normal: toggle
		selecionadas[indice] = !selecionadas[indice]
	else:
		# Modo Sobrecarga: pode selecionar múltiplas vezes
		# Implementar contagem de vezes selecionada (TODO: expandir para array com contagem)
		selecionadas[indice] = !selecionadas[indice]
	
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
	label_info.text = "[%d/5] - Selecionadas: %s" % [quantidade, texto]

func _resetar_selecao() -> void:
	"""Reseta toda a seleção"""
	selecionadas = [false, false, false, false, false]
	regioes_finais.clear()
	
	for botao in botoes_regiao:
		botao.button_pressed = false
		botao.remove_theme_color_override("font_color")
		botao.remove_theme_color_override("font_focus_color")
	
	label_info.text = "Clique para selecionar"

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
