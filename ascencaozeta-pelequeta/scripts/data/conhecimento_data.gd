## Sistema de Conhecimentos OBLIVIO RPG
## 10 Conhecimentos com testes D6 + atributo base + treino
## Zona de Acerto: 1=crítico falha, 2-3=falha normal, 4-5=sucesso, 6=sucesso extremo

class_name ConhecimentoData
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
func testar_conhecimento(combatente: CombatenteData, conhecimento: String, _dificuldade: int = 0, dado_fixo: int = 0) -> Dictionary:
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
	
	# Dado bruto (1-6). dado_fixo permite usar o valor já mostrado na animação.
	var dado: int = randi_range(1, 6)
	if dado_fixo >= 1 and dado_fixo <= 6:
		dado = dado_fixo

	# Mesma regra de RolagemD6.calcular_teste_conhecimento:
	# bônus vem de calcular_bonus_conhecimento (sem limite de +2)
	# e 6 bruto força Sucesso Extremo.
	var bonus_total: int = combatente.calcular_bonus_conhecimento(conhecimento)
	var resultado_final: int = dado + bonus_total
	var categoria: String
	if dado == 6:
		categoria = "Sucesso Extremo"
	else:
		categoria = RolagemD6.avaliar_resultado_d6(resultado_final)

	# Converte para os nomes que os chamadores atuais já esperam.
	var resultado: String
	var sucesso: bool
	match categoria:
		"Falha Crítica":
			resultado = "Falha Crítica"
			sucesso = false
		"Falha Regular":
			resultado = "Falha"
			sucesso = false
		"Sucesso Regular":
			resultado = "Sucesso"
			sucesso = true
		_:
			resultado = "Sucesso Extremo"
			sucesso = true
	return {
		"conhecimento": conhecimento,
		"personagem": combatente.nome,
		"dado": dado,
		"resultado_final": resultado_final,
		"especializado": combatente.tem_especializacao(conhecimento),
		"bonus_especializacao": bonus_especializacao,
		"bonus_total": bonus_total,
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
func executar_duelo(combatente: CombatenteData, _alvo: CombatenteData, dado_fixo: int = 0) -> Dictionary:
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
