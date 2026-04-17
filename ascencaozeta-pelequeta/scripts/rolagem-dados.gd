extends Node

const ZONA_ACERTO_EXTREMO = 20
const ZONA_ACERTO_REGULAR = 13
const REGIOES_CORPO = ["Torso", "Braço Esquerdo", "Braço Direito", "Perna Esquerda", "Perna Direita"]

func _ready():
	randomize()

	# Exemplo de teste de Conhecimento
	var resultado_conhecimento = rolar_teste_conhecimento(false)
	print("Teste de Conhecimento:", resultado_conhecimento)

	var resultado_conhecimento_especializado = rolar_teste_conhecimento(true)
	print("Teste de Conhecimento Especializado:", resultado_conhecimento_especializado)

	# Exemplo de ataque de Combate arriscando 3 regiões
	var regioes = ["Torso", "Braço Direito", "Perna Esquerda"]
	var resultado_combate = rolar_teste_combate(regioes, 3, 2, 1)
	print("Teste de Combate:", resultado_combate)

func rolar_teste_conhecimento(especializado: bool = false) -> Dictionary:
	# Rola 1D20 para um Teste de Conhecimento.
	# Em Conhecimentos Especializados, aplica +2 no total.
	var dado = randi_range(1, 20)
	var bonus_especializacao = 2 if especializado else 0
	var total = dado + bonus_especializacao
	var categoria = avaliar_resultado(total)

	return {
		"tipo": "Conhecimento",
		"especializado": especializado,
		"dado": dado,
		"bonus_especializacao": bonus_especializacao,
		"total": total,
		"categoria": categoria,
		"sucesso": categoria in ["Sucesso Regular", "Sucesso Extremo"],
		"falha": categoria in ["Falha Regular", "Falha Extrema"]
	}

func rolar_teste_combate(regioes_arriscadas: Array, protecao_alvo: int, dano_arma: int, atributo_dano: int) -> Dictionary:
	# Executa um Teste de Combate arriscando as regiões escolhidas.
	# Cada região recebe uma rolagem de 1D20. Sucesso Extremo vale 2 sucessos;
	# Sucesso Regular vale 1. Falhas geram Estresse para a região.
	var quantidade = clamp(regioes_arriscadas.size(), 1, 5)
	regioes_arriscadas = regioes_arriscadas.slice(0, quantidade)

	var resultados = []
	var sucessos_regulares = 0
	var sucessos_extremos = 0
	var falhas_regulares = 0
	var falhas_extremos = 0
	var estresse_gerado = 0

	for regiao in regioes_arriscadas:
		var dado = randi_range(1, 20)
		var categoria = avaliar_resultado(dado)
		var acertos = 0

		if categoria == "Sucesso Extremo":
			acertos = 2
			sucessos_extremos += 1
		elif categoria == "Sucesso Regular":
			acertos = 1
			sucessos_regulares += 1
		elif categoria == "Falha Extrema":
			falhas_extremos += 1
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

	var total_sucessos = sucessos_regulares + (sucessos_extremos * 2)
	var dano_aplicado = 0
	var protecao_temporaria = max(protecao_alvo - total_sucessos, 0)
	var dano_causado = false

	# Se o total de sucessos for igual ou maior que a Proteção do alvo,
	# o ataque acerta e causa dano.
	if total_sucessos >= protecao_alvo:
		dano_aplicado = dano_arma + atributo_dano
		dano_causado = true
		protecao_temporaria = 0

	return {
		"tipo": "Combate",
		"regioes_arriscadas": regioes_arriscadas,
		"resultados_por_regiao": resultados,
		"sucessos_regulares": sucessos_regulares,
		"sucessos_extremos": sucessos_extremos,
		"falhas_regulares": falhas_regulares,
		"falhas_extremos": falhas_extremos,
		"total_sucessos": total_sucessos,
		"estresse_gerado": estresse_gerado,
		"protecao_alvo": protecao_alvo,
		"protecao_temporaria": protecao_temporaria,
		"dano_aplicado": dano_aplicado,
		"dano_causado": dano_causado
	}

func avaliar_resultado(valor: int) -> String:
	# Retorna a categoria do resultado com base na Zona de Acerto.
	# Usa 20 para Sucesso Extremo e 1 para Falha Extrema.
	if valor == ZONA_ACERTO_EXTREMO:
		return "Sucesso Extremo"
	elif valor >= ZONA_ACERTO_REGULAR:
		return "Sucesso Regular"
	elif valor == 1:
		return "Falha Extrema"
	else:
		return "Falha Regular"
