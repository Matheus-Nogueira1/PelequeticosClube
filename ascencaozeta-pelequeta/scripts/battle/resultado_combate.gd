extends Control
class_name ResultadoCombate

# ============================================================
# TELA DE RESULTADOS DO COMBATE
# Toda a interface é construída no editor (resultado_combate.tscn).
# Este script só preenche os nós existentes e controla as duas
# páginas: 1) classificação, 2) estatísticas e resumo.
# Contrato de dados (Dictionary), tudo opcional:
#   resultado:    String ("Vitória", "Derrota" ou "Fuga")
#   subtitulo:    String
#   resumo:       Array de textos
#   fardos:       Array de textos
#   almas:        int
#   itens:        Array de {"nome": String, "quantidade": int}
#   estatisticas: Dictionary (veja EstatisticasCombate.montar_resultado)
# ============================================================

signal confirmado

const LETRA_PENDENTE: String = "?"
const NOME_PENDENTE: String = "Classificação pendente"

# Chave do contrato -> nome único do Label de valor na cena.
const CAMPOS_ESTATISTICAS: Dictionary = {
	"dano_causado": "DanoCausado",
	"cura_efetiva": "CuraEfetivada",
	"dano_recebido": "DanoRecebido",
	"aliados_desmaiados": "Desmaios",
	"aliados_reanimados": "Reanimacoes",
	"pontuacao": "Pontuacao"
}
@onready var secao_classificacao: Control = get_node_or_null(
	"Centro/PainelPrincipal/Margem/Classificação"
) as Control

@onready var secao_estatisticas: Control = get_node_or_null(
	"Centro/PainelPrincipal/Margem/Estatisticas"
) as Control
@onready var titulo: Label = _label("TituloResultado")
@onready var subtitulo: Label = _label("Subtitulo")
@onready var resumo: RichTextLabel = get_node_or_null("%Resumo") as RichTextLabel
@onready var secao_fardos: Label = _label("SecaoFardos")
@onready var fardos: RichTextLabel = get_node_or_null("%Fardos") as RichTextLabel
@onready var secao_recompensas: Label = _label("SecaoRecompensas")
@onready var recompensas: RichTextLabel = get_node_or_null("%Recompensas") as RichTextLabel
@onready var rank: Label = _label("Rank")
@onready var nome_classificacao: Label = _label("NomeClassificacao")
@onready var pontuacao_classificacao: Label = _label("PontuacaoClassificacao")
@onready var botao_continuar: Button = get_node_or_null("%BotaoContinuar") as Button

var _dados: Dictionary = {}
var _pronto: bool = false
var _pagina_estatisticas: bool = false


func _ready() -> void:
	if botao_continuar != null:
		botao_continuar.pressed.connect(_confirmar)
	else:
		push_warning("[ResultadoCombate] BotaoContinuar não encontrado.")

	_atualizar()


# Ponto de entrada: pode ser chamado antes ou depois do _ready.
func configurar(dados: Dictionary) -> void:
	_dados = dados
	_pronto = true
	if is_node_ready():
		_atualizar()


func _label(nome: String) -> Label:
	return get_node_or_null("%" + nome) as Label


# ============================================================
# PREENCHIMENTO
# ============================================================
func _atualizar() -> void:
	_mostrar_pagina(false)

	if titulo != null:
		titulo.text = String(_dados.get("resultado", "")).to_upper()
	if subtitulo != null:
		subtitulo.visible = _dados.has("subtitulo")
		if subtitulo.visible:
			subtitulo.text = String(_dados["subtitulo"])

	if resumo != null:
		resumo.text = _juntar_linhas(_dados.get("resumo", []))

	var lista_fardos: Array = _dados.get("fardos", [])
	if secao_fardos != null:
		secao_fardos.visible = not lista_fardos.is_empty()
	if fardos != null:
		fardos.visible = not lista_fardos.is_empty()
		fardos.text = _juntar_linhas(lista_fardos)

	# Recompensas só aparecem quando existirem dados válidos.
	var linhas: Array = []
	if _dados.has("almas"):
		linhas.append("Almas: %d" % int(_dados["almas"]))
	for item in _dados.get("itens", []):
		linhas.append("%s x%d" % [str(item.get("nome", "?")), int(item.get("quantidade", 1))])
	if secao_recompensas != null:
		secao_recompensas.visible = not linhas.is_empty()
	if recompensas != null:
		recompensas.visible = not linhas.is_empty()
		recompensas.text = _juntar_linhas(linhas)

	_atualizar_estatisticas()


func _atualizar_estatisticas() -> void:
	var est: Dictionary = _dados.get("estatisticas", {})
	if est.is_empty():
		return

	var pendente: bool = bool(est.get("rank_pendente", true))
	if rank != null:
		rank.text = LETRA_PENDENTE if pendente else String(est.get("rank", ""))
	if nome_classificacao != null:
		nome_classificacao.text = NOME_PENDENTE if pendente else String(est.get("nome_classificacao", ""))
	if pontuacao_classificacao != null:
		pontuacao_classificacao.text = str(int(est.get("pontuacao", 0)))

	for chave in CAMPOS_ESTATISTICAS:
		var campo: Label = _label(CAMPOS_ESTATISTICAS[chave])
		if campo == null:
			push_warning("[ResultadoCombate] Label '%s' não encontrado." % CAMPOS_ESTATISTICAS[chave])
			continue
		campo.text = str(int(est.get(chave, 0)))


func _juntar_linhas(linhas: Array) -> String:
	var texto := ""
	for linha in linhas:
		texto += "%s\n" % str(linha)
	return texto.strip_edges()


# ============================================================
# PÁGINAS E CONFIRMAÇÃO
# ============================================================
func _mostrar_pagina(estatisticas: bool) -> void:
	_pagina_estatisticas = estatisticas

	if secao_classificacao != null:
		secao_classificacao.visible = not estatisticas

	if secao_estatisticas != null:
		secao_estatisticas.visible = estatisticas

	if botao_continuar != null:
		var possui_estatisticas: bool = not _dados.get("estatisticas", {}).is_empty()

		if estatisticas:
			botao_continuar.text = "Ok"
		elif possui_estatisticas:
			botao_continuar.text = "Próximo"
		else:
			botao_continuar.text = "Ok"

		botao_continuar.grab_focus()

# _input (e não _unhandled_input) para o Enter não ser consumido
# por um botão com foco. Ignora o Enter segurado (eco).
func _input(event: InputEvent) -> void:
	if _pronto and event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_confirmar()


func _confirmar() -> void:
	if not _pronto:
		return
	# Primeira confirmação: da classificação para as estatísticas.
	if not _pagina_estatisticas and not _dados.get("estatisticas", {}).is_empty():
		_mostrar_pagina(true)
		return
	_pronto = false
	confirmado.emit()
