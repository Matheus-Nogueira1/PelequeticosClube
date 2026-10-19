## Sistema de Itens - Consumíveis e Equipamentos
## Estus Flask: Restaura Estresse em uma região

class_name ItemData
extends RefCounted

enum TipoItem {
	CONSUMIVEL = 1,
	EQUIPAMENTO = 2,
	QUEST = 3
}

class Item:
	var nome: String
	var descricao: String
	var tipo: TipoItem
	var quantidade: int = 1
	var efeitos: Dictionary = {}
	
	func _init(p_nome: String, p_tipo: TipoItem, p_descricao: String = ""):
		nome = p_nome
		tipo = p_tipo
		descricao = p_descricao

## ===== ITENS DISPONÍVEIS =====

## Estus Flask - Restaura Estresse em uma região
static func criar_estus_flask(quantidade: int = 1) -> Item:
	var item = Item.new("Frasco Estus", TipoItem.CONSUMIVEL, "Restaura toda fadiga de uma região do corpo")
	item.quantidade = quantidade
	item.efeitos = {
		"tipo": "restaurar_estresse_regiao",
		"quantidade": 10  # Restaura 10 pontos de Estresse
	}
	return item

## Retorna o Item correspondente ao nome salvo no inventário (null se não existir)
static func obter_item(nome_item: String) -> Item:
	match nome_item.strip_edges().to_lower():
		"frasco estus":
			return criar_estus_flask()
	return null

## Agrupa os consumíveis do inventário: [{"nome", "item", "quantidade"}]
static func listar_consumiveis(combatente: CombatenteData) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	var contagem: Dictionary = {}

	for nome_item in combatente.inventario:
		contagem[nome_item] = int(contagem.get(nome_item, 0)) + 1

	for nome_item in contagem.keys():
		var item: Item = obter_item(nome_item)
		if item == null or item.tipo != TipoItem.CONSUMIVEL:
			continue
		resultado.append({
			"nome": nome_item,
			"item": item,
			"quantidade": contagem[nome_item]
		})

	return resultado

## Usa o item no combatente
static func usar_item(combatente: CombatenteData, item: Item, alvo_regiao: String = "Torso") -> Dictionary:
	"""
	Usa um item e retorna resultado
	"""
	match item.nome:
		"Frasco Estus":
			return usar_estus_flask(combatente, alvo_regiao)
		_:
			return {"sucesso": false, "mensagem": "Item desconhecido"}

## Usa Estus Flask - Restaura Estresse de uma região
static func usar_estus_flask(combatente: CombatenteData, regiao: String) -> Dictionary:
	"""
	Estus Flask: Restaura toda fadiga (estresse) de uma região
	Reduz o estresse da região para 0
	"""
	if not combatente.estresse_por_regiao.has(regiao):
		return {
			"sucesso": false,
			"mensagem": "Região inválida: %s" % regiao
		}
	
	var estresse_antes = combatente.estresse_por_regiao[regiao]["atual"]
	combatente.aliviar_estresse(regiao, estresse_antes)  # Remove todo estresse
	
	return {
		"sucesso": true,
		"regiao": regiao,
		"estresse_restaurado": estresse_antes,
		"mensagem": "%s bebeu Estus Flask e recuperou %d pontos de fadiga em %s!" % [
			combatente.nome, 
			estresse_antes,
			regiao
		]
	}

## Retorna lista de itens de um combatente
static func listar_inventario(combatente: CombatenteData) -> Array[String]:
	var lista: Array[String] = []
	for item_nome in combatente.inventario:
		lista.append(item_nome)
	return lista

## Verifica se combatente tem um item
static func tem_item(combatente: CombatenteData, nome_item: String) -> bool:
	return nome_item in combatente.inventario

## Remove item do inventário
static func remover_item(combatente: CombatenteData, nome_item: String) -> bool:
	if tem_item(combatente, nome_item):
		combatente.inventario.erase(nome_item)
		return true
	return false

## Adiciona item ao inventário
static func adicionar_item(combatente: CombatenteData, nome_item: String) -> void:
	if not tem_item(combatente, nome_item):
		combatente.inventario.append(nome_item)
