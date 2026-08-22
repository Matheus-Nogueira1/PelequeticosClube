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
signal pericia_escolhida(nome_pericia: String)
signal habilidade_escolhida(nome_habilidade: String)
signal item_escolhido(nome_item:String)

## ===== REFERÊNCIAS DA UI =====
## A interface é criada por código para preservar a cena atual. As telas internas
## reaproveitam o mesmo VBoxContainer, o que permite trocar Menu Principal,
## Listas e Detalhes sem depender de menus flutuantes.
@onready var vbox = VBoxContainer.new()

var botao_atacar: Button
var botao_pericia: Button
var botao_habilidade: Button
var botao_item: Button
var botao_passar: Button
var spacer_principal: Control

## ===== ESTADO DO PAINEL =====
## Guarda o combatente ativo e os nós temporários da tela atual. A lista de nós
## temporários prepara o mesmo padrão para Itens Consumíveis: basta criar outra
## lista contextual e limpar a tela ao voltar.
var combatente_ativo: CombatenteData = null
var combatente_ref: CombatenteData = null
var acoes_habilitadas: bool = false
var habilidade_db := HabilidadeData.new()
var pericia_db := PericiaData.new()
var item_db := ItemData.new()
var controles_tela_atual: Array[Node] = []

enum EstadoMenu {
	PRINCIPAL,
	PERICIAS,
	DETALHE_PERICIA,
	HABILIDADES,
	DETALHE_HABILIDADE,
	ITENS,
	DETALHE_ITEM
}

var estado_menu := EstadoMenu.PRINCIPAL

## Monta os controles do painel e inicia o painel desativado.
func _ready() -> void:
	_criar_layout()
	desabilitar_acoes()

## ===== CRIAÇÃO DA UI =====
## Bloco responsável apenas por montar os controles fixos do Menu Principal.
## As telas de Perícias, Habilidades e futuramente Consumíveis são criadas em
## blocos separados para manter o fluxo de navegação fácil de manter.

## Cria os botões fixos do menu principal e seus callbacks.
func _criar_layout() -> void:
	# Cria o layout base dos botões de ação do turno.
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	botao_atacar = _criar_botao(
		"ATACAR",
		"Selecione regiões e alvo",
		_on_atacar_pressionado
	)
	vbox.add_child(botao_atacar)

	botao_pericia = _criar_botao(
		"PERÍCIA",
		"Habilidades treinadas",
		_on_pericia_pressionado
	)
	vbox.add_child(botao_pericia)

	botao_habilidade = _criar_botao(
		"HABILIDADE",
		"Poderes especiais",
		_on_habilidade_pressionada
	)
	vbox.add_child(botao_habilidade)

	botao_item = _criar_botao(
		"ITEM",
		"Usar do inventário",
		_on_item_pressionado
	)
	vbox.add_child(botao_item)

	spacer_principal = Control.new()
	spacer_principal.custom_minimum_size.y = 10
	vbox.add_child(spacer_principal)

	botao_passar = _criar_botao(
		"PASSAR TURNO",
		"Finaliza o turno",
		_on_passar_turno
	)
	vbox.add_child(botao_passar)

## Cria um botão padronizado, com tooltip, tamanho e callback compartilhados.
func _criar_botao(texto: String, p_tooltip_text: String, callback: Callable) -> Button:
	# Cria botões com o mesmo tamanho e conexão, evitando divergência visual entre telas.
	var btn = Button.new()
	btn.text = texto
	btn.tooltip_text = p_tooltip_text
	btn.pressed.connect(callback)
	btn.custom_minimum_size = Vector2(0, 32)
	return btn

## ===== ATIVAÇÃO / DESATIVAÇÃO =====
## O CombatManager chama este bloco ao iniciar ou encerrar janelas de ação.
## Sempre que o painel é reativado, ele volta ao Menu Principal para evitar que
## uma tela antiga fique aberta no turno de outro combatente.

