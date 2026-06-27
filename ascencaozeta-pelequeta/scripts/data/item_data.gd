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
	var efeitos := {}

	func _init(
		p_nome:String,
		p_tipo:TipoItem,
		p_descricao:String=""
	):
		nome = p_nome
		tipo = p_tipo
		descricao = p_descricao
var banco := {}

func _init():
	_registrar_itens()

func _registrar_itens():
	var estus = Item.new(
		"Frasco Estus",
		TipoItem.CONSUMIVEL,
		"Restaura completamente o Estresse de uma região do corpo."
	)

	estus.efeitos = {
		"tipo":"restaurar_estresse"
	}

	banco["Frasco Estus"] = estus

func get_item(nome:String) -> Item:
	return banco.get(nome)

func obter_itens() -> Array:
	return banco.keys()

func get_itens_do_combatente(combatente: CombatenteData) -> Array:
	var resultado:Array = []

	for nome in combatente.inventario:
		var item = get_item(nome)
		if item != null:
			resultado.append(item)

	return resultado

func possui_item(nome:String) -> bool:
	return banco.has(nome)

func obter_descricao(nome:String) -> String:
	var item = get_item(nome)

	if item == null:
		return ""

	return item.descricao

func item_existe(nome:String) -> bool:
	return banco.has(nome)



## Usa o item no combatente
static func usar_item(
	usuario: CombatenteData,
	alvo: CombatenteData,
	item: Item,
	regiao:String
) -> Dictionary:

	match item.efeitos["tipo"]:

		"restaurar_estresse":
			return usar_estus_flask(
				usuario,
				alvo,
				regiao
			)

	return {
		"sucesso":false,
		"mensagem":"Item desconhecido."
	}

## Usa Estus Flask - Restaura Estresse de uma região
static func usar_estus_flask(
	usuario:CombatenteData,
	alvo:CombatenteData,
	regiao:String
) ->Dictionary:
	"""
	Estus Flask: Restaura toda fadiga (estresse) de uma região
	Reduz o estresse da região para 0
	"""
	if not alvo.estresse_por_regiao.has(regiao):
		return {
			"sucesso":false,
			"mensagem":"Região inválida."
		}
	
	var estresse_antes = alvo.estresse_por_regiao[regiao]["atual"]
	alvo.aliviar_estresse(
		regiao,
		estresse_antes
	)
	
	return {
		"sucesso": true,
		"regiao": regiao,
		"estresse_restaurado": estresse_antes,
		"mensagem":
	"%s utilizou um Frasco Estus em %s, restaurando completamente o Estresse da região %s." % [
		usuario.nome,
		alvo.nome,
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
