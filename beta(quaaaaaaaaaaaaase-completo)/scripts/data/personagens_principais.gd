## Personagens Principais do Jogo
## Cada um pode ser selecionado como personagem principal
## Os outros 2 tornam-se membros da party
## Estrutura pronta para habilidades, perícias e itens

class_name PersonagensData
extends RefCounted


## ============================================================================
## DADOS DE APRESENTAÇÃO DOS PERSONAGENS
## Utilizados pela tela de seleção de personagem.
## ============================================================================

static func obter_dados_apresentacao(nome: String) -> Dictionary:
	match nome.to_lower():
		"escolhido":
			return {
				"nome": "Escolhido",
				"descricao": "Cleptomaníaco, Imperdoável, Inesquecível.\n
				Uma existência sem forma, movida por uma vontade que jamais lhe pertenceu.
				\nNascido de uma origem usurpada, percorre caminhos que não escolheu, perseguindo destinos que lhe serão negados. Foi escolhido para reunir os anseios e pecados dos maculados, mas tornou-se uma ruína imperdoável para aqueles que o moldaram. 
				Talvez sua busca por propósito seja apenas outra prisão, há vidas que não nascem para encontrar sentido, mas para descobrir, tarde demais, que sempre caminharam em direção à própria queda."
			}

		"jp", "jpdamaldade", "jp da maldade", "JP", "JP da maldade":
			return {
				"nome": "JP da Maldade",
				"descricao": "Sortudo, Atirador e Vingativo\nUm atirador de pontaria certeira, que encontra na chuva e no frio o cenário perfeito para caçar suas presas.
				Paciente e estratégico, aguarda o momento certo para atacar, guiado pela sorte e pela vingança.
				Por trás de sua precisão, esconde-se uma mente atormentada por dúvidas e feridas do passado.
				Em busca de respostas, descobrirá que nem mesmo suas flechas podem atingir aquilo que precisa enfrentar: a si mesmo.
				\nPois, às vezes, a única cura é a própria aceitação."
			}

		"mob":
			return {
				"nome": "Mob",
				"descricao": "Prisioneiro, Corajoso e Bondoso\nUm homem cuja liberdade lhe foi roubada, condenado a uma vida de cárcere e tormento em uma fazenda. Contudo, um dia, o abismo clamou por seu nome, e sua sentença tornou-se um chamado. Uma nova motivação percorre suas veias, bombeando em seu coração o desejo de proteger aqueles que um dia o acolheram. Teve sua liberdade tomada à força, mas agora vive cada dia ao máximo, aproveitando cada fragmento da liberdade que lhe foi concedida. 
				\nOutrora acorrentado pelo próprio destino, hoje nada poderá detê-lo, pois, acima de tudo, carrega consigo um propósito inabalável proteger aqueles que agora chama de família."
			}

	return {
		"nome": "Personagem desconhecido",
		"descricao": "Nenhuma descrição disponível."
	}


