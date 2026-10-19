extends PanelContainer
class_name ActionPanel

## ===== OBJETIVO DA CLASSE =====
## Painel responsável por concentrar as decisões do jogador durante o turno.
## O CombatManager continua dono das regras de combate; este painel apenas
## organiza a navegação da interface e emite sinais quando uma escolha precisa
## ser processada pelo fluxo principal da batalha.

signal acao_atacar
signal acao_habilidade
signal acao_item
signal turno_passado
signal habilidade_sobrecarga
signal conhecimento_escolhida(nome_conhecimento: String)
signal habilidade_escolhida(nome_habilidade: String)
signal item_escolhido(nome_item: String)
## ===== REFERÊNCIAS DA UI =====
## A interface é criada por código para preservar a cena atual. As telas internas
## reaproveitam o mesmo VBoxContainer, o que permite trocar Menu Principal,
## Listas e Detalhes sem depender de menus flutuantes.
@onready var vbox = VBoxContainer.new()
const TAMANHO_FONTE: int = 8
var grid_principal: GridContainer
var botao_atacar: Button
var botao_conhecimento: Button
var botao_habilidade: Button
var botao_item: Button
var botao_passar: Button

## ===== ESTADO DO PAINEL =====
## Guarda o combatente ativo e os nós temporários da tela atual. A lista de nós
## temporários prepara o mesmo padrão para Itens Consumíveis: basta criar outra
## lista contextual e limpar a tela ao voltar.
var combatente_ativo: Dictionary = {}
var combatente_ref: CombatenteData = null
var acoes_habilitadas: bool = false
var habilidade_db := HabilidadeData.new()
var controles_tela_atual: Array[Node] = []

enum EstadoMenu {
	PRINCIPAL,
	CONHECIMENTOS,
	HABILIDADES,
	DETALHE_HABILIDADE,
	ITENS,
	DETALHE_ITEM
}

var estado_menu := EstadoMenu.PRINCIPAL

func _ready() -> void:
	_criar_layout()
	desabilitar_acoes()

## ===== CRIAÇÃO DA UI =====
## Bloco responsável apenas por montar os controles fixos do Menu Principal.
## As telas de Conhecimentos, Habilidades e futuramente Consumíveis são criadas em
## blocos separados para manter o fluxo de navegação fácil de manter.

func _criar_layout() -> void:
	# Cria o layout base dos botões de ação do turno (grid 2 colunas).
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)

	grid_principal = GridContainer.new()
	grid_principal.columns = 2
	grid_principal.add_theme_constant_override("h_separation", 2)
	grid_principal.add_theme_constant_override("v_separation", 2)
	vbox.add_child(grid_principal)

	botao_atacar = _criar_botao(
		"ATACAR",
		"Selecione regiões e alvo",
		_on_atacar_pressionado
	)
	grid_principal.add_child(botao_atacar)

	botao_conhecimento = _criar_botao(
		"CONHECIMENTO",
		"Habilidades treinadas",
		_on_conhecimento_pressionado
	)
	grid_principal.add_child(botao_conhecimento)

	botao_habilidade = _criar_botao(
		"HABILIDADE",
		"Poderes especiais",
		_on_habilidade_pressionada
	)
	grid_principal.add_child(botao_habilidade)

	botao_item = _criar_botao(
		"ITEM",
		"Usar do inventário",
		_on_item_pressionado
	)
	grid_principal.add_child(botao_item)

	botao_passar = _criar_botao(
		"PASSAR",
		"Finaliza o turno",
		_on_passar_turno
	)
	grid_principal.add_child(botao_passar)