## Exibe o painel para um combatente e prepara o menu principal do turno.
func ativar_para(combatente: CombatenteData) -> void:
	combatente_ativo = combatente
	combatente_ref = combatente
	show()
	habilitar_acoes()

	call_deferred("_focar_botao")

## Move o foco para o primeiro comando para permitir navegação por teclado.
func _focar_botao() -> void:
	botao_atacar.grab_focus()

## Libera os comandos do turno atual e restaura a tela principal.
func habilitar_acoes() -> void:
	# Reabre o painel no estado principal e libera os comandos do turno atual.
	acoes_habilitadas = true
	_mostrar_menu_principal()
	botao_atacar.disabled = false
	botao_pericia.disabled = false
	botao_habilidade.disabled = false
	botao_item.disabled = false
	botao_passar.disabled = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true

## Bloqueia interação enquanto o CombatManager processa uma ação.
func desabilitar_acoes() -> void:
	# Usado enquanto outra seleção está em andamento, como região de ataque ou alvo.
	acoes_habilitadas = false
	_limpar_tela_contextual()
	botao_atacar.disabled = true
	botao_pericia.disabled = true
	botao_habilidade.disabled = true
	botao_item.disabled = true
	botao_passar.disabled = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

## ===== NAVEGAÇÃO BASE =====
## Estas funções controlam quais partes da interface ficam visíveis. O mesmo
## modelo é usado por Perícias e Habilidades e deixa a futura tela de Itens
## Consumíveis preparada para entrar sem menus flutuantes.

## Mostra os controles fixos e limpa qualquer subtela contextual aberta.
func _mostrar_menu_principal() -> void:
	estado_menu = EstadoMenu.PRINCIPAL
	_limpar_tela_contextual()
	botao_atacar.show()
	botao_pericia.show()
	botao_habilidade.show()
	botao_item.show()
	spacer_principal.show()
	botao_passar.show()
	call_deferred("_focar_botao")

## Esconde os controles fixos antes de abrir uma subtela.
func _ocultar_menu_principal() -> void:
	botao_atacar.hide()
	botao_pericia.hide()
	botao_habilidade.hide()
	botao_item.hide()
	spacer_principal.hide()
	botao_passar.hide()

## Remove nós temporários da subtela sem remover os controles permanentes.
func _limpar_tela_contextual() -> void:
	# Remove somente os nós criados pelas subtelas, preservando os botões fixos.
	for controle in controles_tela_atual:
		if is_instance_valid(controle):
			if controle.get_parent() != null:
				controle.get_parent().remove_child(controle)
			controle.queue_free()
	controles_tela_atual.clear()

## Cria e registra o título da subtela atual.
func _criar_titulo_tela(texto: String) -> Label:
	var label = Label.new()
	label.text = texto
	label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(label)
	controles_tela_atual.append(label)
	return label

## Cria o comando Voltar com o destino fornecido pelo fluxo de navegação.
func _criar_botao_voltar(callback: Callable) -> Button:
	# Toda subtela possui Voltar para manter a navegação previsível.
	var voltar = _criar_botao("VOLTAR", "Retorna à tela anterior", callback)
	vbox.add_child(voltar)
	controles_tela_atual.append(voltar)
	return voltar

## Cria uma lista rolável e devolve seu container interno para preenchimento.
func _criar_scroll_lista(altura_minima: int = 180) -> VBoxContainer:
	# A lista rolável evita que muitas habilidades ou itens estourem o painel.
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, altura_minima)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.clip_contents = true

	var lista = VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 4)
	scroll.add_child(lista)

	vbox.add_child(scroll)
	controles_tela_atual.append(scroll)
	return lista

## Cria uma mensagem informativa temporária na subtela.
func _criar_label_info(texto: String) -> Label:
	var label = Label.new()
	label.text = texto
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(label)
	controles_tela_atual.append(label)
	return label

## ===== CALLBACKS DO MENU PRINCIPAL =====
## Cada botão inicia um fluxo diferente. Ataque e Item ainda delegam ao
## CombatManager; Perícias e Habilidades navegam dentro do ActionPanel.

