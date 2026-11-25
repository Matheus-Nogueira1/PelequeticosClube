
extends PanelContainer
class_name ActionPanel

## ============================================================
## OBJETIVO DA CLASSE
## ============================================================
## Painel responsável por concentrar as decisões do jogador.
## O CombatManager continua responsável pelas regras de combate.
## Este painel organiza a navegação e emite sinais quando uma
## escolha precisa ser processada pelo fluxo principal da batalha.
##
## A estrutura principal é fixa na combat.tscn.
## Somente os elementos internos das listas são criados dinamicamente.

## ============================================================
## SINAIS
## ============================================================

signal acao_atacar
signal acao_habilidade
signal acao_item
signal turno_passado
signal habilidade_sobrecarga

signal conhecimento_escolhida(nome_conhecimento: String)
signal habilidade_escolhida(nome_habilidade: String)
signal item_escolhido(nome_item: String)

## ============================================================
## CENAS E CONFIGURAÇÕES
## ============================================================

const CENA_BOTAO: PackedScene = preload("res://scenes/battle/acao_botao.tscn")
const CENA_ROTULO: PackedScene = preload("res://scenes/battle/acao_rotulo.tscn")
const CENA_LINHA: PackedScene = preload("res://scenes/battle/detalhe_linha.tscn")

const TAMANHO_FONTE: int = 10

## ============================================================
## REFERÊNCIAS DA INTERFACE
## ============================================================

@onready var grid_principal: GridContainer = %GridPrincipal

@onready var botao_atacar: Button = %BotaoAtacar
@onready var botao_conhecimento: Button = %BotaoConhecimento
@onready var botao_habilidade: Button = %BotaoHabilidade
@onready var botao_item: Button = %BotaoItem
@onready var botao_passar: Button = %BotaoPassar

@onready var tela_submenu: VBoxContainer = %TelaSubmenu
@onready var titulo_submenu: Label = %SubmenuTitulo
@onready var scroll_submenu: ScrollTeclado = %SubmenuScroll
@onready var lista_submenu: VBoxContainer = %SubmenuLista

@onready var botao_confirmar: Button = %AcaoConfirmar
@onready var botao_voltar: Button = %AcaoVoltar

## ============================================================
## ESTADO DO PAINEL
## ============================================================

var combatente_ativo: Dictionary = {}
var combatente_ref: CombatenteData = null

var acoes_habilitadas: bool = false
var habilidade_db: HabilidadeData = HabilidadeData.new()

enum EstadoMenu {
	PRINCIPAL,
	CONHECIMENTOS,
	HABILIDADES,
	DETALHE_HABILIDADE,
	ITENS,
	DETALHE_ITEM
}

var estado_menu := EstadoMenu.PRINCIPAL

## ============================================================
## INICIALIZAÇÃO
## ============================================================

func _ready() -> void:
	_conectar_botoes()
	desabilitar_acoes()


## Conecta os botões fixos do menu principal.
## Confirmar e Voltar recebem conexões individualmente em cada tela.
func _conectar_botoes() -> void:
	botao_atacar.pressed.connect(_on_atacar_pressionado)
	botao_conhecimento.pressed.connect(_on_conhecimento_pressionado)
	botao_habilidade.pressed.connect(_on_habilidade_pressionada)
	botao_item.pressed.connect(_on_item_pressionado)
	botao_passar.pressed.connect(_on_passar_turno)

	for botao in [
		botao_atacar,
		botao_conhecimento,
		botao_habilidade,
		botao_item,
		botao_passar,
		botao_confirmar,
		botao_voltar
	]:
		UiUtil.compactar_botao(botao, TAMANHO_FONTE, true)


## ============================================================
## CRIAÇÃO DE ELEMENTOS DINÂMICOS
## ============================================================