func _criar_botao(texto: String, p_tooltip_text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = texto
	btn.tooltip_text = p_tooltip_text
	btn.pressed.connect(callback)
	btn.custom_minimum_size = Vector2(0, 12)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.clip_text = true
	UiUtil.aplicar(btn, TAMANHO_FONTE)
	return btn

## ===== ATIVAÇÃO / DESATIVAÇÃO =====
## O CombatManager chama este bloco ao iniciar ou encerrar janelas de ação.
## Sempre que o painel é reativado, ele volta ao Menu Principal para evitar que
## uma tela antiga fique aberta no turno de outro combatente.

func ativar_para(combatente: Dictionary, ref_combatente: CombatenteData = null) -> void:
	combatente_ativo = combatente
	combatente_ref = ref_combatente

	show()
	habilitar_acoes()

	call_deferred("_focar_botao")

func _focar_botao() -> void:
	if botao_atacar != null and botao_atacar.is_visible_in_tree():
		botao_atacar.grab_focus()

func _mostrar_menu_principal() -> void:
	estado_menu = EstadoMenu.PRINCIPAL
	_limpar_tela_contextual()
	grid_principal.show()
	call_deferred("_focar_botao")

func _ocultar_menu_principal() -> void:
	grid_principal.hide()

func habilitar_acoes() -> void:
	# Reabre o painel no estado principal e libera os comandos do turno atual.
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
	# Usado enquanto outra seleção está em andamento, como região de ataque ou alvo.
	acoes_habilitadas = false
	_limpar_tela_contextual()
	botao_atacar.disabled = true
	botao_conhecimento.disabled = true
	botao_habilidade.disabled = true
	botao_item.disabled = true
	botao_passar.disabled = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

## ===== NAVEGAÇÃO BASE =====
## Estas funções controlam quais partes da interface ficam visíveis. O mesmo
## modelo é usado por Conhecimentos e Habilidades e deixa a futura tela de Itens
## Consumíveis preparada para entrar sem menus flutuantes.

func _limpar_tela_contextual() -> void:
	# Remove somente os nós criados pelas subtelas, preservando os botões fixos.
	for controle in controles_tela_atual:
		if is_instance_valid(controle):
			if controle.get_parent() != null:
				controle.get_parent().remove_child(controle)
			controle.queue_free()
	controles_tela_atual.clear()

func _criar_titulo_tela(texto: String) -> Label:
	var label = Label.new()
	label.text = texto
	label.add_theme_font_size_override("font_size", TAMANHO_FONTE+1)
	vbox.add_child(label)
	controles_tela_atual.append(label)
	return label

func _criar_botao_voltar(callback: Callable) -> Button:
	# Toda subtela possui Voltar para manter a navegação previsível.
	var voltar = _criar_botao("VOLTAR", "Retorna à tela anterior", callback)
	vbox.add_child(voltar)
	controles_tela_atual.append(voltar)
	return voltar

func _criar_scroll_lista(altura_minima: int = 50) -> VBoxContainer:
	# A lista rolável evita que muitas habilidades ou itens estourem o painel.
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, altura_minima)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.clip_contents = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var lista = VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 4)
	scroll.add_child(lista)

	vbox.add_child(scroll)
	controles_tela_atual.append(scroll)
	return lista

func _criar_label_info(texto: String) -> Label:
	var label = Label.new()
	label.text = texto
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(label)
	controles_tela_atual.append(label)
	return label

## ===== CALLBACKS DO MENU PRINCIPAL =====
## Cada botão inicia um fluxo diferente. Ataque e Item ainda delegam ao
## CombatManager; Conhecimentos e Habilidades navegam dentro do ActionPanel.

func _on_atacar_pressionado() -> void:
	# Inicia o fluxo externo: selecionar regiões, selecionar alvo e processar ataque.
	desabilitar_acoes()
	acao_atacar.emit()

func _on_conhecimento_pressionado() -> void:
	abrir_menu_conhecimentos()

func _on_habilidade_pressionada() -> void:
	abrir_menu_habilidades()

func _on_item_pressionado() -> void:
	abrir_menu_itens()

func _on_passar_turno() -> void:
	# Finaliza voluntariamente o turno do combatente ativo.
	print("[ActionPanel] Turno passado")
	turno_passado.emit()

func _on_botao_duelo_pressed() -> void:
	conhecimento_escolhida.emit("Duelo")

