extends PanelContainer
class_name RegionalSelector
const TAMANHO_FONTE: int = 8

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
var selecionadas: Array[int] = [0, 0, 0, 0, 0]
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
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)

	label_titulo.text = "Selecione Regiões"
	label_titulo.add_theme_font_size_override("font_size", TAMANHO_FONTE + 1)
	vbox.add_child(label_titulo)

	grid_regioes.columns = 2
	grid_regioes.add_theme_constant_override("h_separation", 2)
	grid_regioes.add_theme_constant_override("v_separation", 2)

	for i in range(regioes.size()):
		var botao = _criar_botao_regiao(regioes[i], i)
		botao.focus_mode = Control.FOCUS_ALL
		botoes_regiao.append(botao)
		grid_regioes.add_child(botao)

	vbox.add_child(grid_regioes)

	label_info.text = "Clique para selecionar"
	label_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_info.add_theme_font_size_override("font_size", TAMANHO_FONTE)
	vbox.add_child(label_info)

	var hbox_botoes = HBoxContainer.new()
	hbox_botoes.add_theme_constant_override("separation", 2)

	var botao_confirmar = Button.new()
	botao_confirmar.text = "✓ Confirmar"
	botao_confirmar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao_confirmar.clip_text = true
	botao_confirmar.pressed.connect(_on_confirmar)
	UiUtil.aplicar(botao_confirmar, TAMANHO_FONTE)
	hbox_botoes.add_child(botao_confirmar)

	var botao_cancelar = Button.new()
	botao_cancelar.text = "✗ Cancelar"
	botao_cancelar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao_cancelar.clip_text = true
	botao_cancelar.pressed.connect(_on_cancelar)
	UiUtil.aplicar(botao_cancelar, TAMANHO_FONTE)
	hbox_botoes.add_child(botao_cancelar)

	vbox.add_child(hbox_botoes)

func _criar_botao_regiao(nome: String, indice: int) -> Button:
	"""Helper para criar botão de região"""
	var botao = Button.new()
	botao.text = nome
	botao.custom_minimum_size = Vector2(0, 12)
	botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao.clip_text = true
	botao.toggle_mode = true
	botao.pressed.connect(_on_regiao_clicada.bindv([indice, nome]))
	UiUtil.aplicar(botao, TAMANHO_FONTE)
	return botao

# ============================================================================
# ATIVAÇÃO/DESATIVAÇÃO
# ============================================================================

func ativar_para_ataque(combatente: CombatenteData) -> void:
	combatente_ativo = combatente
	modo = "selecionar_ataque"
	show()
	await get_tree().process_frame
	if botoes_regiao.size() > 0:
		botoes_regiao[0].grab_focus()
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

	if regiao in combatente_ativo.regioes_perdidas:
		return false

	if combatente_ativo.proteses.has(regiao) and combatente_ativo.proteses[regiao].destruida:
		return false

	var stress: Dictionary = combatente_ativo.estresse_por_regiao[regiao]
	if stress["atual"] >= stress["limite"]:
		return false

	return true

func _atualizar_estado_botoes() -> void:
	"""Atualiza o estado visual dos botões (habilitado/desabilitado)"""
	for i in range(regioes.size()):
		var regiao = regioes[i]
		var botao = botoes_regiao[i]

		if not _pode_arriscar_regiao(regiao):
			botao.disabled = true
			botao.add_theme_color_override("font_disabled_color", Color.RED)
		else:
			botao.disabled = false
			botao.text = _obter_nome_visual_regiao(regiao)
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
	if modo == "desativado":
		return

	if not _pode_arriscar_regiao(nome_regiao):
		label_info.text = "Essa região não pode ser arriscada!"
		return

	var total_riscos := contar_selecionadas()

	if permite_multiplas_mesma_regiao:
		if total_riscos >= 5:
			label_info.text = "Máximo de 5 riscos!"
			return

		selecionadas[indice] += 1
	else:
		if selecionadas[indice] > 0:
			selecionadas[indice] = 0
		else:
			if total_riscos >= 5:
				label_info.text = "Máximo de 5 riscos!"
				return

			selecionadas[indice] = 1

	_atualizar_visual_botao(indice)
	_atualizar_info_label()

	regiao_selecionada.emit(nome_regiao, indice)

func _on_confirmar() -> void:
	if modo == "desativado":
		return

	regioes_finais = obter_regioes_selecionadas()

	if regioes_finais.is_empty():
		label_info.text = "Selecione pelo menos uma região!"
		return

	selecao_confirmada.emit(regioes_finais)

	desativar()

func _on_cancelar() -> void:
	"""Callback do botão Cancelar"""
	selecao_cancelada.emit()
	desativar()

# ============================================================================
# ATUALIZAÇÕES VISUAIS
# ============================================================================
func _obter_nome_visual_regiao(regiao: String) -> String:
	if combatente_ativo != null and combatente_ativo.proteses.has(regiao):
		return regiao + " [PR]"
	return regiao

func _atualizar_visual_botao(indice: int) -> void:
	var botao = botoes_regiao[indice]

	var nome_base = _obter_nome_visual_regiao(regioes[indice])

	if selecionadas[indice] > 0:
		botao.text = "%s x%d" % [nome_base, selecionadas[indice]]

		botao.add_theme_color_override(
			"font_color",
			Color.BLACK
		)

		botao.add_theme_color_override(
			"font_focus_color",
			Color.BLACK
		)
	else:
		botao.text = nome_base

		botao.remove_theme_color_override(
			"font_color"
		)

		botao.remove_theme_color_override(
			"font_focus_color"
		)

func _atualizar_info_label() -> void:
	var total := contar_selecionadas()

	var texto := ""

	for i in range(5):
		if i < total:
			texto += "●"
		else:
			texto += "○"

	label_info.text = "Riscos: %s (%d/5)" % [texto, total]

func _resetar_selecao() -> void:
	"""Reseta toda a seleção"""
	selecionadas = [0, 0, 0, 0, 0]
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
	var resultado: Array[String] = []

	for i in range(selecionadas.size()):
		for j in range(selecionadas[i]):
			resultado.append(regioes[i])

	return resultado

func contar_selecionadas() -> int:
	var total := 0

	for valor in selecionadas:
		total += valor

	return total
