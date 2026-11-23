extends Control
class_name FichaInimigo

# ============================================================
# FICHA COMPLETA DO INIMIGO
# Toda a estrutura vive em ficha_inimigo.tscn. Este script só
# preenche os campos a partir do Dictionary do inimigo e fecha.
# Informações mecânicas ficam como ??? até o inimigo ser analisado
# (a mesma regra do card do EnemyPanel).
# ============================================================

signal fechada

const OCULTO: String = "???"

# Preencha no Inspector (chave = nome do inimigo).
@export var retratos: Dictionary[String, Texture2D] = {}

@onready var nome: Label = %FichaNome
@onready var grau: Label = %FichaGrau
@onready var descricao: Label = %FichaDescricao
@onready var val_car: Label = %ValCar
@onready var val_for: Label = %ValFor
@onready var val_fug: Label = %ValFug
@onready var val_det: Label = %ValDet
@onready var val_men: Label = %ValMen
@onready var dano: Label = %FichaDano
@onready var protecao: Label = %FichaProtecao
@onready var velocidade: Label = %FichaVelocidade
@onready var tamanho: Label = %FichaTamanho
@onready var limite: Label = %FichaLimite
@onready var conhecimento: Label = %FichaConhecimento
@onready var habilidades: RichTextLabel = %FichaHabilidades
@onready var retrato: TextureRect = %FichaRetrato
@onready var botao_fechar: Button = %FichaFechar

var _habilidades_db: HabilidadeData = HabilidadeData.new()


func _ready() -> void:
	visible = false
	botao_fechar.pressed.connect(fechar)


func abrir(inimigo: Dictionary) -> void:
	var analisado: bool = bool(
		inimigo.get("informacoes_reveladas", false)
	)

	nome.text = String(inimigo.get("nome", ""))
	var g: int = int(inimigo.get("grau", 0))
	grau.visible = g > 0
	grau.text = "Grau %d" % g

	var texto_descricao: String = String(inimigo.get("descricao", ""))
	descricao.visible = not texto_descricao.is_empty()
	descricao.text = texto_descricao

	var texto_tamanho: String = String(inimigo.get("tamanho", ""))
	tamanho.visible = not texto_tamanho.is_empty()
	tamanho.text = "Tamanho: %s" % texto_tamanho

	val_car.text = _numero(inimigo, "atributo_carne", analisado)
	val_for.text = _numero(inimigo, "atributo_forca", analisado)
	val_fug.text = _numero(inimigo, "atributo_fuga", analisado)
	val_det.text = _numero(inimigo, "atributo_determinacao", analisado)
	val_men.text = _numero(inimigo, "atributo_mente", analisado)

	dano.text = "Dano: %s" % _numero(inimigo, "atributo_dano", analisado)
	velocidade.text = "Velocidade: %s" % _numero(inimigo, "atributo_velocidade", analisado)
	if analisado:
		var base: int = int(inimigo.get("atributo_protecao", 0))
		var atual: int = maxi(0, base - int(inimigo.get("reducao_protecao_temporaria", 0)))
		protecao.text = "Proteção: %d/%d" % [atual, base]
	else:
		protecao.text = "Proteção: %s" % OCULTO

	limite.text = _texto_limite(inimigo, analisado)
	conhecimento.text = "Conhecimento especializado: %s" % _texto_conhecimento(inimigo, analisado)
	habilidades.text = _texto_habilidades(inimigo, analisado)

	retrato.texture = retratos.get(nome.text, null)
	retrato.visible = retrato.texture != null

	visible = true


func fechar() -> void:
	if not visible:
		return
	visible = false
	fechada.emit()


# _input (e não _unhandled_input) para consumir Esc e Enter antes
# do combate, que usa as mesmas teclas (alvo, leitura).
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") \
			or (event.is_action_pressed("ui_accept") and not event.is_echo()):
		get_viewport().set_input_as_handled()
		fechar()


func _numero(inimigo: Dictionary, chave: String, analisado: bool) -> String:
	return str(int(inimigo.get(chave, 0))) if analisado else OCULTO


func _texto_limite(inimigo: Dictionary, analisado: bool) -> String:
	var total: int = 0
	var maximo: int = 0
	for dados in inimigo["estresse_por_regiao"].values():
		total += int(dados["atual"])
		maximo += int(dados["limite"])
	var texto: String = "Estresse: %d/%d" % [total, maximo]
	for regiao in CombatenteData.REGIOES:
		if analisado:
			var d: Dictionary = inimigo["estresse_por_regiao"][regiao]
			texto += "\n%s %d/%d" % [regiao, d["atual"], d["limite"]]
		else:
			texto += "\n%s ??/?" % regiao
	return texto


func _texto_conhecimento(inimigo: Dictionary, analisado: bool) -> String:
	if not analisado:
		return OCULTO
	var lista: Array = inimigo.get("conhecimentos_especializados", [])
	return "Nenhum" if lista.is_empty() else ", ".join(lista)


func _texto_habilidades(inimigo: Dictionary, analisado: bool) -> String:
	if not analisado:
		return "[b]Habilidades:[/b] %s" % OCULTO
	var lista: Array = inimigo.get("habilidades", [])
	if lista.is_empty():
		return "[b]Habilidades:[/b] Nenhuma"
	var texto: String = "[b]Habilidades:[/b]"
	for nome_habilidade in lista:
		var hab = _habilidades_db.get_habilidade(String(nome_habilidade))
		if hab == null:
			texto += "\n%s" % nome_habilidade
		else:
			texto += "\n[b]%s[/b] (%s)\n%s" % [hab.nome, hab.descricao, hab.efeito]
	return texto
