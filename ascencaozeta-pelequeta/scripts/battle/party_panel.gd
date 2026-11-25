extends PanelContainer
class_name PartyPanel

# ============================================================
# PAINEL DA PARTY
# A estrutura (card, coluna de ícones, marcador) vive em
# combat.tscn e party_card.tscn. Este script só preenche os
# textos e controla a seleção: um card por vez, um ícone por aliado.
# Contrato com o CombatManager: atualizar_todos, adicionar_personagem,
# atualizar_personagem, remover_personagem, limpar_personagens,
# indicar_personagem_ativo, remover_destaque_turno, obter_personagem_ativo.
# ============================================================

const CENA_ICONE: PackedScene = preload("res://scenes/battle/icone_personagem.tscn")
const ORDEM_REGIOES: Array[String] = [
	"Torso", "Braço Direito", "Braço Esquerdo", "Perna Direita", "Perna Esquerda"
]
const VARIACAO_NORMAL: StringName = &"IconePersonagem"
const VARIACAO_DESMAIADO: StringName = &"IconeDesmaiado"

# Preenchidos no Inspector.
@export var estilo_turno_ativo: StyleBox
@export var texturas_icones: Dictionary[String, Texture2D] = {}
@export var fundo_icones: Texture2D
@onready var coluna_icones: HBoxContainer = %PartyIcones
@onready var card: PanelContainer = %PartyCard
@onready var marcador: Panel = %MarcadorParty
@onready var label_nome: Label = card.get_node("%NomeLabel")
@onready var label_pa: Label = card.get_node("%PaLabel")
@onready var label_regioes: RichTextLabel = card.get_node("%RegioesLabel")
@onready var label_pro: Label = card.get_node("%ProLabel")

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
@onready var label_status: RichTextLabel = card.get_node("%StatusLabel")

var personagens: Array[Dictionary] = []
var icones: Dictionary = {}  # nome -> Button
var exibido: String = ""     # nome do aliado cujo card está na tela
var personagem_ativo_atual: Dictionary = {}

# ============================================================================
# GERENCIAMENTO DE PERSONAGENS
# ============================================================================

func adicionar_personagem(personagem: Dictionary) -> void:
	if not _valido(personagem):
		return
	personagens.append(personagem)
	icones[personagem["nome"]] = _criar_icone(personagem)
	_atualizar_icone(personagem)
	if exibido.is_empty():
		_exibir(personagem["nome"])
	else:
		_atualizar_destaques()


func atualizar_personagem(personagem: Dictionary) -> void:
	"""Atualiza o personagem. Remove se morreu."""
	if not personagem.has("nome"):
		return
	if personagem.get("morto", false):
		remover_personagem(personagem)
		return

	var indice: int = _indice_de(personagem["nome"])
	if indice == -1:
		return
	personagens[indice] = personagem
	_atualizar_icone(personagem)
	if personagem["nome"] == exibido:
		_renderizar_card(personagem)


func remover_personagem(personagem: Dictionary) -> void:
	"""Remove um personagem do painel (derrotado)"""
	var chave: String = personagem["nome"]
	var indice: int = _indice_de(chave)
	if indice == -1:
		return

	personagens.remove_at(indice)
	if icones.has(chave):
		(icones[chave] as Button).queue_free()
		icones.erase(chave)
	if personagem_ativo_atual.get("nome", "") == chave:
		personagem_ativo_atual.clear()
		DestaqueTurno.remover(self)
	if chave == exibido:
		exibido = ""
		if personagens.is_empty():
			card.visible = false
		else:
			_exibir(personagens[mini(indice, personagens.size() - 1)]["nome"])


func limpar_personagens() -> void:
	for icone in icones.values():
		(icone as Button).queue_free()
	icones.clear()
	personagens.clear()
	DestaqueTurno.remover(self)
	personagem_ativo_atual.clear()
	exibido = ""
	card.visible = false


func atualizar_todos(personagens_novos: Array[Dictionary]) -> void:
	"""Atualiza toda a lista de personagens"""
	limpar_personagens()
	for personagem in personagens_novos:
		adicionar_personagem(personagem)

# ============================================================================
# SELEÇÃO
# ============================================================================

# Passa ao aliado seguinte (+1) ou anterior (-1), de forma circular.
func navegar(passo: int) -> void:
	if personagens.is_empty():
		return
	var indice: int = _indice_de(exibido)
	if indice == -1:
		indice = 0
	else:
		indice = posmod(indice + passo, personagens.size())
	_exibir(personagens[indice]["nome"])


func _exibir(nome: String) -> void:
	var indice: int = _indice_de(nome)
	if indice == -1:
		return
	exibido = nome
	card.visible = true
	for chave in icones:
		(icones[chave] as Button).set_pressed_no_signal(chave == nome)
	_renderizar_card(personagens[indice])
	_atualizar_destaques()


func _on_icone_pressionado(nome: String) -> void:
	_exibir(nome)  # também religa o estado "pressionado" do ícone clicado

# ============================================================================
# TURNO ATIVO
# ============================================================================