## Inicia o fluxo externo de seleção de regiões e alvo para um ataque.
func _on_atacar_pressionado() -> void:
	# Inicia o fluxo externo: selecionar regiões, selecionar alvo e processar ataque.
	desabilitar_acoes()
	acao_atacar.emit()

## Abre a lista de perícias conhecidas pelo combatente ativo.
func _on_pericia_pressionado() -> void:
	abrir_menu_pericias()

## Abre a lista de habilidades disponíveis no turno.
func _on_habilidade_pressionada() -> void:
	abrir_menu_habilidades()

## Abre o inventário contextual do combatente ativo.
func _on_item_pressionado() -> void:
	abrir_menu_itens()

## Emite o encerramento voluntário do turno atual.
func _on_passar_turno() -> void:
	# Finaliza voluntariamente o turno do combatente ativo.
	print("[ActionPanel] Turno passado")
	turno_passado.emit()

## Mantém compatibilidade com o antigo botão direto de Duelo.
func _on_botao_duelo_pressed() -> void:
	pericia_escolhida.emit("Duelo")

## ===== TELA DE PERÍCIAS =====
## Mantém a filosofia já existente: o jogador sai do Menu Principal, escolhe uma
## perícia conhecida e o ActionPanel emite um sinal sem decidir a regra.

## Monta a lista de perícias treinadas e oferece seus detalhes.
func abrir_menu_pericias() -> void:
	if combatente_ref == null:
		return

	estado_menu = EstadoMenu.PERICIAS

	_ocultar_menu_principal()
	_limpar_tela_contextual()

	_criar_titulo_tela("Perícias")

	var lista = _criar_scroll_lista()

	var pericias = _obter_pericias_conhecidas()

	if pericias.is_empty():
		var vazio = Label.new()
		vazio.text = "Nenhuma perícia treinada."
		lista.add_child(vazio)
	else:
		for pericia in pericias:
			lista.add_child(_criar_botao_pericia(pericia))

	_criar_botao_voltar(fechar_menu_pericias)

	_focar_primeiro_botao(lista)


## Aguarda a montagem da lista e foca seu primeiro botão habilitado.
func _focar_primeiro_botao(container: VBoxContainer) -> void:

	await get_tree().process_frame

	if not is_instance_valid(container):
		return

	for child in container.get_children():

		if child is Button and child.visible and not child.disabled:

			child.grab_focus()
			return

## Fecha a lista de perícias e retorna ao menu principal.
func fechar_menu_pericias() -> void:
	_mostrar_menu_principal()
	call_deferred("_focar_botao")

## ===== TELA DE HABILIDADES =====
## Fluxo implementado:
## Menu Principal -> Lista de Habilidades -> Detalhes -> Confirmar Uso.
## Nenhuma etapa usa menus flutuantes; tudo é composto no próprio painel para manter
## consistência visual com Perícias e facilitar reuso por Itens Consumíveis.

## Monta a lista agrupada de habilidades e a opção de Sobrecarga.
func abrir_menu_habilidades() -> void:
	if combatente_ref == null:
		print("[ActionPanel] Combatente não possui referência")
		return
	estado_menu = EstadoMenu.HABILIDADES
	_ocultar_menu_principal()
	_limpar_tela_contextual()
	_criar_titulo_tela("Habilidades")
	var lista = _criar_scroll_lista(220)
	var habilidades_disponiveis = _obter_habilidades_conhecidas()
	if habilidades_disponiveis.is_empty() and not combatente_ref.habilidade_sobrecarga_ativa:
		var vazio = Label.new()
		vazio.text = "Nenhuma habilidade disponível."
		lista.add_child(vazio)
	else:
		_preencher_lista_habilidades(lista, habilidades_disponiveis)
	_criar_botao_voltar(_mostrar_menu_principal)
	_focar_primeiro_botao(lista)
	