## ============================================================================
## PERSONAGEM 1: Mob - Quem Protege
## ============================================================================
static func criar_mob() -> CombatenteData:
	var mob = CombatenteData.new("Mob", "jogador")
	
	## ATRIBUTOS FIXOS OBLIVIO
	mob.atributo_carne = 4        # Saúde e resistência
	mob.atributo_forca = 2        # Força bruta
	mob.atributo_mente = 0        # Intelecto
	mob.atributo_fuga = 4        # Agilidade
	mob.atributo_determinacao = 0 # Vontade
	mob._calcular_atributos_mutaveis()
	
	## LIMITE DE ESTRESSE - Quem Protege: 20 + Carne
	## Distribuído por região: Torso(10), Braço D(4), Braço E(4), Perna D(3), Perna E(3)
	mob.estresse_por_regiao["Torso"]["limite"] = 10
	mob.estresse_por_regiao["Braço Direito"]["limite"] = 4
	mob.estresse_por_regiao["Braço Esquerdo"]["limite"] = 4
	mob.estresse_por_regiao["Perna Direita"]["limite"] = 3
	mob.estresse_por_regiao["Perna Esquerda"]["limite"] = 3
	
	## CONHECIMENTOS (Perícias) - TREINO INICIAL
	# Guerreiro especializado em combate
	mob.conhecimentos_treino["Duelo"] = 2
	mob.conhecimentos_treino["Esforço"] = 2
	mob.conhecimentos_treino["Reflexos"] = 1
	# TODO: Adicionar mais perícias conforme necessário
	
	## CONHECIMENTOS ESPECIALIZADOS
	## Quem Protege escolhe 3 do Papel + Mente/2 adicionais (0/2 = 0 total)
	mob.adicionar_especializacao_inicial(
	"Duelo",
	CombatenteData.ORIGEM_PAPEL
	)
	mob.adicionar_especializacao_inicial(
		"Esforço",
		CombatenteData.ORIGEM_PAPEL
	)
	mob.adicionar_especializacao_inicial(
		"Reflexos",
		CombatenteData.ORIGEM_PAPEL
	)
	
	## HABILIDADES
	## Habilidade Principal (todos têm desde o início):
	## - Escudo Humano: Bloquear um ataque direcionado a outro membro
	##
	## Habilidades Únicas (ganham ao completar missões/aventuras):
	## - Armadura de espinhos (em desenvolvimento)
	## - Peso pesado (em desenvolvimento)
	## - Repartir dor (em desenvolvimento)
	mob.habilidades = [
		"Escudo humano"  ## Habilidade Principal
	] as Array[String]
	
	## ITENS INICIAIS
	# TODO: Adicionar itens iniciais
	mob.inventario = [
		"TACO GIGANTE",
		"VESTIMENTA PESADA",
	] as Array[String]
	mob.arma_equipada = "TacoGigante"
	
	return mob