func indicar_personagem_ativo(personagem: Dictionary) -> void:
	"""Destaca o personagem do turno e passa o card para ele"""
	personagem_ativo_atual = personagem
	if _indice_de(personagem["nome"]) != -1:
		_exibir(personagem["nome"])
	else:
		_atualizar_destaques()


func remover_destaque_turno() -> void:
	personagem_ativo_atual.clear()
	_atualizar_destaques()


func obter_personagem_ativo() -> Dictionary:
	return personagem_ativo_atual

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

func _criar_icone(personagem: Dictionary) -> Button:
	var nome: String = personagem["nome"]
	var icone := CENA_ICONE.instantiate() as Button
	_aplicar_fundo_icone(icone)
	icone.tooltip_text = nome
	var textura: Texture2D = texturas_icones.get(
		PersonagensData.normalizar_id(nome), null
	)
	if textura != null:
		icone.icon = textura
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

# Aliado desmaiado fica escurecido (variação de tema); continua selecionável.
func _atualizar_icone(personagem: Dictionary) -> void:
	var icone := icones.get(personagem["nome"], null) as Button
	if icone == null:
		return
	if personagem.get("desmaiado", false):
		icone.theme_type_variation = VARIACAO_DESMAIADO
	else:
		icone.theme_type_variation = VARIACAO_NORMAL

func _atualizar_destaques() -> void:
	var ativo: String = personagem_ativo_atual.get("nome", "")
	if not ativo.is_empty() and exibido == ativo:
		DestaqueTurno.aplicar(self, estilo_turno_ativo)
	else:
		DestaqueTurno.remover(self)

func _renderizar_card(p: Dictionary) -> void:
	var texto_nome: String = p["nome"]

	if p.has("status") and not p["status"].is_empty():
		texto_nome += " [%s]" % ", ".join(p["status"])

	label_nome.text = texto_nome

	# Pontos de ação.
	label_pa.text = "PA %d/%d" % [
		int(p.get("pontos_acao_atuais", 0)),
		int(p.get("pontos_acao_maximos", 0))
	]

	# Proteção atual e máxima.
	var protecao_maxima: int = int(
		p.get("atributo_protecao", 0)
	)

	var reducao_protecao: int = int(
		p.get("reducao_protecao_temporaria", 0)
	)

	var protecao_atual: int = maxi(
		0,
		protecao_maxima - reducao_protecao
	)

	label_pro.text = "PRO %d/%d" % [
		protecao_atual,
		protecao_maxima
	]

	# Regiões e Estresse.
	label_regioes.text = _texto_regioes(p)

	# Atributos fixos.
	valor_car.text = str(int(p.get("atributo_carne", 0)))
	valor_for.text = str(int(p.get("atributo_forca", 0)))
	valor_fug.text = str(int(p.get("atributo_fuga", 0)))
	valor_det.text = str(int(p.get("atributo_determinacao", 0)))
	valor_men.text = str(int(p.get("atributo_mente", 0)))

	# Atributos mutáveis.
	# ValorPro mostra somente a proteção máxima.
	valor_pro.text = str(protecao_maxima)
	valor_fol.text = str(int(p.get("atributo_folego", 0)))
	valor_dan.text = str(int(p.get("atributo_dano", 0)))
	valor_cor.text = str(int(p.get("atributo_coragem", 0)))
	valor_vel.text = str(int(p.get("atributo_velocidade", 0)))

	# Status e condições especiais.
	var especial: String = ""
	if p.get("habilidade_sobrecarga_ativa", false):
		especial += "SOBRECARGA "

	if p.has("proteses") and not p["proteses"].is_empty():
		especial += "[PR: %s]" % ", ".join(p["proteses"].keys())

	label_status.text = especial

func _texto_regioes(p: Dictionary) -> String:
	var texto: String = ""
	for regiao in ORDEM_REGIOES:
		if not p["estresse_por_regiao"].has(regiao):
			continue
		var dados: Dictionary = p["estresse_por_regiao"][regiao]
		var atual: int = dados["atual"]
		var limite: int = dados["limite"]
		var linha: String = "%s %d/%d" % [regiao, atual, limite]
		if limite == 0:
			linha = "[color=red]%s 0/0[/color]" % regiao
		elif atual >= limite:
			linha = "[color=red]%s[/color]" % linha
		elif float(atual) / float(limite) > 0.7:
			linha = "[color=orange]%s[/color]" % linha
		texto += linha + "\n"
	return texto

# ============================================================================
# UTILIDADES
# ============================================================================

func _valido(personagem: Dictionary) -> bool:
	if not personagem.has("nome"):
		print("[PartyPanel] ERRO: Personagem sem nome")
		return false
	if not personagem.has("estresse_por_regiao"):
		print("[PartyPanel] ERRO: Personagem '%s' sem dados de estresse" % personagem["nome"])
		return false
	return true


func _indice_de(nome: String) -> int:
	for i in range(personagens.size()):
		if personagens[i]["nome"] == nome:
			return i
	return -1