## ===== TELA DE CONHECIMENTOS =====
## Mantém a filosofia já existente: o jogador sai do Menu Principal, escolhe uma
## conhecimento conhecida e o ActionPanel emite um sinal sem decidir a regra.

func abrir_menu_conhecimentos() -> void:
	if combatente_ref == null:
		print("[ActionPanel] Combatente não possui referência")
		return

	estado_menu = EstadoMenu.CONHECIMENTOS
	_ocultar_menu_principal()
	_limpar_tela_contextual()
	_criar_titulo_tela("Conhecimentos")

	var lista = _criar_scroll_lista(70)
	var encontrou_conhecimento := false

	for conhecimento in combatente_ref.conhecimentos_especializados:
		var bonus: int = combatente_ref.calcular_bonus_conhecimento(conhecimento)
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
		var vazio = Label.new()
		vazio.text = "Nenhuma conhecimento especializada."
		vazio.add_theme_font_size_override("font_size", TAMANHO_FONTE)
		lista.add_child(vazio)

	_criar_botao_voltar(fechar_menu_conhecimentos)

func fechar_menu_conhecimentos() -> void:
	_mostrar_menu_principal()

## ===== TELA DE HABILIDADES =====
## Fluxo implementado:
## Menu Principal -> Lista de Habilidades -> Detalhes -> Confirmar Uso.
## Nenhuma etapa usa menus flutuantes; tudo é composto no próprio painel para manter
## consistência visual com Conhecimentos e facilitar reuso por Itens Consumíveis.

func abrir_menu_habilidades() -> void:
	if combatente_ref == null:
		print("[ActionPanel] Combatente não possui referência")
		return

	estado_menu = EstadoMenu.HABILIDADES
	_ocultar_menu_principal()
	_limpar_tela_contextual()
	_criar_titulo_tela("Habilidades")

	var lista = _criar_scroll_lista(50)
	var habilidades_disponiveis = _obter_habilidades_conhecidas()

	if habilidades_disponiveis.is_empty() and not combatente_ref.habilidade_sobrecarga_ativa:
		var vazio = Label.new()
		vazio.text = "Nenhuma habilidade disponível."
		lista.add_child(vazio)
	else:
		_preencher_lista_habilidades(lista, habilidades_disponiveis)

	_criar_botao_voltar(_mostrar_menu_principal)

func _obter_habilidades_conhecidas() -> Array:
	# Resolve os nomes salvos no CombatenteData usando o banco de habilidades.
	# A busca tolerante a capitalização evita que dados antigos escondam uma
	# habilidade por diferenças como "Escudo humano" e "Escudo Humano".
	var resultado: Array = []
	for nome_habilidade in combatente_ref.habilidades:
		var habilidade = habilidade_db.get_habilidade(nome_habilidade)
		if habilidade != null:
			resultado.append(habilidade)
		else:
			print("[ActionPanel] Habilidade não encontrada no banco: %s" % nome_habilidade)
	return resultado

func _preencher_lista_habilidades(lista: VBoxContainer, habilidades_disponiveis: Array) -> void:
	# Agrupa por categoria para que Principal, Única e Geral apareçam de forma
	# consistente mesmo quando o combatente tiver muitas habilidades.
	var ordem_tipos = [
		HabilidadeData.TipoHabilidade.PRINCIPAL,
		HabilidadeData.TipoHabilidade.UNICA,
		HabilidadeData.TipoHabilidade.GERAL
	]

	for tipo_habilidade in ordem_tipos:
		var habilidades_do_tipo = habilidades_disponiveis.filter(
			func(habilidade): return habilidade.tipo_habilidade == tipo_habilidade
		)
		if habilidades_do_tipo.is_empty():
			continue

		var secao = Label.new()
		secao.text = HabilidadeData.tipo_habilidade_para_texto(tipo_habilidade).to_upper()
		secao.add_theme_font_size_override("font_size", TAMANHO_FONTE)
		lista.add_child(secao)

		for habilidade in habilidades_do_tipo:
			var btn = _criar_botao_habilidade(habilidade)
			lista.add_child(btn)

	if combatente_ref.habilidade_sobrecarga_ativa:
		var btn_sobrecarga = _criar_botao(
			"SOBRECARGA (Ir Além)",
			"Permite arriscar a mesma região mais de uma vez",
			_abrir_detalhes_sobrecarga
		)
		lista.add_child(btn_sobrecarga)