## ============================================================================
## PERSONAGEM 2: Escolhido - Quem Cuida
## ============================================================================
static func criar_escolhido() -> CombatenteData:
	var escolhido = CombatenteData.new("Escolhido", "jogador")
	
	## ATRIBUTOS FIXOS OBLIVIO
	escolhido.atributo_carne = 0         # Saúde fraca
	escolhido.atributo_forca = 0         # Fraco fisicamente
	escolhido.atributo_mente = 10         # Intelecto elevado
	escolhido.atributo_fuga = 1          # Ágil
	escolhido.atributo_determinacao = 0  # Vontade média
	escolhido._calcular_atributos_mutaveis()
	
	## LIMITE DE ESTRESSE - Quem Cuida: 15 + Carne
	## Distribuído por região: Torso(3), Braço D(5-prótese), Braço E(3), Perna D(3), Perna E(3)
	escolhido.estresse_por_regiao["Torso"]["limite"] = 3
	escolhido.estresse_por_regiao["Braço Direito"]["limite"] = 5 # Braço direito é prótese, tem limite aumentado
	escolhido.estresse_por_regiao["Braço Esquerdo"]["limite"] = 3
	escolhido.estresse_por_regiao["Perna Direita"]["limite"] = 3
	escolhido.estresse_por_regiao["Perna Esquerda"]["limite"] = 3
	
	## PRÓTESES - Escolhido possui prótese no Braço Direito
	var protese_braco = ProteseData.criar_protese("Prótese Mecânica", "Braço Direito")
	escolhido.adicionar_protese(protese_braco)
	## Prótese tem limite de 5 pontos estresse
	
	## CONHECIMENTOS (Perícias) - TREINO INICIAL
	# Mago especializado em magia e conhecimento
	escolhido.conhecimentos_treino["Rastro"] = 2
	escolhido.conhecimentos_treino["Místico"] = 2
	escolhido.conhecimentos_treino["Esforço"] = 2
	# TODO: Adicionar mais perícias conforme necessário
	
	## CONHECIMENTOS ESPECIALIZADOS
	## Quem Cuida escolhe 3 do Papel + Mente/2 adicionais (10/2 = 5 total)
	## Do Papel: Esforço, Saber, Místico
	## Adicionais (liberdade do jogador): Mundo, Rastro, Emocional, Social, Bandidagem
	## Especializações do Papel: Quem Cuida
	escolhido.adicionar_especializacao_inicial(
		"Esforço",
		CombatenteData.ORIGEM_PAPEL
	)
	escolhido.adicionar_especializacao_inicial(
		"Saber",
		CombatenteData.ORIGEM_PAPEL
	)
	escolhido.adicionar_especializacao_inicial(
		"Místico",
		CombatenteData.ORIGEM_PAPEL
	)

	## Especializações adicionais pela Mente 10: cinco
	escolhido.adicionar_especializacao_inicial(
		"Mundo",
		CombatenteData.ORIGEM_MENTE
	)
	escolhido.adicionar_especializacao_inicial(
		"Rastro",
		CombatenteData.ORIGEM_MENTE
	)
	escolhido.adicionar_especializacao_inicial(
		"Emocional",
		CombatenteData.ORIGEM_MENTE
	)
	escolhido.adicionar_especializacao_inicial(
		"Social",
		CombatenteData.ORIGEM_MENTE
	)
	escolhido.adicionar_especializacao_inicial(
		"Bandidagem",
		CombatenteData.ORIGEM_MENTE
	)

	## Exceção explícita: Místico é o treinamento principal do Escolhido.
	escolhido.conhecimentos_treino_permitido.append("Místico")

	## Treinamentos iniciais mantidos
	escolhido.conhecimentos_treino["Místico"] = 2
	escolhido.conhecimentos_treino["Rastro"] = 2
	
	## HABILIDADES
	## Habilidade Principal (todos têm desde o início):
	## - Ajudar os Necessitados: Escolha até 2 pessoas adjacentes para curar em vez do atributo de mente
	##
	## Habilidade Especial: Ir Além (Sobrecarga)
	## - Permite arriscar múltiplas vezes uma única região em Testes de Combate
	##
	## Habilidades Únicas (ganham ao completar missões/aventuras):
	## - Abrir feridas (em desenvolvimento)
	## - Bálsamo (em desenvolvimento)
	## - Última Esperança (em desenvolvimento)
	escolhido.habilidades = [
		"Ajudar os necessitados"  ## Habilidade Principal
	] as Array[String]
	
	## ITENS INICIAIS
	# TODO: Adicionar itens iniciais
	escolhido.inventario = [
		"Frasco Estus",
		"Frasco Estus",
	] as Array[String]
	escolhido.arma_equipada = "BolaDeFogo"
	
	return escolhido

