extends CanvasLayer
class_name CaixaAjuda

# ============================================================
# CAIXA DE AJUDA CONTEXTUAL
# Toda a interface vive em caixa_ajuda.tscn. Cada filho de
# "Paineis" é um painel (o nome do nó é o id). abrir(painel, ancora)
# mostra só aquele painel e rola até a seção com o nome da âncora.
# Emite "fechada" ao terminar.
# ============================================================

signal fechada

const PASSO_SETAS: int = 16

@onready var raiz: Control = %Raiz
@onready var titulo: Label = %Titulo
@onready var botao_fechar: Button = %BotaoFechar
@onready var paineis: Control = %Paineis

var _aberta: bool = false
var _painel_atual: ScrollContainer = null
var _origem: Control = null


func _ready() -> void:
	add_to_group("caixa_ajuda")
	_definir_visivel(false)
	for painel in _lista_paineis():
		painel.visible = false
	botao_fechar.pressed.connect(fechar)
	# Foco preso: sem isso, Tab e as setas moveriam o foco para botões
	# que estão atrás da janela.
	for propriedade in [
		"focus_neighbor_left", "focus_neighbor_right", "focus_neighbor_top",
		"focus_neighbor_bottom", "focus_next", "focus_previous"
	]:
		botao_fechar.set(propriedade, ^".")


func esta_aberta() -> bool:
	return _aberta


# Abre o painel e, se houver âncora, rola até a seção com esse nome.
func abrir(id_painel: String, ancora: String = "") -> void:
	var painel := paineis.get_node_or_null(NodePath(id_painel)) as ScrollContainer
	if painel == null:
		push_warning("[CaixaAjuda] Painel '%s' não encontrado." % id_painel)
		return

	if not _aberta:
		_origem = get_viewport().gui_get_focus_owner()
	_aberta = true

	for outro in _lista_paineis():
		outro.visible = (outro == painel)
	_painel_atual = painel
	titulo.text = String(painel.get_meta("titulo", id_painel.capitalize()))
	painel.scroll_vertical = 0

	_definir_visivel(true)
	get_viewport().gui_release_focus()
	botao_fechar.grab_focus()

	if not ancora.is_empty():
		_rolar_para_ancora(painel, ancora)


func fechar() -> void:
	if not _aberta:
		return
	_aberta = false
	_definir_visivel(false)
	for painel in _lista_paineis():
		painel.visible = false
	_painel_atual = null

	get_viewport().gui_release_focus()
	if is_instance_valid(_origem) and _origem.is_visible_in_tree() \
			and _origem.focus_mode != Control.FOCUS_NONE:
		_origem.grab_focus()
	_origem = null
	fechada.emit()


# Esc fecha; as setas rolam (o foco preso consumiria as setas no botão).
# PageUp/PageDown/Home/End ficam por conta do ScrollTeclado do painel.
func _input(event: InputEvent) -> void:
	if not _aberta or _painel_atual == null:
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		fechar()
	elif event.is_action_pressed("ui_down", true):
		get_viewport().set_input_as_handled()
		_painel_atual.scroll_vertical += PASSO_SETAS
	elif event.is_action_pressed("ui_up", true):
		get_viewport().set_input_as_handled()
		_painel_atual.scroll_vertical -= PASSO_SETAS


func _rolar_para_ancora(painel: ScrollContainer, ancora: String) -> void:
	var alvo := painel.find_child(ancora, true, false) as Control
	if alvo == null:
		push_warning("[CaixaAjuda] Âncora '%s' não encontrada." % ancora)
		return
	# Espera o layout dos RichTextLabel (Fit Content) se acomodar.
	await get_tree().process_frame
	await get_tree().process_frame
	var conteudo := painel.get_child(0) as Control
	if conteudo == null or painel != _painel_atual:
		return
	painel.scroll_vertical = int(alvo.global_position.y - conteudo.global_position.y)


func _lista_paineis() -> Array[ScrollContainer]:
	var lista: Array[ScrollContainer] = []
	for filho in paineis.get_children():
		if filho is ScrollContainer:
			lista.append(filho)
	return lista


func _definir_visivel(valor: bool) -> void:
	visible = valor
	raiz.visible = valor
