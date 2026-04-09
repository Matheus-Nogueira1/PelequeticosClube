extends CharacterBody2D

@onready var dado_sprite = $AnimatedSprite2D

const ZONA_ACERTO_EXTREMO = 6
const ZONA_ACERTO_REGULAR = 4
const REGIOES_CORPO = ["Torso", "Braço Esquerdo", "Braço Direito", "Perna Esquerda", "Perna Direita"]
func _ready():
	randomize()
	var resultado = rolar_teste_conhecimento_d6(false)
	rodar_e_mostrar_face(resultado.dado)
	print(resultado)
func rodar_e_mostrar_face(lado: int) -> void:
	dado_sprite.animation = "rolar"
	dado_sprite.play()
	await get_tree().create_timer(0.8).timeout
	dado_sprite.stop()
	dado_sprite.animation = "default"  # ou nome da animação de face
	dado_sprite.frame = lado - 1
	# Exemplo de teste de Conhecimento com D6
	var resultado_conhecimento = rolar_teste_conhecimento_d6(false)
	#print("Teste de Conhecimento D6:", resultado_conhecimento)

	var resultado_conhecimento_especializado = rolar_teste_conhecimento_d6(true)
	print("Teste de Conhecimento Especializado D6:", resultado_conhecimento_especializado)

	# Exemplo de ataque de Combate com D6 arriscando 3 regiões
	var regioes = ["Torso", "Braço Direito", "Perna Esquerda"]
	var resultado_combate = rolar_teste_combate_d6(regioes, 3, 2, 1)
	print("Teste de Combate D6:", resultado_combate)

func rolar_teste_conhecimento_d6(especializado: bool = false) -> Dictionary:
	# Rola 1D6 para um Teste de Conhecimento.
	# Em Conhecimentos Especializados, aplica +2 no total.
	var dado = randi_range(1, 6)
	var bonus_especializacao = 2 if especializado else 0
	var total = dado + bonus_especializacao
	var categoria = avaliar_resultado_d6(total)

	return {
		"tipo": "Conhecimento D6",
		"especializado": especializado,
		"dado": dado,
		"bonus_especializacao": bonus_especializacao,
		"total": total,
		"categoria": categoria,
		"sucesso": categoria in ["Sucesso Regular", "Sucesso Extremo"],
		"falha": categoria in ["Falha Regular", "Falha Crítica"]
	}

func rolar_teste_combate_d6(regioes_arriscadas: Array, protecao_alvo: int, dano_arma: int, atributo_dano: int) -> Dictionary:
	# Executa um Teste de Combate arriscando as regiões escolhidas com D6.
	# Cada região recebe uma rolagem de 1D6. Sucesso Extremo vale 2 sucessos;
	# Sucesso Regular vale 1. Falhas geram Estresse para a região.
	var quantidade = clamp(regioes_arriscadas.size(), 1, 5)
	regioes_arriscadas = regioes_arriscadas.slice(0, quantidade)

	var resultados = []
	var sucessos_regulares = 0
	var sucessos_extremos = 0
	var falhas_regulares = 0
	var falhas_criticas = 0
	var estresse_gerado = 0

	for regiao in regioes_arriscadas:
		var dado = randi_range(1, 6)
		var categoria = avaliar_resultado_d6(dado)
		var acertos = 0

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
	# Retorna a categoria do resultado com base na Zona de Acerto D6.
	# 6 = Sucesso Extremo, 4-5 = Sucesso Regular, 2-3 = Falha Regular, 1 = Falha Crítica.
	if valor == ZONA_ACERTO_EXTREMO:
		return "Sucesso Extremo"
	elif valor >= ZONA_ACERTO_REGULAR:
		return "Sucesso Regular"
	elif valor == 1:
		return "Falha Crítica"
	else:
		return "Falha Regular"