## ============================================================================
## PERSONAGEM 3: JPdaMaldade - Quem Manda
## ============================================================================
static func criar_JP() -> CombatenteData:
	var JP = CombatenteData.new("JPdaMaldade", "jogador")
	var sobrecarga_ativa: bool = false
	
	## ATRIBUTOS FIXOS OBLIVIO
	JP.atributo_carne = 2        # Saúde média
	JP.atributo_forca = 0        # Força média
	JP.atributo_mente = 4        # Intelecto médio
	JP.atributo_fuga = 4        # Agilidade extrema
	JP.atributo_determinacao = 4 # Vontade elevada
	JP._calcular_atributos_mutaveis()
	
	## LIMITE DE ESTRESSE - Quem Manda: 10 + Carne
	## Distribuído por região: Torso(3), Braço D(0-SEM MEMBRO), Braço E(3), Perna D(2), Perna E(2)
	JP.estresse_por_regiao["Torso"]["limite"] = 3
	JP.estresse_por_regiao["Braço Direito"]["limite"] = 0 # JP não possui o Braço direito.
	JP.estresse_por_regiao["Braço Esquerdo"]["limite"] = 3
	JP.estresse_por_regiao["Perna Direita"]["limite"] = 2
	JP.estresse_por_regiao["Perna Esquerda"]["limite"] = 2
	
	## REGIÕES PERDIDAS - JP não tem o Braço Direito (perdido, não pode ser recuperado)
	JP.regioes_perdidas.append("Braço Direito")
	
	## CONHECIMENTOS (Perícias) - TREINO INICIAL
	# JP especializado em furtividade e esperteza
	JP.conhecimentos_treino["Bandidagem"] = 2
	JP.conhecimentos_treino["Reflexos"] = 2
	JP.conhecimentos_treino["Rastro"] = 1
	# TODO: Adicionar mais perícias conforme necessário
	
	## CONHECIMENTOS ESPECIALIZADOS
	## Quem Manda escolhe 3 do Papel + Mente/2 adicionais (4/2 = 2 total)
	## Do Papel: Saber, Social, Emocional
	## Adicionais (liberdade do jogador): Rastro, Bandidagem
	## Especializações do Papel: Quem Manda
	JP.adicionar_especializacao_inicial(
		"Saber",
		CombatenteData.ORIGEM_PAPEL
	)
	JP.adicionar_especializacao_inicial(
		"Social",
		CombatenteData.ORIGEM_PAPEL
	)
	JP.adicionar_especializacao_inicial(
		"Emocional",
		CombatenteData.ORIGEM_PAPEL
	)

	## Especializações adicionais pela Mente 4: duas
	JP.adicionar_especializacao_inicial(
		"Rastro",
		CombatenteData.ORIGEM_MENTE
	)
	JP.adicionar_especializacao_inicial(
		"Bandidagem",
		CombatenteData.ORIGEM_MENTE
	)

	## Treinamentos iniciais mantidos
	JP.conhecimentos_treino["Bandidagem"] = 2
	JP.conhecimentos_treino["Rastro"] = 1
	
	## HABILIDADES
	## Habilidade Principal (todos têm desde o início):
	## - Dar uma Mãozinha: Use sua inteligência para algo extra
	##
	## Habilidades Únicas (ganham ao completar missões/aventuras):
	## - Animar os ânimos (em desenvolvimento)
	## - Cópia barata (em desenvolvimento) - Pode copiar qualquer habilidade de outro Papel
	## - Instrução Decisiva (em desenvolvimento)
	JP.habilidades = [
		"Dar uma mãozinha"  ## Habilidade Principal
	] as Array[String]
	## Ativa a habilidade Sobrecarga (Ir Além) - JP pode arriscar múltiplas vezes a mesma região
	JP.habilidade_sobrecarga_ativa = true
	
	## ITENS INICIAIS
	# TODO: Adicionar itens iniciais
	JP.inventario = [
		# "Disparo Longo",
		# "Bomba de fumaça",
		# "Fonte de luz",
	] as Array[String]
	JP.arma_equipada = "Besta"
	return JP

## ============================================================================
## FUNÇÕES UTILITÁRIAS
## ============================================================================

## Retorna lista de todos os personagens principais
static func obter_todos_personagens() -> Array[CombatenteData]:
	return [
		criar_mob(),
		criar_escolhido(),
		criar_JP()
	]

## Retorna um personagem específico pelo nome
static func obter_personagem(nome: String) -> CombatenteData:
	match nome.strip_edges().to_lower():
		"mob":
			return criar_mob()
		"escolhido":
			return criar_escolhido()
		"jp", "jp da maldade", "jpdamaldade":
			return criar_JP()

	return null

## Cria grupo completo com um personagem como principal
static func criar_grupo_completo(personagem_principal: String) -> Array[CombatenteData]:
	"""
	Cria um grupo com o personagem selecionado como principal
	e os outros como membros da party
	"""
	var grupo: Array[CombatenteData] = []
	
	# Adiciona como primeiro (principal)
	grupo.append(obter_personagem(personagem_principal))
	
	# Adiciona os outros como party
	for personagem in obter_todos_personagens():
		if personagem.nome != personagem_principal:
			grupo.append(personagem)
	
	return grupo