func _criar_botao(
	texto: String,
	p_tooltip_text: String,
	callback: Callable
) -> Button:
	var btn := CENA_BOTAO.instantiate() as Button
	btn.custom_minimum_size = Vector2(0, 18)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = texto
	btn.tooltip_text = p_tooltip_text
	btn.pressed.connect(callback)

	UiUtil.aplicar(btn, TAMANHO_FONTE, true)

	return btn


func _criar_rotulo(texto: String) -> Label:
	var rotulo := CENA_ROTULO.instantiate() as Label

	rotulo.text = texto

	return rotulo


## ============================================================
## CONTROLE DAS TELAS INTERNAS
## ============================================================

## Limpa somente os elementos dinâmicos da lista.
## Os nós fixos continuam existindo na combat.tscn.
func _limpar_tela_contextual() -> void:
	for filho in lista_submenu.get_children():
		lista_submenu.remove_child(filho)
		filho.queue_free()

	_desligar_botao(botao_confirmar)
	_desligar_botao(botao_voltar)

	botao_confirmar.visible = false
	botao_voltar.visible = false

	tela_submenu.visible = false


func _criar_titulo_tela(texto: String) -> Label:
	titulo_submenu.text = texto
	tela_submenu.visible = true

	return titulo_submenu


## O botão Voltar é fixo na cena.
## Apenas substitui sua conexão e habilita sua exibição.
func _criar_botao_voltar(callback: Callable) -> Button:
	_ligar_botao(botao_voltar, callback)
	botao_voltar.visible = true

	return botao_voltar

func _criar_scroll_lista() -> VBoxContainer:
	scroll_submenu.scroll_vertical = 0

	return lista_submenu

## Configura o botão fixo de confirmação.
func _preparar_confirmar(
	texto: String,
	dica: String,
	callback: Callable
) -> Button:
	botao_confirmar.text = texto
	botao_confirmar.tooltip_text = dica
	botao_confirmar.disabled = false
	botao_confirmar.visible = true

	_ligar_botao(botao_confirmar, callback)

	return botao_confirmar


## Substitui as conexões anteriores do botão.
func _ligar_botao(botao: Button, callback: Callable) -> void:
	_desligar_botao(botao)

	botao.pressed.connect(callback)


func _desligar_botao(botao: Button) -> void:
	for conexao in botao.pressed.get_connections():
		botao.pressed.disconnect(conexao["callable"])


## ============================================================
## ATIVAÇÃO E DESATIVAÇÃO
## ============================================================

func ativar_para(
	combatente: Dictionary,
	ref_combatente: CombatenteData = null
) -> void:
	combatente_ativo = combatente
	combatente_ref = ref_combatente

	show()
	habilitar_acoes()

	call_deferred("_focar_botao")


func _focar_botao() -> void:
	if botao_atacar != null and botao_atacar.is_visible_in_tree():
		botao_atacar.grab_focus()


func habilitar_acoes() -> void:
	acoes_habilitadas = true

	_mostrar_menu_principal()

	botao_atacar.disabled = false
	botao_conhecimento.disabled = false
	botao_habilidade.disabled = false
	botao_item.disabled = false
	botao_passar.disabled = false

	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true


func desabilitar_acoes() -> void:
	acoes_habilitadas = false

	_limpar_tela_contextual()

	botao_atacar.disabled = true
	botao_conhecimento.disabled = true
	botao_habilidade.disabled = true
	botao_item.disabled = true
	botao_passar.disabled = true

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## ============================================================
## MENU PRINCIPAL
## ============================================================

func _mostrar_menu_principal() -> void:
	estado_menu = EstadoMenu.PRINCIPAL

	_limpar_tela_contextual()

	grid_principal.show()

	call_deferred("_focar_botao")


func _ocultar_menu_principal() -> void:
	grid_principal.hide()


## ============================================================
## CALLBACKS DO MENU PRINCIPAL
## ============================================================

func _on_atacar_pressionado() -> void:
	desabilitar_acoes()
	acao_atacar.emit()


func _on_conhecimento_pressionado() -> void:
	abrir_menu_conhecimentos()


func _on_habilidade_pressionada() -> void:
	abrir_menu_habilidades()


