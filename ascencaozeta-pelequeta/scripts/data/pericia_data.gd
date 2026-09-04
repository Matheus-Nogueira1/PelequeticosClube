## Sistema de Conhecimentos OBLIVIO RPG
## 10 Conhecimentos com testes D6 + atributo base + treino
## Zona de Acerto: 1=crítico falha, 2-3=falha normal, 4-5=sucesso, 6=sucesso extremo

class_name PericiaData
extends RefCounted

## Mapa de Conhecimentos OBLIVIO para seus atributos base
const CONHECIMENTOS_ATRIBUTOS = {
	"Bandidagem": "fuga",       # Delitos, furtividade de crimes
	"Duelo": "forca",           # Estratégia marcial, brechas em defesa
	"Emocional": "determinacao", # Autocontrole, gestão de sentimentos
	"Esforço": "carne",         # Físico desgastante, resistência corporal
	"Místico": "mente",         # Sobrenatural, artes arcanas, seres outros
	"Mundo": "mente",           # Natureza, animais, sobrevivência
	"Rastro": "fuga",           # Percepção, detalhes ocultos, sensoriais
	"Reflexos": "fuga",         # Esquiva, corporais rápidos, movimento
	"Saber": "mente",           # Memória, estudos, conhecimento geral
	"Social": "determinacao"    # Persuasão, manipulação emocional, charisma
}

## Descrições dos 10 Conhecimentos OBLIVIO
const CONHECIMENTOS_DESCRICOES = {
	"Bandidagem": "Cometer delitos, furto, invasão, se esgueirar de guardas",
	"Duelo": "Estratégia de combate, identificar brechas na defesa, vantagens táticas",
	"Emocional": "Controlar raiva, lágrimas, manter calma, enfrentar medos",
	"Esforço": "Ações cansativas, manter fôlego, empurrar pesado, resistir venenos",
	"Místico": "Fenômenos sobrenaturais, runas arcanas, seres de outra realidade",
	"Mundo": "Natureza, animais selvagens, pontos cardeais, plantas venenosas",
	"Rastro": "Percepção aguçada, encontrar coisas, ler lábios, farejar pistas",
	"Reflexos": "Esquivar-se, acertar alvo em movimento, manter equilíbrio",
	"Saber": "Memória de estudos, hobby favorito, conversa em mesa de bar",
	"Social": "Persuadir, mentir, convencer, acalmar emoções alheias"
}

## Testa um Conhecimento OBLIVIO (D6 + atributo base + treino + especialização)
func testar_conhecimento(combatente: CombatenteData, conhecimento: String, _dificuldade: int = 0) -> Dictionary:
	# Validar conhecimento
	if not CONHECIMENTOS_ATRIBUTOS.has(conhecimento):
		return {
			"sucesso": false,
			"conhecimento": conhecimento,
			"personagem": combatente.nome,
			"erro": "Conhecimento não existe: %s" % conhecimento
		}
	
	# Bonus de especialização
	var bonus_especializacao = 0
	if combatente.tem_especializacao(conhecimento):
		bonus_especializacao = 2
	
	# Rolar D6
	var dado = randi_range(1, 6)
	var resultado_final = dado
	if combatente.tem_especializacao(conhecimento):
		resultado_final += 2
	resultado_final = clampi(resultado_final, 1, 6)
	
	# ZONA DE ACERTO OBLIVIO 2.2:
	# 1 = Falha Crítica (algo extremamente ruim acontece)
	# 2-3 = Falha Regular (não acontece como esperado)
	# 4-5 = Sucesso Regular (o que era esperado acontece)
	# 6 = Sucesso Extremo (algo adicional favorável acontece)
	
	var resultado: String
	var sucesso: bool
	
	match resultado_final:
		1:
			resultado = "Falha Crítica"
			sucesso = false
		2, 3:
			resultado = "Falha"
			sucesso = false
		4, 5:
			resultado = "Sucesso"
			sucesso = true
		6:
			resultado = "Sucesso Extremo"
			sucesso = true
	
	return {
		"conhecimento": conhecimento,
		"personagem": combatente.nome,
		"dado": dado,
		"resultado_final": resultado_final,
		"especializado": combatente.tem_especializacao(conhecimento),
		"bonus_especializacao": bonus_especializacao,
		"resultado": resultado,
		"sucesso": sucesso
	}

## Retorna lista de todos os Conhecimentos disponíveis
func obter_conhecimentos() -> Array[String]:
	var lista: Array[String] = []
	for conhecimento in CONHECIMENTOS_ATRIBUTOS.keys():
		lista.append(conhecimento)
	return lista

## Retorna os conhecimentos agrupados por atributo base
func conhecimentos_por_atributo(atributo: String) -> Array[String]:
	var lista: Array[String] = []
	for conhecimento in CONHECIMENTOS_ATRIBUTOS:
		if CONHECIMENTOS_ATRIBUTOS[conhecimento] == atributo:
			lista.append(conhecimento)
	return lista

## Retorna descrição de um conhecimento
func obter_descricao(conhecimento: String) -> String:
	if CONHECIMENTOS_DESCRICOES.has(conhecimento):
		return CONHECIMENTOS_DESCRICOES[conhecimento]
	return "Conhecimento desconhecido"	

## Retorna executar Duelo
func executar_duelo(
	combatente: CombatenteData,
	_alvo: CombatenteData
) -> Dictionary:
	var resultado_teste = testar_conhecimento(
		combatente,
		"Duelo"
	)
	match resultado_teste["resultado"]:
		"Falha Crítica":
			return {
				"resultado": "Falha Crítica",
				"analisado": false,
				"reduzir_protecao": false
			}
		"Falha":
			return {
				"resultado": "Falha",
				"analisado": false,
				"reduzir_protecao": false
			}
		"Sucesso":
			return {
				"resultado": "Sucesso",
				"analisado": true,
				"reduzir_protecao": false
			}
		"Sucesso Extremo":
			return {
				"resultado": "Sucesso Extremo",
				"analisado": true,
				"reduzir_protecao": true
			}
	return {}
