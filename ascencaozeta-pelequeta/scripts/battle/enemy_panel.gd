extends PanelContainer
class_name EnemyPanel

# ============================================================
# PAINEL DE INIMIGOS
# A estrutura (card, coluna de ícones, marcador) vive em
# combat.tscn e enemy_card.tscn. Este script só preenche o texto
# e controla a seleção.
# - Fora da escolha de alvo: clicar num ícone só mostra o card (consulta).
# - Na escolha de alvo (ativar_seletor_alvo): clicar num ícone, ou
#   Enter, confirma aquele inimigo como alvo.
# ============================================================

## ===== SINAIS =====
signal inimigo_selecionado(inimigo: Dictionary)
signal inimigo_deseleccionado
## Emitido quando o jogador cancela a escolha do alvo (Esc ou clique no campo)
signal selecao_alvo_cancelada
## Emitido quando a escolha de alvo começa ou termina
signal modo_alvo_alterado(ativo: bool)
## Emitido quando o jogador pede a ficha completa (botão da cena)
signal ficha_solicitada
const CENA_ICONE: PackedScene = preload("res://scenes/battle/icone_personagem.tscn")
const VARIACAO_NORMAL: StringName = &"IconePersonagem"
const VARIACAO_ALVO: StringName = &"IconeAlvo"

# Preenchido no Inspector (chave = nome do inimigo: Dummy, Carcaça...).
@export var texturas_icones: Dictionary[String, Texture2D] = {}
@onready var botao_ficha: Button = get_node_or_null("%BotaoFicha") as Button
@onready var coluna_icones: HBoxContainer = %EnemyIcones
@onready var card: Control = %EnemyCard
@onready var marcador: Control = %MarcadorEnemy
@onready var nome_label: Label = card.get_node("%NomeLabel")
@onready var estresse_label: Label = card.get_node("%EstresseLabel")
@onready var barra_estresse: ProgressBar = card.get_node("%BarraEstresse")

@onready var regioes_label: RichTextLabel = card.get_node("%RegioesLabel")
@onready var fixos_label: RichTextLabel = card.get_node("%FixosLabel")
@onready var mutaveis_label: RichTextLabel = card.get_node("%MutaveisLabel")
@onready var status_label: RichTextLabel = card.get_node("%StatusLabel")
var inimigos: Array[Dictionary] = []
var botoes_inimigos: Dictionary = {}  # nome -> ícone (Button)
var inimigo_selecionado_atual: Dictionary = {}
var modo_seletor_ativo: bool = false
var exibido: String = ""

# ============================================================================
# GERENCIAMENTO DE INIMIGOS
# ============================================================================
func _ready() -> void:
	if botao_ficha != null:
		botao_ficha.pressed.connect(ficha_solicitada.emit)


# Dicionário do inimigo que está no card (vazio se não houver).
func obter_inimigo_exibido() -> Dictionary:
	var indice: int = _indice_de(exibido)
	if indice == -1:
		return {}
	return inimigos[indice]

func adicionar_inimigo(inimigo: Dictionary) -> void:
	inimigos.append(inimigo)
	botoes_inimigos[inimigo["nome"]] = _criar_icone(inimigo)
	if exibido.is_empty():
		_exibir(inimigo["nome"])


func atualizar_inimigo(inimigo: Dictionary) -> void:
	var chave: String = inimigo["nome"]
	var indice: int = _indice_de(chave)
	if indice == -1:
		return
	inimigos[indice] = inimigo
	if chave == exibido:
		_renderizar_card(inimigo)


func remover_inimigo(inimigo: Dictionary) -> void:
	"""Remove um inimigo da lista (quando derrotado)"""
	var chave: String = inimigo["nome"]
	var indice: int = _indice_de(chave)
	if indice == -1:
		return

	inimigos.remove_at(indice)
	if botoes_inimigos.has(chave):
		(botoes_inimigos[chave] as Button).queue_free()
		botoes_inimigos.erase(chave)
	if inimigo_selecionado_atual == inimigo:
		inimigo_selecionado_atual.clear()

	if chave == exibido:
		exibido = ""
		if inimigos.is_empty():
			card.visible = false
		else:
			_exibir(inimigos[mini(indice, inimigos.size() - 1)]["nome"])