## Monta a lista de itens presentes no inventário do combatente.
func abrir_menu_itens() -> void:
	if combatente_ref == null:
		return
	estado_menu = EstadoMenu.ITENS
	_ocultar_menu_principal()
	_limpar_tela_contextual()
	_criar_titulo_tela("Itens")
	var lista = _criar_scroll_lista()
	var inventario = item_db.listar_inventario(combatente_ref)
	if inventario.is_empty():
		var vazio = Label.new()
		vazio.text = "Nenhum item."
		lista.add_child(vazio)
	else:
		for nome_item in inventario:
			var item = item_db.get_item(nome_item)
			if item == null:
				continue
			var btn = _criar_botao(
				item.nome,
				item.descricao,
				_abrir_detalhes_item.bind(item)
			)
			lista.add_child(btn)
	_criar_botao_voltar(_mostrar_menu_principal)
	_focar_primeiro_botao(lista)

## Resolve os nomes de habilidades do combatente usando o banco de dados.
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

## Filtra conhecimentos treinados e retorna suas definições para a UI.
func _obter_pericias_conhecidas() -> Array:
	var resultado: Array = []

	for nome_pericia in combatente_ref.conhecimentos_treino.keys():
		var treino = combatente_ref.conhecimentos_treino[nome_pericia]

		if treino <= 0:
			continue

		var pericia = pericia_db.get_pericia(nome_pericia)

		if pericia != null:
			resultado.append(pericia)

	return resultado

## Agrupa habilidades por tipo e adiciona Sobrecarga quando aplicável.
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
		secao.add_theme_font_size_override("font_size", 14)
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

## Cria o botão resumido de uma habilidade, exibindo tipo e custo de PA.
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

## Cria o botão resumido de um item do inventário.
func _criar_botao_item(item: ItemData.Item) -> Button:
	var texto := "%s | %s" % [
		item.nome,
		ItemData.tipo_item_para_texto(item.tipo)
	]
	if item.quantidade > 1:
		texto += " | x%d" % item.quantidade
	return _criar_botao(
		texto,
		"Ver detalhes de %s" % item.nome,
		_abrir_detalhes_item.bind(item)
	)

## Cria o botão de uma perícia e informa seu nível de treino.
func _criar_botao_pericia(pericia) -> Button:
	var treino = combatente_ref.conhecimentos_treino.get(pericia.nome, 0)

	var texto = "%s (+%d)" % [
		pericia.nome,
		treino
	]

	return _criar_botao(
		texto,
		"Ver detalhes de %s" % pericia.nome,
		_abrir_detalhes_pericia.bind(pericia)
	)

## Exibe descrição, treino e confirmação de uso de uma perícia.
func _abrir_detalhes_pericia(pericia) -> void:
	estado_menu = EstadoMenu.DETALHE_PERICIA

	_limpar_tela_contextual()

	_criar_titulo_tela(pericia.nome)

	var detalhes = _criar_scroll_lista()

	var treino = combatente_ref.conhecimentos_treino.get(pericia.nome, 0)

	_adicionar_linha_detalhe(
		detalhes,
		"Treino",
		"+%d" % treino
	)

	_adicionar_linha_detalhe(
		detalhes,
		"Descrição",
		pericia.descricao
	)

	var confirmar = _criar_botao(
		"USAR PERÍCIA",
		"Executar perícia",
		_confirmar_pericia.bind(pericia.nome)
	)

	vbox.add_child(confirmar)
	controles_tela_atual.append(confirmar)

	_criar_botao_voltar(abrir_menu_pericias)

	confirmar.grab_focus()

