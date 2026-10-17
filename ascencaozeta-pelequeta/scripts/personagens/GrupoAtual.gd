
extends Node

var grupo: Array[CombatenteData] = []
var personagem_principal: CombatenteData = null


func definir_personagem_principal(nome: String) -> void:
	grupo = PersonagensData.criar_grupo_completo(nome)
	
	if grupo.is_empty():
		personagem_principal = null
		push_error("Não foi possível criar o grupo de personagens.")
		return
	
	personagem_principal = grupo[0]


func obter_personagem_principal() -> CombatenteData:
	return personagem_principal
