extends Control

var regioes: Array[String] = [
	"Torso",
	"Braço Direito",
	"Braço Esquerdo",
	"Perna Direita",
	"Perna Esquerda"
]

var selecionadas: Array[bool] = [false, false, false, false, false]
var estresse: Array[int] = [0, 0, 0, 0, 0]

var indice_atual: int = 0
var estado: String = "selecionando"
var indices_escolhidos: Array[int] = []
var valores_rolados: Array[int] = []
var dados_pendentes: int = 0

@onready var label: Label = $Label
@onready var dados_container: HBoxContainer = $HBoxContainer

const ZONA_ACERTO_EXTREMO: int = 6
const ZONA_ACERTO_REGULAR: int = 4

func _ready() -> void:
	randomize()
	_conectar_dados()
	esconder_dados()
	atualizar_texto()

func _conectar_dados() -> void:
	for i in range(dados_container.get_child_count()):
		var dado: DadoUI = dados_container.get_child(i) as DadoUI
		if dado != null:
			var slot: int = i
			dado.dado_rolado.connect(func(valor: int) -> void:
				_on_dado_rolado(valor, slot)
			)

func _process(_delta: float) -> void:
	if estado == "selecionando":
		if Input.is_action_just_pressed("ui_up"):
			indice_atual = max(0, indice_atual - 1)
			atualizar_texto()

		if Input.is_action_just_pressed("ui_down"):
			indice_atual = min(regioes.size() - 1, indice_atual + 1)
			atualizar_texto()

		if Input.is_action_just_pressed("ui_right"):
			selecionadas[indice_atual] = true
			atualizar_texto()

		if Input.is_action_just_pressed("ui_left"):
			selecionadas[indice_atual] = false
			atualizar_texto()

		if Input.is_action_just_pressed("ui_accept"):
			confirmar_selecao()

	elif estado == "resultado":
		if Input.is_action_just_pressed("ui_cancel"):
			voltar_para_selecao()

func atualizar_texto() -> void:
	var texto: String = "Escolha as regiões:\n\n"

	for i in range(regioes.size()):
		var cursor: String = "> " if i == indice_atual else "  "
		var marcado: String = "[X] " if selecionadas[i] else "[ ] "
		texto += cursor + marcado + regioes[i] + " (Estresse: " + str(estresse[i]) + ")\n"

	texto += "\n↑↓ navegar | → marcar | ← desmarcar | Enter confirmar"
	label.text = texto

func confirmar_selecao() -> void:
	indices_escolhidos.clear()

	for i in range(regioes.size()):
		if selecionadas[i]:
			indices_escolhidos.append(i)

	if indices_escolhidos.is_empty():
		print("Nenhuma região selecionada.")
		return

	if indices_escolhidos.size() > dados_container.get_child_count():
		print("Há mais regiões selecionadas do que dados disponíveis.")
		return

	estado = "aguardando_cliques"
	valores_rolados.clear()
	valores_rolados.resize(indices_escolhidos.size())
	for i in range(valores_rolados.size()):
		valores_rolados[i] = 0
	dados_pendentes = indices_escolhidos.size()

	_preparar_dados_visuais(indices_escolhidos.size())
	label.text = "Clique nos dados para rolar."

func _preparar_dados_visuais(qtd: int) -> void:
	mostrar_dados(qtd)

	for i in range(qtd):
		var dado := dados_container.get_child(i) as DadoUI
		if dado != null:
			dado.preparar()

func _on_dado_rolado(valor: int, slot: int) -> void:
	if estado != "aguardando_cliques":
		return

	if slot < 0 or slot >= valores_rolados.size():
		return

	if valores_rolados[slot] != 0:
		return

	valores_rolados[slot] = valor
	dados_pendentes -= 1

	if dados_pendentes <= 0:
		finalizar_combate()

func finalizar_combate() -> void:
	var regioes_escolhidas: Array[String] = []

	for i in indices_escolhidos:
		regioes_escolhidas.append(regioes[i])

	var resultado: Dictionary = rolar_teste_combate_d6(regioes_escolhidas, 3, 2, 1, valores_rolados)

	print("\n=== COMBATE D6 ===")
	print(JSON.stringify(resultado, "\t"))

	aplicar_estresse(resultado)

	var texto: String = "RESULTADO DO COMBATE:\n\n"
	for r in resultado["resultados_por_regiao"]:
		var regiao_nome: String = String(r["regiao"])
		var dado_valor: int = int(r["dado"])
		var categoria: String = String(r["categoria"])
		var acertos: int = int(r["acertos"])
		texto += regiao_nome + ": D" + str(dado_valor) + " | " + categoria + " | Acertos: " + str(acertos) + "\n"

	texto += "\nTotal de Sucessos: " + str(resultado["total_sucessos"])
	texto += "\nEstresse Gerado: " + str(resultado["estresse_gerado"])

	if bool(resultado["dano_causado"]):
		texto += "\nDano Causado: " + str(resultado["dano_aplicado"])
	else:
		texto += "\nAtaque defendido."

	texto += "\n\nPressione Esc para voltar."
	label.text = texto

	for i in range(selecionadas.size()):
		selecionadas[i] = false

	estado = "resultado"