## Exibe os detalhes e a confirmação de uso de um item.
func _abrir_detalhes_item(item) -> void:
	estado_menu = EstadoMenu.DETALHE_ITEM
	_limpar_tela_contextual()
	_criar_titulo_tela(item.nome)
	var detalhes = _criar_scroll_lista()
	_adicionar_linha_detalhe(
		detalhes,
		"Tipo",
		"Consumível"
	)
	_adicionar_linha_detalhe(
		detalhes,
		"Descrição",
		item.descricao
	)
	var confirmar = _criar_botao(
		"USAR ITEM",
		"Usar este item",
		_confirmar_item.bind(item.nome)
	)
	vbox.add_child(confirmar)
	controles_tela_atual.append(confirmar)
	_criar_botao_voltar(abrir_menu_itens)
	confirmar.grab_focus()

## Exibe custo, origem, alcance e efeito antes de confirmar uma habilidade.
func _abrir_detalhes_habilidade(habilidade) -> void:
	estado_menu = EstadoMenu.DETALHE_HABILIDADE
	_limpar_tela_contextual()
	_criar_titulo_tela(habilidade.nome)

	var detalhes = _criar_scroll_lista(240)
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

## Exibe e confirma a regra especial de Sobrecarga (Ir Além).
func _abrir_detalhes_sobrecarga() -> void:
	# Sobrecarga é uma regra especial do combate que não está no banco principal
	# de HabilidadeData. Ela recebe uma tela de detalhes própria para preservar
	# o mesmo fluxo de confirmação das demais habilidades.
	estado_menu = EstadoMenu.DETALHE_HABILIDADE
	_limpar_tela_contextual()
	_criar_titulo_tela("Sobrecarga (Ir Além)")

	var detalhes = _criar_scroll_lista(220)
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

## Adiciona uma linha formatada de informação à tela de detalhes.
func _adicionar_linha_detalhe(container: VBoxContainer, rotulo: String, valor: String) -> void:
	# Usa RichTextLabel para suportar descrições longas sem quebrar o painel.
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = "[b]%s:[/b] %s" % [rotulo, valor]
	container.add_child(label)

## Evita campos vazios na interface usando um texto substituto.
func _texto_ou_padrao(texto: String, padrao: String) -> String:
	if texto.strip_edges() == "":
		return padrao
	return texto

## Fecha a tela e emite a perícia confirmada ao CombatManager.
func _confirmar_pericia(nome_pericia:String) -> void:
	print("[ActionPanel] Perícia confirmada: %s" % nome_pericia)
	_mostrar_menu_principal()
	call_deferred("_focar_botao")
	pericia_escolhida.emit(nome_pericia)

## Fecha a tela e emite a habilidade confirmada ao CombatManager.
func _confirmar_habilidade(nome_habilidade: String) -> void:
	print("[ActionPanel] Habilidade confirmada: %s" % nome_habilidade)
	_mostrar_menu_principal()
	call_deferred("_focar_botao")
	habilidade_escolhida.emit(nome_habilidade)

## Fecha a tela e emite o item confirmado ao CombatManager.
func _confirmar_item(nome_item:String) -> void:
	print("[ActionPanel] Item confirmado: %s" % nome_item)
	_mostrar_menu_principal()
	call_deferred("_focar_botao")
	item_escolhido.emit(nome_item)

## Confirma a ativação de Sobrecarga e emite seu sinal específico.
func _confirmar_sobrecarga() -> void:
	print("[ActionPanel] Sobrecarga confirmada")
	_mostrar_menu_principal()
	call_deferred("_focar_botao")
	habilidade_sobrecarga.emit()

## ===== MENUS ESPECÍFICOS / COMPATIBILIDADE =====
## Métodos mantidos para chamadas externas antigas. Eles agora redirecionam para
## o fluxo interno sem menus flutuantes.

## Mantém a API antiga redirecionando para o menu interno de perícias.
func mostrar_menu_pericias(_combatente: CombatenteData) -> void:
	abrir_menu_pericias()

## Mantém a API antiga redirecionando para o menu interno de habilidades.
func mostrar_menu_habilidades(_combatente: CombatenteData) -> void:
	abrir_menu_habilidades()

## Mantém a API antiga redirecionando para o menu interno de itens.
func mostrar_menu_itens(_combatente: CombatenteData) -> void:
	abrir_menu_itens()
