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

@onready var coluna_icones: HBoxContainer = %PartyIcones
@onready var card: PanelContainer = %PartyCard
@onready var marcador: Panel = %MarcadorParty
@onready var label_nome: Label = card.get_node("%NomeLabel")
@onready var label_pa: Label = card.get_node("%PaLabel")
@onready var label_regioes: RichTextLabel = card.get_node("%RegioesLabel")
@onready var label_fixos: RichTextLabel = card.get_node("%FixosLabel")
@onready var label_mutaveis: RichTextLabel = card.get_node("%MutaveisLabel")
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


# Mostra ou esconde o marcador de "painel que recebe Q e Espaço".
func definir_marcador(visivel: bool) -> void:
	marcador.visible = visivel

# ============================================================================
# APRESENTAÇÃO
# ============================================================================

func _criar_icone(personagem: Dictionary) -> Button:
	var nome: String = personagem["nome"]
	var icone := CENA_ICONE.instantiate() as Button
	icone.tooltip_text = nome
	var textura: Texture2D = texturas_icones.get(
		PersonagensData.normalizar_id(nome), null
	)
	if textura != null:
		icone.icon = textura
	icone.pressed.connect(_on_icone_pressionado.bind(nome))
	coluna_icones.add_child(icone)
	return icone


# Aliado desmaiado fica escurecido (variação de tema); continua selecionável.
func _atualizar_icone(personagem: Dictionary) -> void:
	var icone := icones.get(personagem["nome"], null) as Button
	if icone == null:
		return
	if personagem.get("desmaiado", false):
		icone.theme_type_variation = VARIACAO_DESMAIADO
	else:
		icone.theme_type_variation = VARIACAO_NORMAL


# Marcador do ícone do turno e estilo do card quando ele é o exibido.
func _atualizar_destaques() -> void:
	var ativo: String = personagem_ativo_atual.get("nome", "")
	for nome in icones:
		var marca := (icones[nome] as Button).get_node_or_null("%MarcadorTurno") as Control
		if marca != null:
			marca.visible = (nome == ativo)
	if estilo_turno_ativo != null and not ativo.is_empty() and exibido == ativo:
		card.add_theme_stylebox_override("panel", estilo_turno_ativo)
	else:
		card.remove_theme_stylebox_override("panel")



func _renderizar_card(p: Dictionary) -> void:
	var texto_nome: String = p["nome"]
	if p.has("status") and not p["status"].is_empty():
		texto_nome += " [%s]" % ", ".join(p["status"])
	label_nome.text = texto_nome

	label_pa.text = "PA %d/%d" % [
		int(p.get("pontos_acao_atuais", 0)),
		int(p.get("pontos_acao_maximos", 0))
	]

	label_regioes.text = _texto_regioes(p)

	# Atributos fixos: cabeçalho e valores na mesma ordem.
	label_fixos.text = "Car For Fug Det Men\n%d  %d  %d  %d  %d" % [
		int(p.get("atributo_carne", 0)),
		int(p.get("atributo_forca", 0)),
		int(p.get("atributo_fuga", 0)),
		int(p.get("atributo_determinacao", 0)),
		int(p.get("atributo_mente", 0))
	]

	# Proteção atual = base - redução temporária.
	var protecao_base: int = int(p.get("atributo_protecao", 0))
	var protecao_atual: int = maxi(
		0, protecao_base - int(p.get("reducao_protecao_temporaria", 0))
	)

	# Atributos mutáveis: cabeçalho e valores na mesma ordem.
	label_mutaveis.text = "Fôl Dan Cor Pro Vel\n%d  %d  %d  %d/%d  %d" % [
		int(p.get("atributo_folego", 0)),
		int(p.get("atributo_dano", 0)),
		int(p.get("atributo_coragem", 0)),
		protecao_atual,
		protecao_base,
		int(p.get("atributo_velocidade", 0))
	]

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
			linha = "%s PERDIDO" % regiao
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
