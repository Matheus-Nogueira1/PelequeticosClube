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
@export var fundo_icones: Texture2D
@export var estilo_turno_ativo: StyleBox
var inimigo_ativo_atual: Dictionary = {}
@onready var botao_ficha: Button = get_node_or_null("%BotaoFicha") as Button
@onready var coluna_icones: HBoxContainer = %EnemyIcones
@onready var card: PanelContainer = %EnemyCard
@onready var marcador: Panel = %MarcadorEnemy
@onready var nome_label: Label = card.get_node("%NomeLabel")

@onready var pa_label: Label = card.get_node("%PaLabel")
@onready var pro_label: Label = card.get_node("%ProLabel")

@onready var regioes_label: RichTextLabel = card.get_node("%RegioesLabel")
@onready var status_label: RichTextLabel = card.get_node("%StatusLabel")

@onready var valor_car: Label = card.get_node("%ValorCar")
@onready var valor_for: Label = card.get_node("%ValorFor")
@onready var valor_fug: Label = card.get_node("%ValorFug")
@onready var valor_det: Label = card.get_node("%ValorDet")
@onready var valor_men: Label = card.get_node("%ValorMen")

@onready var valor_pro: Label = card.get_node("%ValorPro")
@onready var valor_fol: Label = card.get_node("%ValorFol")
@onready var valor_dan: Label = card.get_node("%ValorDan")
@onready var valor_cor: Label = card.get_node("%ValorCor")
@onready var valor_vel: Label = card.get_node("%ValorVel")
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
	if inimigo_ativo_atual.get("nome", "") == chave:
		inimigo_ativo_atual.clear()
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
	inimigo_ativo_atual.clear()
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

# ============================================================================
# TURNO ATIVO
# ============================================================================

func indicar_inimigo_ativo(inimigo: Dictionary) -> void:
	"""Destaca o inimigo do turno e passa o card para ele"""
	inimigo_ativo_atual = inimigo
	if _indice_de(String(inimigo["nome"])) != -1:
		_exibir(inimigo["nome"])
	else:
		_atualizar_destaques()


func remover_destaque_turno() -> void:
	inimigo_ativo_atual.clear()
	_atualizar_destaques()


func obter_inimigo_ativo() -> Dictionary:
	return inimigo_ativo_atual

func _atualizar_destaques() -> void:
	var ativo: String = inimigo_ativo_atual.get("nome", "")
	if not ativo.is_empty() and exibido == ativo:
		DestaqueTurno.aplicar(self, estilo_turno_ativo)
	else:
		DestaqueTurno.remover(self)

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

func definir_marcador(selecionado: bool) -> void:
	marcador.visible = true

	var estilo := StyleBoxFlat.new()
	estilo.draw_center = false
	estilo.set_border_width_all(3 if selecionado else 1)
	estilo.border_color = Color(0.41568628, 0.09803922, 0.16470589, 1)

	marcador.add_theme_stylebox_override("panel", estilo)

# ============================================================================
# APRESENTAÇÃO
# ============================================================================

func _criar_icone(inimigo: Dictionary) -> Button:
	var nome: String = inimigo["nome"]
	var icone := CENA_ICONE.instantiate() as Button
	_aplicar_fundo_icone(icone)
	icone.tooltip_text = nome
	var textura: Texture2D = texturas_icones.get(nome, null)
	if textura != null:
		icone.icon = textura
	icone.theme_type_variation = VARIACAO_ALVO if modo_seletor_ativo else VARIACAO_NORMAL
	icone.pressed.connect(_on_icone_pressionado.bind(nome))
	coluna_icones.add_child(icone)
	return icone

func _aplicar_fundo_icone(icone: Button) -> void:
	if fundo_icones == null:
		return

	var estilo := StyleBoxTexture.new()
	estilo.texture = fundo_icones
	estilo.draw_center = true

	icone.add_theme_stylebox_override("normal", estilo)
	icone.add_theme_stylebox_override("hover", estilo)
	icone.add_theme_stylebox_override("pressed", estilo)
	icone.add_theme_stylebox_override("hover_pressed", estilo)

func _exibir(nome: String) -> void:
	var indice: int = _indice_de(nome)
	if indice == -1:
		return
	exibido = nome
	card.visible = true
	for chave in botoes_inimigos:
		(botoes_inimigos[chave] as Button).set_pressed_no_signal(chave == nome)
	_renderizar_card(inimigos[indice])
	_atualizar_destaques()

func _aplicar_variacao_a_todos(variacao: StringName) -> void:
	for icone in botoes_inimigos.values():
		(icone as Button).theme_type_variation = variacao

func _renderizar_card(inimigo: Dictionary) -> void:
	nome_label.text = String(inimigo.get("nome", "Inimigo"))

	# Pontos de ação.
	pa_label.text = "PA %d/%d" % [
		int(inimigo.get("pontos_acao_atuais", 0)),
		int(inimigo.get("pontos_acao_maximos", 0))
	]

	var analisado: bool = bool(
		inimigo.get("informacoes_reveladas", false)
	)

	# Informações ocultas antes da análise.
	if not analisado:
		regioes_label.text = _texto_regioes_ocultas()
		pro_label.text = "PRO ?/?"

		valor_car.text = "?"
		valor_for.text = "?"
		valor_fug.text = "?"
		valor_det.text = "?"
		valor_men.text = "?"

		valor_pro.text = "?"
		valor_fol.text = "?"
		valor_dan.text = "?"
		valor_cor.text = "?"
		valor_vel.text = "?"

		status_label.text = "[b]STATUS[/b]\n???"
		return

	# Proteção atual e máxima.
	var protecao_maxima: int = int(
		inimigo.get("atributo_protecao", 0)
	)

	var reducao_protecao: int = int(
		inimigo.get("reducao_protecao_temporaria", 0)
	)

	var protecao_atual: int = maxi(
		0,
		protecao_maxima - reducao_protecao
	)

	pro_label.text = "PRO %d/%d" % [
		protecao_atual,
		protecao_maxima
	]

	# Regiões e Estresse.
	regioes_label.text = _texto_regioes(inimigo)

	# Atributos fixos.
	valor_car.text = str(int(inimigo.get("atributo_carne", 0)))
	valor_for.text = str(int(inimigo.get("atributo_forca", 0)))
	valor_fug.text = str(int(inimigo.get("atributo_fuga", 0)))
	valor_det.text = str(int(inimigo.get("atributo_determinacao", 0)))
	valor_men.text = str(int(inimigo.get("atributo_mente", 0)))

	# Atributos mutáveis.
	valor_pro.text = str(protecao_maxima)
	valor_fol.text = str(int(inimigo.get("atributo_folego", 0)))
	valor_dan.text = str(int(inimigo.get("atributo_dano", 0)))
	valor_cor.text = str(int(inimigo.get("atributo_coragem", 0)))
	valor_vel.text = str(int(inimigo.get("atributo_velocidade", 0)))

	# Status e condições especiais.
	status_label.text = _texto_status(inimigo)

func _texto_regioes_ocultas() -> String:
	var texto: String = ""

	for regiao in CombatenteData.REGIOES:
		texto += "%s ??/?\n" % regiao

	return texto

func _texto_regioes(inimigo: Dictionary) -> String:
	var texto: String = ""
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
			linha = "[color=red]%s 0/0[/color]" % regiao
		elif atual >= limite:
			linha = "[color=red]%s[/color]" % linha
		elif float(atual) / float(limite) > 0.7:
			linha = "[color=orange]%s[/color]" % linha

		texto += linha + "\n"

	return texto

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