func _on_item_pressionado() -> void:
	abrir_menu_itens()


func _on_passar_turno() -> void:
	print("[ActionPanel] Turno passado")
	turno_passado.emit()


func _on_botao_duelo_pressed() -> void:
	conhecimento_escolhida.emit("Duelo")


## ============================================================
## CONHECIMENTOS
## ============================================================

func abrir_menu_conhecimentos() -> void:
	if combatente_ref == null:
		print("[ActionPanel] Combatente não possui referência")
		return

	estado_menu = EstadoMenu.CONHECIMENTOS

	_ocultar_menu_principal()
	_limpar_tela_contextual()
	_criar_titulo_tela("Conhecimentos")

	var lista := _criar_scroll_lista()
	var encontrou_conhecimento := false

	for conhecimento in combatente_ref.conhecimentos_especializados:
		var bonus: int = combatente_ref.calcular_bonus_conhecimento(
			conhecimento
		)

		encontrou_conhecimento = true

		var btn := _criar_botao(
			"%s (+%d)" % [conhecimento, bonus],
			"Usar conhecimento %s" % conhecimento,
			func():
				conhecimento_escolhida.emit(conhecimento)
				fechar_menu_conhecimentos()
		)

		lista.add_child(btn)

	if not encontrou_conhecimento:
		lista.add_child(
			_criar_rotulo("Nenhum conhecimento disponível.")
		)

	var voltar := _criar_botao_voltar(
		fechar_menu_conhecimentos
	)

	_focar_primeiro_botao.call_deferred(lista, voltar)


func fechar_menu_conhecimentos() -> void:
	_mostrar_menu_principal()


## ============================================================
## HABILIDADES
## ============================================================

func abrir_menu_habilidades() -> void:
	if combatente_ref == null:
		print("[ActionPanel] Combatente não possui referência")
		return

	estado_menu = EstadoMenu.HABILIDADES

	_ocultar_menu_principal()
	_limpar_tela_contextual()
	_criar_titulo_tela("Habilidades")

	var lista := _criar_scroll_lista()
	var habilidades_disponiveis := _obter_habilidades_conhecidas()

	if habilidades_disponiveis.is_empty() and not combatente_ref.possui_sobrecarga:
		lista.add_child(
			_criar_rotulo("Nenhuma habilidade disponível.")
		)
	else:
		_preencher_lista_habilidades(
			lista,
			habilidades_disponiveis
		)

	var voltar := _criar_botao_voltar(
		_mostrar_menu_principal
	)

	_focar_primeiro_botao.call_deferred(lista, voltar)


func _obter_habilidades_conhecidas() -> Array:
	var resultado: Array = []

	for nome_habilidade in combatente_ref.habilidades:
		var habilidade = habilidade_db.get_habilidade(
			nome_habilidade
		)

		if habilidade != null:
			resultado.append(habilidade)
		else:
			print(
				"[ActionPanel] Habilidade não encontrada no banco: %s"
				% nome_habilidade
			)

	return resultado


func _preencher_lista_habilidades(
	lista: Container,
	habilidades_disponiveis: Array
) -> void:
	var ordem_tipos := [
		HabilidadeData.TipoHabilidade.PRINCIPAL,
		HabilidadeData.TipoHabilidade.UNICA,
		HabilidadeData.TipoHabilidade.GERAL
	]

	for tipo_habilidade in ordem_tipos:
		var habilidades_do_tipo = habilidades_disponiveis.filter(
			func(habilidade):
				return habilidade.tipo_habilidade == tipo_habilidade
		)

		if habilidades_do_tipo.is_empty():
			continue

		lista.add_child(
			_criar_rotulo(
				HabilidadeData.tipo_habilidade_para_texto(
					tipo_habilidade
				).to_upper()
			)
		)

		for habilidade in habilidades_do_tipo:
			var btn := _criar_botao_habilidade(habilidade)
			lista.add_child(btn)

	if combatente_ref.possui_sobrecarga:
		var rotulo: String = "SOBRECARGA (Ir Além)"

		if combatente_ref.habilidade_sobrecarga_ativa:
			rotulo = "SOBRECARGA ATIVA"

		var btn_sobrecarga := _criar_botao(
			rotulo,
			"Permite arriscar a mesma região mais de uma vez",
			_abrir_detalhes_sobrecarga
		)

		lista.add_child(btn_sobrecarga)