func limpar_inimigos() -> void:
	"""Remove todos os inimigos da lista"""
	for icone in botoes_inimigos.values():
		(icone as Button).queue_free()
	botoes_inimigos.clear()
	inimigos.clear()
	inimigo_selecionado_atual.clear()
	exibido = ""
	card.visible = false


func atualizar_todos(inimigos_novos: Array[Dictionary]) -> void:
	"""Atualiza toda a lista de inimigos"""
	limpar_inimigos()
	for inimigo in inimigos_novos:
		adicionar_inimigo(inimigo)

# ============================================================================
# SELEÇÃO E ESCOLHA DE ALVO
# ============================================================================

# Passa ao inimigo seguinte (+1) ou anterior (-1), de forma circular.
func navegar(passo: int) -> void:
	if inimigos.is_empty():
		return
	var indice: int = _indice_de(exibido)
	if indice == -1:
		indice = 0
	else:
		indice = posmod(indice + passo, inimigos.size())
	_exibir(inimigos[indice]["nome"])


func ativar_seletor_alvo() -> void:
	if modo_seletor_ativo:
		return
	modo_seletor_ativo = true
	_aplicar_variacao_a_todos(VARIACAO_ALVO)
	modo_alvo_alterado.emit(true)


func desativar_seletor_alvo() -> void:
	"""Desativa o modo de seleção de alvo"""
	if not modo_seletor_ativo:
		return
	modo_seletor_ativo = false
	_aplicar_variacao_a_todos(VARIACAO_NORMAL)
	modo_alvo_alterado.emit(false)


# Esc ou clique no campo de batalha.
func cancelar_selecao_alvo() -> void:
	if not modo_seletor_ativo:
		return
	desativar_seletor_alvo()
	selecao_alvo_cancelada.emit()


func obter_inimigo_selecionado() -> Dictionary:
	"""Retorna o inimigo atualmente selecionado"""
	return inimigo_selecionado_atual


func _on_icone_pressionado(nome: String) -> void:
	_exibir(nome)
	if modo_seletor_ativo:
		_confirmar_alvo()


# Confirma como alvo o inimigo que está no card.
func _confirmar_alvo() -> void:
	var indice: int = _indice_de(exibido)
	if indice == -1:
		return
	inimigo_selecionado_atual = inimigos[indice]
	inimigo_selecionado.emit(inimigos[indice])
	desativar_seletor_alvo()


func _unhandled_input(event: InputEvent) -> void:
	if not modo_seletor_ativo:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cancelar_selecao_alvo()
	elif event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_confirmar_alvo()


# Mostra ou esconde o marcador de "painel que recebe Q e Espaço".
func definir_marcador(visivel: bool) -> void:
	marcador.visible = visivel

# ============================================================================
# APRESENTAÇÃO
# ============================================================================

func _criar_icone(inimigo: Dictionary) -> Button:
	var nome: String = inimigo["nome"]
	var icone := CENA_ICONE.instantiate() as Button
	icone.tooltip_text = nome
	var textura: Texture2D = texturas_icones.get(nome, null)
	if textura != null:
		icone.icon = textura
	icone.theme_type_variation = VARIACAO_ALVO if modo_seletor_ativo else VARIACAO_NORMAL
	icone.pressed.connect(_on_icone_pressionado.bind(nome))
	coluna_icones.add_child(icone)
	return icone


func _exibir(nome: String) -> void:
	var indice: int = _indice_de(nome)
	if indice == -1:
		return
	exibido = nome
	card.visible = true
	for chave in botoes_inimigos:
		(botoes_inimigos[chave] as Button).set_pressed_no_signal(chave == nome)
	_renderizar_card(inimigos[indice])


func _aplicar_variacao_a_todos(variacao: StringName) -> void:
	for icone in botoes_inimigos.values():
		(icone as Button).theme_type_variation = variacao