func _criar_botao_habilidade(habilidade) -> Button:
	# O texto mostra custo e categoria para reduzir idas desnecessárias à tela de detalhes.
	var texto = "%s | %s | %d PA" % [
		habilidade.nome,
		HabilidadeData.tipo_habilidade_para_texto(habilidade.tipo_habilidade),
		habilidade.custo_pa
	]
	return _criar_botao(
		texto,
		"Ver detalhes de %s" % habilidade.nome,
		_abrir_detalhes_habilidade.bind(habilidade)
	)

func _abrir_detalhes_habilidade(habilidade) -> void:
	estado_menu = EstadoMenu.DETALHE_HABILIDADE
	_limpar_tela_contextual()
	_criar_titulo_tela(habilidade.nome)

	var detalhes = _criar_scroll_lista(70)
	_adicionar_linha_detalhe(detalhes, "Tipo", HabilidadeData.tipo_habilidade_para_texto(habilidade.tipo_habilidade))
	_adicionar_linha_detalhe(detalhes, "Custo de PA", str(habilidade.custo_pa))
	_adicionar_linha_detalhe(detalhes, "Persona de origem", _texto_ou_padrao(habilidade.persona_origem, "Não informada"))

	if habilidade.alcance.strip_edges() != "":
		_adicionar_linha_detalhe(detalhes, "Alcance", habilidade.alcance)

	_adicionar_linha_detalhe(detalhes, "Descrição", habilidade.efeito)

	var confirmar = _criar_botao(
		"CONFIRMAR USO",
		"Confirma o uso da habilidade selecionada",
		_confirmar_habilidade.bind(habilidade.nome)
	)
	vbox.add_child(confirmar)
	controles_tela_atual.append(confirmar)

	_criar_botao_voltar(abrir_menu_habilidades)
	confirmar.grab_focus()

func _abrir_detalhes_sobrecarga() -> void:
	# Sobrecarga é uma regra especial do combate que não está no banco principal
	# de HabilidadeData. Ela recebe uma tela de detalhes própria para preservar
	# o mesmo fluxo de confirmação das demais habilidades.
	estado_menu = EstadoMenu.DETALHE_HABILIDADE
	_limpar_tela_contextual()
	_criar_titulo_tela("Sobrecarga (Ir Além)")

	var detalhes = _criar_scroll_lista(50)
	_adicionar_linha_detalhe(detalhes, "Tipo", "Geral")
	_adicionar_linha_detalhe(detalhes, "Custo de PA", "0")
	_adicionar_linha_detalhe(detalhes, "Persona de origem", combatente_ref.nome)
	_adicionar_linha_detalhe(detalhes, "Alcance", "Pessoal")
	_adicionar_linha_detalhe(
		detalhes,
		"Descrição",
		"Permite arriscar a mesma região mais de uma vez no Teste de Combate, respeitando o limite total de cinco riscos."
	)

	var confirmar = _criar_botao(
		"CONFIRMAR USO",
		"Ativa Sobrecarga para o combatente atual",
		_confirmar_sobrecarga
	)
	vbox.add_child(confirmar)
	controles_tela_atual.append(confirmar)

	_criar_botao_voltar(abrir_menu_habilidades)
	confirmar.grab_focus()

func _adicionar_linha_detalhe(container: VBoxContainer, rotulo: String, valor: String) -> void:
	# Usa RichTextLabel para suportar descrições longas sem quebrar o painel.
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.add_theme_font_size_override("normal_font_size", TAMANHO_FONTE)
	label.add_theme_font_size_override("bold_font_size", TAMANHO_FONTE)
	label.text = "[b]%s:[/b] %s" % [rotulo, valor]
	container.add_child(label)

