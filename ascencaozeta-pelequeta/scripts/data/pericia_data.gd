## Sistema de Conhecimentos OBLIVIO RPG
## 10 Conhecimentos com testes D6 + atributo base + treino
## Zona de Acerto: 1=crítico falha, 2-3=falha normal, 4-5=sucesso, 6=sucesso extremo

class_name PericiaData
extends RefCounted
class Pericia:
	var nome: String
	var descricao: String
	func _init(
		p_nome:String,
		p_descricao:String
	):
		nome = p_nome
		descricao = p_descricao

var banco := {}
func _init():
	_registrar_pericias()

func _registrar_pericias():

	banco["Bandidagem"] = Pericia.new(
		"Bandidagem",
		"Cometer delitos, furtar, invadir locais e agir fora da lei."
	)

	banco["Duelo"] = Pericia.new(
		"Duelo",
		"Analisa o estilo de combate do inimigo procurando brechas e pontos fracos."
	)

	banco["Emocional"] = Pericia.new(
		"Emocional",
		"Controla sentimentos, supera medo e mantém a calma em situações extremas."
	)

	banco["Esforço"] = Pericia.new(
		"Esforço",
		"Executa ações fisicamente desgastantes e suporta grandes esforços."
	)

	banco["Místico"] = Pericia.new(
		"Místico",
		"Compreensão de fenômenos sobrenaturais, magia e entidades."
	)

	banco["Mundo"] = Pericia.new(
		"Mundo",
		"Conhecimento sobre natureza, fauna, flora e sobrevivência."
	)

	banco["Rastro"] = Pericia.new(
		"Rastro",
		"Encontrar pistas, perceber detalhes e interpretar vestígios."
	)

	banco["Reflexos"] = Pericia.new(
		"Reflexos",
		"Movimentos rápidos, esquivas e ações que exigem velocidade."
	)

	banco["Saber"] = Pericia.new(
		"Saber",
		"Conhecimentos gerais, memória e assuntos estudados."
	)

	banco["Social"] = Pericia.new(
		"Social",
		"Persuasão, blefe, intimidação e interação com outras pessoas."
	)

func get_pericia(nome:String) -> Pericia:
	return banco.get(nome)

func obter_pericias() -> Array:
	return banco.keys()

func obter_descricao(nome:String) -> String:
	var pericia = get_pericia(nome)
	if pericia == null:
		return ""
	return pericia.descricao

func testar_pericia(
	combatente: CombatenteData,
	nome_pericia: String
) -> Dictionary:

	var dado := randi_range(1, 6)

	var resultado := ""

	match dado:
		1:
			resultado = "Falha Crítica"

		2,3:
			resultado = "Falha"

		4,5:
			resultado = "Sucesso"

		6:
			resultado = "Sucesso Extremo"

	return {
		"personagem": combatente.nome,
		"pericia": nome_pericia,
		"dado": dado,
		"resultado": resultado,
		"sucesso": dado >= 4
	}

func executar_duelo(
	combatente: CombatenteData,
	_alvo: CombatenteData
) -> Dictionary:

	var teste = testar_pericia(
		combatente,
		"Duelo"
	)

	match teste.resultado:

		"Falha Crítica":
			return {
				"resultado": teste.resultado,
				"analisado": false,
				"reduzir_protecao": false
			}

		"Falha":
			return {
				"resultado": teste.resultado,
				"analisado": false,
				"reduzir_protecao": false
			}

		"Sucesso":
			return {
				"resultado": teste.resultado,
				"analisado": true,
				"reduzir_protecao": false
			}

		"Sucesso Extremo":
			return {
				"resultado": teste.resultado,
				"analisado": true,
				"reduzir_protecao": true
			}

	return {}