func _renderizar_card(inimigo: Dictionary) -> void:
	var estresse_total: int = 0
	var limite_total: int = 0

	var regioes: Dictionary = inimigo.get("estresse_por_regiao", {})

	for regiao_data in regioes.values():
		estresse_total += int(regiao_data.get("atual", 0))
		limite_total += int(regiao_data.get("limite", 0))

	nome_label.text = String(inimigo.get("nome", "Inimigo"))
	estresse_label.text = "ESTR %d/%d" % [
		estresse_total,
		limite_total
	]

	barra_estresse.max_value = maxi(limite_total, 1)
	barra_estresse.value = estresse_total

	var analisado: bool = bool(
		inimigo.get("informacoes_reveladas", false)
	)

	if not analisado:
		regioes_label.text = _texto_regioes_ocultas()
		fixos_label.text = "ATRIBUTOS FIXOS\n???"
		mutaveis_label.text = "ATRIBUTOS MUTÁVEIS\n???"
		status_label.text = "STATUS\n???"
		return

	regioes_label.text = _texto_regioes(inimigo)
	fixos_label.text = _texto_atributos_fixos(inimigo)
	mutaveis_label.text = _texto_atributos_mutaveis(inimigo)
	status_label.text = _texto_status(inimigo)


func _texto_regioes_ocultas() -> String:
	var texto: String = "[b]REGIÕES[/b]\n"

	for regiao in CombatenteData.REGIOES:
		texto += "%s ??/?\n" % regiao

	return texto


func _texto_regioes(inimigo: Dictionary) -> String:
	var texto: String = "[b]REGIÕES[/b]\n"
	var regioes: Dictionary = inimigo.get("estresse_por_regiao", {})

	for regiao in CombatenteData.REGIOES:
		var dados: Dictionary = regioes.get(regiao, {})
		var atual: int = int(dados.get("atual", 0))
		var limite: int = int(dados.get("limite", 0))

		var linha: String = "%s %d/%d" % [
			regiao,
			atual,
			limite
		]

		if limite == 0:
			linha = "[color=red]%s PERDIDO[/color]" % regiao
		elif atual >= limite:
			linha = "[color=red]%s[/color]" % linha
		elif float(atual) / float(limite) > 0.7:
			linha = "[color=orange]%s[/color]" % linha

		texto += linha + "\n"

	return texto


func _texto_atributos_fixos(inimigo: Dictionary) -> String:
	return "[b]ATRIBUTOS FIXOS[/b]\n" + \
		"Carne: %d | Força: %d\n" % [
			int(inimigo.get("atributo_carne", 0)),
			int(inimigo.get("atributo_forca", 0))
		] + \
		"Mente: %d | Fuga: %d\n" % [
			int(inimigo.get("atributo_mente", 0)),
			int(inimigo.get("atributo_fuga", 0))
		] + \
		"Determinação: %d" % [
			int(inimigo.get("atributo_determinacao", 0))
		]


func _texto_atributos_mutaveis(inimigo: Dictionary) -> String:
	var protecao_base: int = int(
		inimigo.get("atributo_protecao", 0)
	)

	var reducao: int = int(
		inimigo.get("reducao_protecao_temporaria", 0)
	)

	var protecao_atual: int = maxi(0, protecao_base - reducao)

	return "[b]ATRIBUTOS MUTÁVEIS[/b]\n" + \
		"Fôlego: %d | Dano: %d\n" % [
			int(inimigo.get("atributo_folego", 0)),
			int(inimigo.get("atributo_dano", 0))
		] + \
		"Coragem: %d | Velocidade: %d\n" % [
			int(inimigo.get("atributo_coragem", 0)),
			int(inimigo.get("atributo_velocidade", 0))
		] + \
		"Proteção: %d/%d" % [
			protecao_atual,
			protecao_base
		]


func _texto_status(inimigo: Dictionary) -> String:
	var linhas: Array[String] = []

	if inimigo.get("habilidade_sobrecarga_ativa", false):
		linhas.append("[color=orange]SOBRECARGA[/color]")

	var status: Array = inimigo.get("status", [])

	for efeito in status:
		if efeito is Dictionary:
			linhas.append(
				"[color=red]%s[/color]" % String(
					efeito.get("nome", "Status desconhecido")
				)
			)
		else:
			linhas.append(String(efeito))

	var proteses: Dictionary = inimigo.get("proteses", {})

	for nome_protese in proteses.keys():
		linhas.append("Prótese: %s" % String(nome_protese))

	if linhas.is_empty():
		return "[b]STATUS[/b]\nNenhum"

	return "[b]STATUS[/b]\n" + "\n".join(linhas)


func _indice_de(nome: String) -> int:
	for i in range(inimigos.size()):
		if inimigos[i]["nome"] == nome:
			return i
	return -1