func _criar_botao_habilidade(habilidade) -> Button:
	var texto := "%s | %s | %d PA" % [
		habilidade.nome,
		HabilidadeData.tipo_habilidade_para_texto(
			habilidade.tipo_habilidade
		),
		habilidade.custo_pa
	]

	return _criar_botao(
		texto,
		"Ver detalhes de %s" % habilidade.nome,
		_abrir_detalhes_habilidade.bind(habilidade)
	)


## ============================================================
## DETALHES DE HABILIDADES
## ============================================================

func _abrir_detalhes_habilidade(habilidade) -> void:
	estado_menu = EstadoMenu.DETALHE_HABILIDADE

	_limpar_tela_contextual()
	_criar_titulo_tela(habilidade.nome)

	var detalhes := _criar_scroll_lista()

	_adicionar_linha_detalhe(
		detalhes,
		"Tipo",
		HabilidadeData.tipo_habilidade_para_texto(
			habilidade.tipo_habilidade
		)
	)

	_adicionar_linha_detalhe(
		detalhes,
		"Custo de PA",
		str(habilidade.custo_pa)
	)

	_adicionar_linha_detalhe(
		detalhes,
		"Persona de origem",
		_texto_ou_padrao(
			habilidade.persona_origem,
			"Não informada"
		)
	)

	if habilidade.alcance.strip_edges() != "":
		_adicionar_linha_detalhe(
			detalhes,
			"Alcance",
			habilidade.alcance
		)

	_adicionar_linha_detalhe(
		detalhes,
		"Descrição",
		habilidade.efeito
	)

	var confirmar := _preparar_confirmar(
		"CONFIRMAR USO",
		"Confirma o uso da habilidade selecionada",
		_confirmar_habilidade.bind(habilidade.nome)
	)

	_criar_botao_voltar(abrir_menu_habilidades)

	confirmar.grab_focus()


func _abrir_detalhes_sobrecarga() -> void:
	estado_menu = EstadoMenu.DETALHE_HABILIDADE

	_limpar_tela_contextual()
	_criar_titulo_tela("Sobrecarga (Ir Além)")

	var detalhes := _criar_scroll_lista()

	_adicionar_linha_detalhe(
		detalhes,
		"Tipo",
		"Geral"
	)

	_adicionar_linha_detalhe(
		detalhes,
		"Custo de PA",
		"0"
	)

	_adicionar_linha_detalhe(
		detalhes,
		"Persona de origem",
		combatente_ref.nome
	)

	_adicionar_linha_detalhe(
		detalhes,
		"Alcance",
		"Pessoal"
	)

	var ativa: bool = combatente_ref.habilidade_sobrecarga_ativa

	_adicionar_linha_detalhe(
		detalhes,
		"Estado",
		"ATIVA até o fim do combate" if ativa else "Inativa"
	)

	_adicionar_linha_detalhe(
		detalhes,
		"Descrição",
		"Permite arriscar a mesma região mais de uma vez no Teste de Combate, respeitando o limite total de cinco riscos."
	)

	var confirmar := _preparar_confirmar(
		"CONFIRMAR USO",
		"Ativa Sobrecarga para o combatente atual",
		_confirmar_sobrecarga
	)

	confirmar.disabled = ativa

	var voltar := _criar_botao_voltar(
		abrir_menu_habilidades
	)

	if ativa:
		voltar.grab_focus()
	else:
		confirmar.grab_focus()


