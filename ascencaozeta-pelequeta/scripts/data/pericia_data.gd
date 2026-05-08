## Banco de dados de perícias OBLIVIO
## Cada perícia é vinculada a um atributo

class_name PericiaData
extends RefCounted

## Definição de uma perícia
class Pericia:
	var nome: String
	var descricao: String
	var atributo_base: String  # forca, inteligencia, agilidade, vontade, vitalidade
	var dificuldade_padrao: int = 0  # 0 para teste normal, maior = mais difícil
	
	func _init(p_nome: String, p_descricao: String, p_atributo: String, p_dif: int = 0):
		nome = p_nome
		descricao = p_descricao
		atributo_base = p_atributo
		dificuldade_padrao = p_dif

## Banco de todas as perícias
var pericias: Dictionary = {}

func _init() -> void:
	_inicializar_pericias()

func _inicializar_pericias() -> void:
	"""Define todas as perícias OBLIVIO disponíveis"""
	
	# Perícias de FORÇA
	pericias["Ataque com Espada"] = Pericia.new(
		"Ataque com Espada",
		"Atacar com uma espada ou arma branca similar",
		"forca"
	)
	
	pericias["Ataque Desarmado"] = Pericia.new(
		"Ataque Desarmado",
		"Lutar sem armas, usando puñhos ou técnicas marciais",
		"forca"
	)
	
	pericias["Escalar"] = Pericia.new(
		"Escalar",
		"Subir superfícies verticais ou difíceis",
		"forca"
	)
	
	# Perícias de INTELIGÊNCIA
	pericias["Conhecimento Geral"] = Pericia.new(
		"Conhecimento Geral",
		"Saber sobre história, cultura e fatos gerais",
		"inteligencia"
	)
	
	pericias["Investigação"] = Pericia.new(
		"Investigação",
		"Examinar cenas, buscar pistas e indícios",
		"inteligencia"
	)
	
	pericias["Ofício"] = Pericia.new(
		"Ofício",
		"Criar, reparar ou usar ferramentas especializadas",
		"inteligencia"
	)
	
	# Perícias de AGILIDADE
	pericias["Esquiva"] = Pericia.new(
		"Esquiva",
		"Desviar de ataques ou efeitos danosos",
		"agilidade"
	)
	
	pericias["Furtividade"] = Pericia.new(
		"Furtividade",
		"Mover-se silenciosamente ou esconder-se",
		"agilidade"
	)
	
	pericias["Acrobacia"] = Pericia.new(
		"Acrobacia",
		"Mover-se graciosamente, fazer flips ou outras manobras",
		"agilidade"
	)
	
	# Perícias de VONTADE
	pericias["Intimidação"] = Pericia.new(
		"Intimidação",
		"Assustar ou forçar com presença intimidadora",
		"vontade"
	)
	
	pericias["Resistência Mental"] = Pericia.new(
		"Resistência Mental",
		"Resistir a manipulação psicológica ou estresse",
		"vontade"
	)
	
	pericias["Liderança"] = Pericia.new(
		"Liderança",
		"Inspirar e guiar aliados",
		"vontade"
	)
	
	# Perícias de VITALIDADE
	pericias["Resistência"] = Pericia.new(
		"Resistência",
		"Suportar privação, fadiga ou dor",
		"vitalidade"
	)
	
	pericias["Medicina"] = Pericia.new(
		"Medicina",
		"Tratar ferimentos e doenças",
		"vitalidade"
	)
	
	pericias["Recuperação"] = Pericia.new(
		"Recuperação",
		"Recuperar-se de efeitos negativos mais rapidamente",
		"vitalidade"
	)

## Obtém uma perícia pelo nome
func get_pericia(nome: String) -> Pericia:
	if pericias.has(nome):
		return pericias[nome]
	return null

## Lista todas as perícias de um atributo
func pericias_por_atributo(atributo: String) -> Array:
	var lista = []
	for nome in pericias:
		if pericias[nome].atributo_base == atributo:
			lista.append(pericias[nome])
	return lista

## Testa uma perícia (rola D6 + atributo + treino vs dificuldade)
func testar_pericia(combatente: CombatenteData, nome_pericia: String, dificuldade: int = 0) -> Dictionary:
	var pericia = get_pericia(nome_pericia)
	
	if pericia == null:
		return {
			"sucesso": false,
			"resultado": 0,
			"dificuldade": dificuldade,
			"erro": "Perícia não encontrada: %s" % nome_pericia
		}
	
	# Obter atributo
	var attr_valor = 1
	match pericia.atributo_base:
		"forca": attr_valor = combatente.atributo_forca
		"inteligencia": attr_valor = combatente.atributo_inteligencia
		"agilidade": attr_valor = combatente.atributo_agilidade
		"vontade": attr_valor = combatente.atributo_vontade
		"vitalidade": attr_valor = combatente.atributo_vitalidade
	
	# Obter nível de treino (0 se não tem)
	var treino = combatente.pericias.get(nome_pericia, 0)
	
	# Rolar D6
	var dado = randi_range(1, 6)
	var resultado = dado + attr_valor + treino
	
	# Dificuldade (padrão = 0, mais alto = mais difícil)
	var dif_final = pericia.dificuldade_padrao + dificuldade
	var sucesso = resultado > dif_final
	
	# Categorizar resultado
	var categoria = "Regular"
	if resultado == 6:
		categoria = "Crítico"
	elif resultado == 1:
		categoria = "Falha"
	
	return {
		"sucesso": sucesso,
		"dado": dado,
		"atributo": attr_valor,
		"treino": treino,
		"resultado": resultado,
		"dificuldade": dif_final,
		"categoria": categoria,
		"pericia": nome_pericia,
		"personagem": combatente.nome
	}

## Retorna todas as perícias disponíveis
func get_todas_pericias() -> Array:
	var lista = []
	for nome in pericias:
		lista.append(pericias[nome])
	return lista
