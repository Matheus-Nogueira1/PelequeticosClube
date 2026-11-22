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
enum Pagina { CLASSIFICACAO, RECOMPENSA, ESTATISTICAS }

@export var pagina_recompensa: Control

# Itens ganhos nas rolagens (lidos pelo CombatManager depois do "confirmado").
var itens_obtidos: Array[Dictionary] = []

@onready var recompensa_titulo: Label = _label("RecompensaTitulo")
@onready var recompensa_bonus: Label = _label("RecompensaBonus")
@onready var recompensa_detalhe: Label = _label("RecompensaDetalhe")
@onready var recompensa_itens: RichTextLabel = get_node_or_null("%RecompensaItens") as RichTextLabel
@onready var botao_rolar: Button = get_node_or_null("%BotaoRolar") as Button
@onready var botao_pular: Button = get_node_or_null("%BotaoPular") as Button
@onready var botao_recompensa_ok: Button = get_node_or_null("%BotaoRecompensaOk") as Button
@onready var dado: RolagemD6 = get_node_or_null("%DadoRecompensa") as RolagemD6

var _pagina: int = Pagina.CLASSIFICACAO
var _fila_inimigos: Array[String] = []
var _indice_recompensa: int = 0
var _rolou: bool = false
var _rolando: bool = false

func _ready() -> void:
	if botao_continuar != null:
		botao_continuar.pressed.connect(_avancar)
	else:
		push_warning("[ResultadoCombate] BotaoContinuar não encontrado.")

	_atualizar()
	if botao_rolar != null:
		botao_rolar.pressed.connect(_rolar_recompensa)
	if botao_pular != null:
		botao_pular.pressed.connect(_pular_recompensa)
	if botao_recompensa_ok != null:
		botao_recompensa_ok.pressed.connect(_avancar)

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
	_mostrar_pagina(Pagina.CLASSIFICACAO)
	_preparar_recompensas()

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

	_atualizar_recompensas()

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
# _input (e não _unhandled_input) para o Enter não ser consumido por um
# botão com foco. Ignora o Enter segurado (eco). Esc pula a rolagem atual.
func _input(event: InputEvent) -> void:
	if not _pronto or event.is_echo():
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_acao_principal()
	elif event.is_action_pressed("ui_cancel") and _pagina == Pagina.RECOMPENSA:
		get_viewport().set_input_as_handled()
		_pular_recompensa()

# Prepara a fila: uma rolagem por inimigo derrotado, só em Vitória.
func _preparar_recompensas() -> void:
	itens_obtidos.clear()
	_fila_inimigos.clear()
	_indice_recompensa = 0
	if not bool(_dados.get("recompensa_habilitada", false)):
		return
	for nome in _dados.get("inimigos_derrotados", []):
		_fila_inimigos.append(String(nome))


# Seção "Recompensas" da página de estatísticas (Almas e Itens).
func _atualizar_recompensas() -> void:
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


func _mostrar_pagina(pagina: int) -> void:
	_pagina = pagina
	_definir_visivel(secao_classificacao, pagina == Pagina.CLASSIFICACAO)
	_definir_visivel(pagina_recompensa, pagina == Pagina.RECOMPENSA)
	_definir_visivel(secao_estatisticas, pagina == Pagina.ESTATISTICAS)
	if pagina != Pagina.RECOMPENSA:
		_definir_visivel(dado, false)

	var botao: Button = botao_continuar
	if pagina == Pagina.RECOMPENSA:
		botao = botao_rolar
	elif pagina == Pagina.ESTATISTICAS:
		botao = botao_continuar
	if botao != null:
		botao.grab_focus()


func _definir_visivel(no: CanvasItem, visivel: bool) -> void:
	if no != null:
		no.visible = visivel


func _rank() -> String:
	return String(_dados.get("estatisticas", {}).get("rank", ""))


func _tem_estatisticas() -> bool:
	return not _dados.get("estatisticas", {}).is_empty()