func _adicionar_linha_detalhe(
	container: VBoxContainer,
	rotulo: String,
	valor: String
) -> void:
	var label := CENA_LINHA.instantiate() as RichTextLabel

	label.text = "[b]%s:[/b] %s" % [rotulo, valor]

	container.add_child(label)


func _texto_ou_padrao(
	texto: String,
	padrao: String
) -> String:
	if texto.strip_edges() == "":
		return padrao

	return texto


## ============================================================
## CONFIRMAÇÃO DE HABILIDADES
## ============================================================

func _confirmar_habilidade(nome_habilidade: String) -> void:
	print(
		"[ActionPanel] Habilidade confirmada: %s"
		% nome_habilidade
	)

	_mostrar_menu_principal()
	habilidade_escolhida.emit(nome_habilidade)


func _confirmar_sobrecarga() -> void:
	print("[ActionPanel] Sobrecarga confirmada")

	_mostrar_menu_principal()
	habilidade_sobrecarga.emit()


## ============================================================
## COMPATIBILIDADE COM CHAMADAS EXTERNAS
## ============================================================

func mostrar_menu_conhecimentos(_combatente: Dictionary) -> void:
	abrir_menu_conhecimentos()


func mostrar_menu_habilidades(_combatente: Dictionary) -> void:
	abrir_menu_habilidades()


func mostrar_menu_itens(_combatente: Dictionary) -> void:
	abrir_menu_itens()


## ============================================================
## ITENS
## ============================================================

func abrir_menu_itens() -> void:
	if combatente_ref == null:
		print("[ActionPanel] Combatente não possui referência")
		return

	estado_menu = EstadoMenu.ITENS

	_ocultar_menu_principal()
	_limpar_tela_contextual()
	_criar_titulo_tela("Itens")

	var lista := _criar_scroll_lista()
	var consumiveis: Array[Dictionary] = ItemData.listar_consumiveis(
		combatente_ref
	)

	if consumiveis.is_empty():
		lista.add_child(
			_criar_rotulo("Nenhum item consumível disponível.")
		)
	else:
		for entrada in consumiveis:
			var item: ItemData.Item = entrada["item"]

			var btn := _criar_botao(
				"%s x%d" % [
					item.nome,
					entrada["quantidade"]
				],
				item.descricao,
				_abrir_detalhes_item.bind(entrada)
			)

			lista.add_child(btn)

	var voltar := _criar_botao_voltar(
		_mostrar_menu_principal
	)

	_focar_primeiro_botao.call_deferred(lista, voltar)


## ============================================================
## DETALHES DOS ITENS
## ============================================================

func _abrir_detalhes_item(entrada: Dictionary) -> void:
	var item: ItemData.Item = entrada["item"]

	estado_menu = EstadoMenu.DETALHE_ITEM

	_limpar_tela_contextual()
	_criar_titulo_tela(item.nome)

	var detalhes := _criar_scroll_lista()

	_adicionar_linha_detalhe(
		detalhes,
		"Quantidade",
		str(entrada["quantidade"])
	)

	_adicionar_linha_detalhe(
		detalhes,
		"Efeito",
		item.descricao
	)

	var confirmar := _preparar_confirmar(
		"USAR",
		"Usa o item e finaliza o turno",
		_confirmar_item.bind(String(entrada["nome"]))
	)

	_criar_botao_voltar(abrir_menu_itens)

	confirmar.grab_focus()


func _confirmar_item(nome_item: String) -> void:
	print(
		"[ActionPanel] Item confirmado: %s"
		% nome_item
	)

	_mostrar_menu_principal()
	item_escolhido.emit(nome_item)


## ============================================================
## NAVEGAÇÃO POR FOCO
## ============================================================

func _focar_primeiro_botao(
	container: Node,
	alternativo: Button = null
) -> void:
	if not is_instance_valid(container):
		return

	for filho in container.get_children():
		if filho is Button and not filho.disabled:
			filho.grab_focus()
			return

	if alternativo != null and is_instance_valid(alternativo):
		alternativo.grab_focus()
