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
@onready var grid_regioes: GridContainer = %RegionalGrid
@onready var label_info: Label = %RegionalInfo
@onready var botao_confirmar: Button = %RegionalConfirmar
@onready var botao_cancelar: Button = %RegionalCancelar
var botoes_regiao: Array[Button] = []

func _ready() -> void:
	_conectar_botoes()
	desativar()


# Liga os botões que já existem na cena (a estrutura vem do editor).
func _conectar_botoes() -> void:
	var filhos: Array[Node] = grid_regioes.get_children()
	if filhos.size() != regioes.size():
		push_error("[RegionalSelector] RegionalGrid deve ter %d botões." % regioes.size())
		return
	for i in range(regioes.size()):
		var botao := filhos[i] as Button
		botoes_regiao.append(botao)
		botao.pressed.connect(_on_regiao_clicada.bindv([i, regioes[i]]))
		UiUtil.compactar_botao(botao, TAMANHO_FONTE, true)
	botao_confirmar.pressed.connect(_on_confirmar)
	botao_cancelar.pressed.connect(_on_cancelar)
	UiUtil.compactar_botao(botao_confirmar, TAMANHO_FONTE, true)
	UiUtil.compactar_botao(botao_cancelar, TAMANHO_FONTE, true)

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
	var total_riscos := contar_selecionadas()
	var limite_atingido := total_riscos >= 5

	for i in range(regioes.size()):
		var regiao: String = regioes[i]
		var botao: Button = botoes_regiao[i]

		var regiao_invalida := not _pode_arriscar_regiao(regiao)

		botao.disabled = regiao_invalida or limite_atingido

		if regiao_invalida:
			botao.add_theme_color_override(
				"font_disabled_color",
				Color.RED
			)
		else:
			botao.remove_theme_color_override("font_disabled_color")

		botao.text = _obter_nome_visual_regiao(regiao)

		if selecionadas[i] > 0:
			botao.text += " x%d" % selecionadas[i]


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
	_atualizar_estado_botoes()

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

	# Mantém o estado "pressionado" igual à contagem: com Sobrecarga o
	# toggle nativo desmarcaria o botão no segundo clique (x2).
	botao.set_pressed_no_signal(selecionadas[indice] > 0)

	if selecionadas[indice] > 0:
		botao.text = "%s x%d" % [nome_base, selecionadas[indice]]
	else:
		botao.text = nome_base

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
	selecionadas = [0, 0, 0, 0, 0]
	regioes_finais.clear()

	for botao in botoes_regiao:
		botao.button_pressed = false
		botao.remove_theme_color_override("font_color")
		botao.remove_theme_color_override("font_focus_color")

	label_info.text = "Clique para selecionar"

	if is_node_ready() and combatente_ativo != null:
		_atualizar_estado_botoes()

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