# Abre a rolagem do inimigo atual.
func _abrir_recompensa() -> void:
	_rolou = false
	_mostrar_pagina(Pagina.RECOMPENSA)
	var modificador: int = RecompensaCombate.modificador_do_rank(_rank())
	if recompensa_titulo != null:
		recompensa_titulo.text = "Recompensa: %s" % _fila_inimigos[_indice_recompensa]
	if recompensa_bonus != null:
		recompensa_bonus.text = "Bônus de recompensa: %s" % RecompensaCombate.texto_modificador(modificador)
	if recompensa_detalhe != null:
		recompensa_detalhe.text = ""
	if recompensa_itens != null:
		recompensa_itens.text = ""
	_definir_visivel(botao_rolar, true)
	_definir_visivel(botao_pular, true)
	_definir_visivel(botao_recompensa_ok, false)
	if botao_rolar != null:
		botao_rolar.grab_focus()


# O D6 é sorteado uma vez; a animação mostra exatamente esse valor.
func _rolar_recompensa() -> void:
	if _pagina != Pagina.RECOMPENSA or _rolando or _rolou:
		return
	_rolando = true
	_definir_visivel(botao_rolar, false)
	_definir_visivel(botao_pular, false)

	var inimigo: String = _fila_inimigos[_indice_recompensa]
	var r: Dictionary = RecompensaCombate.rolar(_rank(), inimigo)

	if dado != null:
		dado.visible = true
		await dado.rodar_e_mostrar_face(int(r["natural"]))

	if recompensa_detalhe != null:
		recompensa_detalhe.text = "D6: %d | Bônus: %s | Final: %d" % [
			int(r["natural"]),
			RecompensaCombate.texto_modificador(int(r["modificador"])),
			int(r["final"])
		]
	if recompensa_itens != null:
		recompensa_itens.text = String(r["mensagem"])
	_acumular_itens(r["itens"])

	_rolando = false
	_rolou = true
	_definir_visivel(botao_recompensa_ok, true)
	if botao_recompensa_ok != null:
		botao_recompensa_ok.grab_focus()


# Pular dispensa a rolagem deste inimigo e segue para o próximo passo.
func _pular_recompensa() -> void:
	if _pagina != Pagina.RECOMPENSA or _rolando or _rolou:
		return
	_rolou = true
	_avancar()


func _acumular_itens(novos: Array) -> void:
	for item in novos:
		var nome: String = String(item["nome"])
		var quantidade: int = int(item["quantidade"])
		var achou: bool = false
		for existente in itens_obtidos:
			if existente["nome"] == nome:
				existente["quantidade"] = int(existente["quantidade"]) + quantidade
				achou = true
				break
		if not achou:
			itens_obtidos.append({"nome": nome, "quantidade": quantidade})
	# Reflete na seção "Recompensas" das estatísticas.
	_dados["itens"] = itens_obtidos.duplicate(true)
	_atualizar_recompensas()


# Enter e Espaço (ui_accept): rola se ainda não rolou, senão avança.
func _acao_principal() -> void:
	if not _pronto or _rolando:
		return
	if _pagina == Pagina.RECOMPENSA and not _rolou:
		_rolar_recompensa()
	else:
		_avancar()


func _avancar() -> void:
	if not _pronto or _rolando:
		return
	match _pagina:
		Pagina.CLASSIFICACAO:
			if _indice_recompensa < _fila_inimigos.size():
				_abrir_recompensa()
			elif _tem_estatisticas():
				_mostrar_pagina(Pagina.ESTATISTICAS)
			else:
				_encerrar()
		Pagina.RECOMPENSA:
			if not _rolou:
				return
			_indice_recompensa += 1
			if _indice_recompensa < _fila_inimigos.size():
				_abrir_recompensa()
			elif _tem_estatisticas():
				_mostrar_pagina(Pagina.ESTATISTICAS)
			else:
				_encerrar()
		Pagina.ESTATISTICAS:
			_encerrar()


func _encerrar() -> void:
	_pronto = false
	confirmado.emit()