func _texto_ou_padrao(texto: String, padrao: String) -> String:
	if texto.strip_edges() == "":
		return padrao
	return texto

func _confirmar_habilidade(nome_habilidade: String) -> void:
	# Após a confirmação, a regra volta para o CombatManager via sinal.
	print("[ActionPanel] Habilidade confirmada: %s" % nome_habilidade)
	_mostrar_menu_principal()
	habilidade_escolhida.emit(nome_habilidade)

func _confirmar_sobrecarga() -> void:
	print("[ActionPanel] Sobrecarga confirmada")
	_mostrar_menu_principal()
	habilidade_sobrecarga.emit()

## ===== MENUS ESPECÍFICOS / COMPATIBILIDADE =====
## Métodos mantidos para chamadas externas antigas. Eles agora redirecionam para
## o fluxo interno sem menus flutuantes.

func mostrar_menu_conhecimentos(_combatente: Dictionary) -> void:
	abrir_menu_conhecimentos()

func mostrar_menu_habilidades(_combatente: Dictionary) -> void:
	abrir_menu_habilidades()

func mostrar_menu_itens(_combatente: Dictionary) -> void:
	abrir_menu_itens()

## ===== TELA DE ITENS =====
## Menu Principal -> Lista de consumíveis -> Detalhes -> Usar.
## Mesmo padrão de Habilidades; o CombatManager aplica o efeito.

func abrir_menu_itens() -> void:
	if combatente_ref == null:
		print("[ActionPanel] Combatente não possui referência")
		return

	estado_menu = EstadoMenu.ITENS
	_ocultar_menu_principal()
	_limpar_tela_contextual()
	_criar_titulo_tela("Itens")

	var lista = _criar_scroll_lista(40)
	var consumiveis: Array[Dictionary] = ItemData.listar_consumiveis(combatente_ref)

	if consumiveis.is_empty():
		var vazio = Label.new()
		vazio.text = "Nenhum item utilizável."
		vazio.add_theme_font_size_override("font_size", TAMANHO_FONTE)
		lista.add_child(vazio)
	else:
		for entrada in consumiveis:
			var item: ItemData.Item = entrada["item"]
			var btn := _criar_botao(
				"%s x%d" % [item.nome, entrada["quantidade"]],
				item.descricao,
				_abrir_detalhes_item.bind(entrada)
			)
			lista.add_child(btn)

	_criar_botao_voltar(_mostrar_menu_principal)
	_focar_primeiro_botao.call_deferred(lista)

func _abrir_detalhes_item(entrada: Dictionary) -> void:
	var item: ItemData.Item = entrada["item"]
	estado_menu = EstadoMenu.DETALHE_ITEM
	_limpar_tela_contextual()
	_criar_titulo_tela(item.nome)

	var detalhes = _criar_scroll_lista(40)
	_adicionar_linha_detalhe(detalhes, "Quantidade", str(entrada["quantidade"]))
	_adicionar_linha_detalhe(detalhes, "Efeito", item.descricao)

	var confirmar = _criar_botao(
		"USAR",
		"Usa o item e finaliza o turno",
		_confirmar_item.bind(String(entrada["nome"]))
	)
	vbox.add_child(confirmar)
	controles_tela_atual.append(confirmar)

	_criar_botao_voltar(abrir_menu_itens)
	confirmar.grab_focus()

func _confirmar_item(nome_item: String) -> void:
	print("[ActionPanel] Item confirmado: %s" % nome_item)
	_mostrar_menu_principal()
	item_escolhido.emit(nome_item)

func _focar_primeiro_botao(container: Node) -> void:
	if not is_instance_valid(container):
		return
	for filho in container.get_children():
		if filho is Button and not filho.disabled:
			filho.grab_focus()
			return
