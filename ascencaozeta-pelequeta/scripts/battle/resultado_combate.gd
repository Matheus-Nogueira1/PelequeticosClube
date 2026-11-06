extends Control
class_name ResultadoCombate

# ============================================================
# TELA DE RESULTADOS DO COMBATE
# Toda a interface é construída no editor (resultado_combate.tscn).
# Este script só preenche os nós existentes e emite "confirmado".
# Contrato de dados (Dictionary), tudo opcional:
#   resultado: String ("Vitória", "Derrota" ou "Fuga")
#   subtitulo: String
#   resumo:    Array de textos
#   fardos:    Array de textos
#   almas:     int
#   itens:     Array de {"nome": String, "quantidade": int}
# ============================================================

signal confirmado

@onready var titulo: Label = %TituloResultado
@onready var subtitulo: Label = %Subtitulo
@onready var resumo: RichTextLabel = %Resumo
@onready var secao_fardos: Label = %SecaoFardos
@onready var fardos: RichTextLabel = %Fardos
@onready var secao_recompensas: Label = %SecaoRecompensas
@onready var recompensas: RichTextLabel = %Recompensas
@onready var botao_continuar: Button = get_node_or_null("%BotaoContinuar") as Button

var _dados: Dictionary = {}
var _pronto: bool = false


func _ready() -> void:
	if botao_continuar != null:
		botao_continuar.pressed.connect(_confirmar)
		botao_continuar.grab_focus()
	else:
		push_warning("[ResultadoCombate] BotaoContinuar não existe: só o teclado confirma.")
	_atualizar()


# Ponto de entrada: pode ser chamado antes ou depois do _ready.
func configurar(dados: Dictionary) -> void:
	_dados = dados
	_pronto = true
	if is_node_ready():
		_atualizar()


func _atualizar() -> void:
	titulo.text = String(_dados.get("resultado", "")).to_upper()

	subtitulo.visible = _dados.has("subtitulo")
	if subtitulo.visible:
		subtitulo.text = String(_dados["subtitulo"])

	resumo.text = _juntar_linhas(_dados.get("resumo", []))

	var lista_fardos: Array = _dados.get("fardos", [])
	secao_fardos.visible = not lista_fardos.is_empty()
	fardos.visible = secao_fardos.visible
	fardos.text = _juntar_linhas(lista_fardos)

	# Recompensas só aparecem quando existirem dados válidos.
	var linhas: Array = []
	if _dados.has("almas"):
		linhas.append("Almas: %d" % int(_dados["almas"]))
	for item in _dados.get("itens", []):
		linhas.append("%s x%d" % [str(item.get("nome", "?")), int(item.get("quantidade", 1))])
	secao_recompensas.visible = not linhas.is_empty()
	recompensas.visible = secao_recompensas.visible
	recompensas.text = _juntar_linhas(linhas)


func _juntar_linhas(linhas: Array) -> String:
	var texto := ""
	for linha in linhas:
		texto += "%s\n" % str(linha)
	return texto.strip_edges()


# _input (e não _unhandled_input) para o Enter não ser consumido
# por algum botão que ainda tenha foco.
func _input(event: InputEvent) -> void:
	if _pronto and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_confirmar()


func _confirmar() -> void:
	if not _pronto:
		return
	_pronto = false
	confirmado.emit()
