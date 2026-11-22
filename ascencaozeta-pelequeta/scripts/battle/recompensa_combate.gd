extends RefCounted
class_name RecompensaCombate

# ============================================================
# RECOMPENSA DE COMBATE
# Rolagem de 1D6 + modificador do rank. O resultado final (1 a 6)
# aponta a recompensa. Tudo que você ajusta fica no bloco CONFIGURAÇÃO.
# ============================================================

# ------------------------------------------------------------
# CONFIGURAÇÃO
# ------------------------------------------------------------

# Tabela B. Rank pendente (sem letra) usa MODIFICADOR_RANK_PENDENTE.
const MODIFICADOR_POR_RANK: Dictionary = {
	"C": -1,
	"B": 0,
	"A": 1,
	"S": 2,
	"SS": 3,
	"P": 4
}
const MODIFICADOR_RANK_PENDENTE: int = 0

# Itens de recurso ou suprimento (sorteio uniforme; repete se sair igual).
const SUPRIMENTOS: Array[String] = [
	"Recurso", "Munição", "Ração", "Combustível",
	"Estimulante", "Utensílio", "Kit de Primeiros Socorros"
]
# Quantos suprimentos saem nos resultados 3 e 4.
const QUANTIDADE_SUPRIMENTOS_3_4: int = 1

# Equipamentos que cada inimigo pode soltar (nome do inimigo -> lista).
# Vazio por padrão: sem equipamento cadastrado, o 5 e a parte de
# equipamento do 6 não entregam nada.
const EQUIPAMENTOS_POR_INIMIGO: Dictionary = {}

# ------------------------------------------------------------
# REGRAS
# ------------------------------------------------------------

static func modificador_do_rank(rank: String) -> int:
	return int(MODIFICADOR_POR_RANK.get(rank, MODIFICADOR_RANK_PENDENTE))


static func texto_modificador(modificador: int) -> String:
	if modificador == 0:
		return "0"
	return "%+d" % modificador


# Rola o D6 natural e resolve. Chamada uma vez por inimigo.
static func rolar(rank: String, inimigo: String) -> Dictionary:
	return resolver(randi_range(1, 6), rank, inimigo)


# Resolve a partir de um D6 natural já conhecido (facilita testar).
static func resolver(natural: int, rank: String, inimigo: String) -> Dictionary:
	var modificador: int = modificador_do_rank(rank)
	var resultado_final: int = clampi(natural + modificador, 1, 6)
	var itens: Array[Dictionary] = []
	var mensagem: String = ""

	match resultado_final:
		1, 2:
			mensagem = "Nenhum item encontrado."
		3, 4:
			for i in range(QUANTIDADE_SUPRIMENTOS_3_4):
				_somar(itens, _sortear_suprimento(), 1)
			mensagem = _descrever(itens, "Nenhum suprimento encontrado.")
		5:
			var equipamento: String = _sortear_equipamento(inimigo)
			if equipamento != "":
				_somar(itens, equipamento, 1)
			mensagem = _descrever(itens, "Nenhum equipamento encontrado.")
		6:
			var equipamento_6: String = _sortear_equipamento(inimigo)
			if equipamento_6 != "":
				_somar(itens, equipamento_6, 1)
			# Para o 6 não dar suprimento, apague a linha abaixo.
			_somar(itens, _sortear_suprimento(), 1)
			mensagem = _descrever(itens, "Nenhum item encontrado.")

	return {
		"natural": natural,
		"modificador": modificador,
		"final": resultado_final,
		"itens": itens,
		"mensagem": mensagem
	}


static func _sortear_suprimento() -> String:
	return SUPRIMENTOS[randi_range(0, SUPRIMENTOS.size() - 1)]


static func _sortear_equipamento(inimigo: String) -> String:
	var lista: Array = EQUIPAMENTOS_POR_INIMIGO.get(inimigo, [])
	if lista.is_empty():
		return ""
	return String(lista[randi_range(0, lista.size() - 1)])


# Soma na lista, juntando nomes iguais.
static func _somar(itens: Array[Dictionary], nome: String, quantidade: int) -> void:
	for item in itens:
		if item["nome"] == nome:
			item["quantidade"] = int(item["quantidade"]) + quantidade
			return
	itens.append({"nome": nome, "quantidade": quantidade})


static func _descrever(itens: Array[Dictionary], vazio: String) -> String:
	if itens.is_empty():
		return vazio
	var partes: Array[String] = []
	for item in itens:
		partes.append("%s x%d" % [item["nome"], int(item["quantidade"])])
	return ", ".join(partes)
