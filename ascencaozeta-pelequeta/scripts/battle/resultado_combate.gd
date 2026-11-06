extends Control
class_name ResultadoCombate

# ============================================================
# TELA DE RESULTADOS DO COMBATE
# Independente do CombatManager: recebe um Dictionary em
# configurar() e emite "confirmado" quando o jogador continua.
# ============================================================

signal confirmado

const TEMA: Theme = preload("res://themes/oblivio_theme.tres")
const TAMANHO_FONTE: int = 8

var _dados: Dictionary = {}
var _pronto: bool = false
var _titulo: Label
var _corpo: RichTextLabel
var _dica: Label


func _ready() -> void:
	theme = TEMA
	_construir_layout()
	_atualizar()


# Ponto de entrada: pode ser chamado antes ou depois do _ready.
func configurar(dados: Dictionary) -> void:
	_dados = dados
	_pronto = true
	if _titulo != null:
		_atualizar()


func _construir_layout() -> void:
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.75)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var painel := PanelContainer.new()
	centro.add_child(painel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	painel.add_child(vbox)

	_titulo = Label.new()
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.add_theme_font_size_override("font_size", TAMANHO_FONTE + 2)
	vbox.add_child(_titulo)

	_corpo = RichTextLabel.new()
	_corpo.bbcode_enabled = true
	_corpo.fit_content = true
	_corpo.scroll_active = false
	_corpo.custom_minimum_size = Vector2(228, 0)
	_corpo.add_theme_font_size_override("normal_font_size", TAMANHO_FONTE)
	vbox.add_child(_corpo)

	_dica = Label.new()
	_dica.text = "Enter: continuar"
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dica.add_theme_font_size_override("font_size", TAMANHO_FONTE)
	vbox.add_child(_dica)


func _atualizar() -> void:
	_titulo.text = String(_dados.get("resultado", "")).to_upper()

	var texto := ""

	var resumo: Array = _dados.get("resumo", [])
	if not resumo.is_empty():
		texto += "[color=gold]ACONTECIMENTOS[/color]\n"
		for linha in resumo:
			texto += "- %s\n" % str(linha)

	# Recompensas: só aparecem quando houver dados enviados.
	var itens: Array = _dados.get("itens", [])
	if _dados.has("almas") or not itens.is_empty():
		texto += "\n[color=gold]RECOMPENSAS[/color]\n"
		if _dados.has("almas"):
			texto += "Almas: %d\n" % int(_dados["almas"])
		for item in itens:
			texto += "- %s x%d\n" % [
				str(item.get("nome", "?")),
				int(item.get("quantidade", 1))
			]

	var fardos: Array = _dados.get("fardos", [])
	if not fardos.is_empty():
		texto += "\n[color=red]FARDOS[/color]\n"
		for fardo in fardos:
			texto += "- %s\n" % str(fardo)

	_corpo.text = texto


# _input (e não _unhandled_input) para o Enter não ser consumido
# por algum botão que ainda tenha foco.
func _input(event: InputEvent) -> void:
	if not _pronto:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_pronto = false
		confirmado.emit()