func voltar_para_selecao() -> void:
	estado = "selecionando"
	valores_rolados.clear()
	indices_escolhidos.clear()
	dados_pendentes = 0
	esconder_dados()
	atualizar_texto()

func aplicar_estresse(resultado: Dictionary) -> void:
	var resultados: Array = resultado["resultados_por_regiao"]

	for item in resultados:
		var r: Dictionary = item
		var regiao_nome: String = String(r["regiao"])
		var index: int = regioes.find(regiao_nome)

		if index == -1:
			continue

		var categoria: String = String(r["categoria"])

		if categoria == "Falha Crítica":
			estresse[index] += 2
		elif categoria == "Falha Regular":
			estresse[index] += 1

func mostrar_dados(qtd: int) -> void:
	for i in range(dados_container.get_child_count()):
		var dado := dados_container.get_child(i) as Control
		if dado != null:
			dado.visible = i < qtd

func esconder_dados() -> void:
	for dado in dados_container.get_children():
		var dado_control := dado as Control
		if dado_control != null:
			dado_control.visible = false

func rolar_teste_combate_d6(regioes_arriscadas: Array[String], protecao_alvo: int, dano_arma: int, atributo_dano: int, dados_fixos: Array[int] = []) -> Dictionary:
	var quantidade: int = clamp(regioes_arriscadas.size(), 1, 5)
	regioes_arriscadas = regioes_arriscadas.slice(0, quantidade)

	var resultados: Array = []
	var sucessos_regulares: int = 0
	var sucessos_extremos: int = 0
	var falhas_regulares: int = 0
	var falhas_criticas: int = 0
	var estresse_gerado: int = 0

	for i in range(regioes_arriscadas.size()):
		var regiao: String = regioes_arriscadas[i]
		var dado: int = 0

		if i < dados_fixos.size():
			dado = dados_fixos[i]
		else:
			dado = randi_range(1, 6)

		var categoria: String = avaliar_resultado_d6(dado)
		var acertos: int = 0

		if categoria == "Sucesso Extremo":
			acertos = 2
			sucessos_extremos += 1
		elif categoria == "Sucesso Regular":
			acertos = 1
			sucessos_regulares += 1
		elif categoria == "Falha Crítica":
			falhas_criticas += 1
			estresse_gerado += 2
		else:
			falhas_regulares += 1
			estresse_gerado += 1

		resultados.append({
			"regiao": regiao,
			"dado": dado,
			"categoria": categoria,
			"acertos": acertos
		})

	var total_sucessos: int = sucessos_regulares + (sucessos_extremos * 2)
	var dano_aplicado: int = 0
	var protecao_temporaria: int = max(protecao_alvo - total_sucessos, 0)
	var dano_causado: bool = false

	if total_sucessos >= protecao_alvo:
		dano_aplicado = dano_arma + atributo_dano
		dano_causado = true
		protecao_temporaria = 0

	return {
		"tipo": "Combate D6",
		"regioes_arriscadas": regioes_arriscadas,
		"resultados_por_regiao": resultados,
		"sucessos_regulares": sucessos_regulares,
		"sucessos_extremos": sucessos_extremos,
		"falhas_regulares": falhas_regulares,
		"falhas_criticas": falhas_criticas,
		"total_sucessos": total_sucessos,
		"estresse_gerado": estresse_gerado,
		"protecao_alvo": protecao_alvo,
		"protecao_temporaria": protecao_temporaria,
		"dano_aplicado": dano_aplicado,
		"dano_causado": dano_causado
	}

func avaliar_resultado_d6(valor: int) -> String:
	if valor == ZONA_ACERTO_EXTREMO:
		return "Sucesso Extremo"
	elif valor >= ZONA_ACERTO_REGULAR:
		return "Sucesso Regular"
	elif valor == 1:
		return "Falha Crítica"
	else:
		return "Falha Regular"
