## Personagens Principais do Jogo
## Cada um pode ser selecionado como personagem principal
## Os outros 2 tornam-se membros da party
## Estrutura pronta para habilidades, perícias e itens

class_name PersonagensData
extends RefCounted

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
	mob.adicionar_especializacao("Duelo")
	mob.adicionar_especializacao("Esforço")
	mob.adicionar_especializacao("Reflexos")
	
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
	]
	
	## ITENS INICIAIS
	# TODO: Adicionar itens iniciais
	mob.inventario = [
		"TACO GIGANTE",
		"VESTIMENTA PESADA",
	]
	
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
	## Distribuído por região: Torso(3), Braço D(3), Braço E(3), Perna D(3), Perna E(3)
	escolhido.estresse_por_regiao["Torso"]["limite"] = 3
	escolhido.estresse_por_regiao["Braço Direito"]["limite"] = 5 # Escolhido possui uma protese.
	escolhido.estresse_por_regiao["Braço Esquerdo"]["limite"] = 3
	escolhido.estresse_por_regiao["Perna Direita"]["limite"] = 2
	escolhido.estresse_por_regiao["Perna Esquerda"]["limite"] = 2
	
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
	escolhido.adicionar_especializacao("Esforço")
	escolhido.adicionar_especializacao("Saber")
	escolhido.adicionar_especializacao("Místico")
	escolhido.adicionar_especializacao("Mundo")
	escolhido.adicionar_especializacao("Rastro")
	escolhido.adicionar_especializacao("Emocional")
	escolhido.adicionar_especializacao("Social")
	escolhido.adicionar_especializacao("Bandidagem")
	
	## HABILIDADES
	## Habilidade Principal (todos têm desde o início):
	## - Ajudar os Necessitados: Escolha até 2 pessoas adjacentes para curar em vez do atributo de mente
	##
	## Habilidades Únicas (ganham ao completar missões/aventuras):
	## - Abrir feridas (em desenvolvimento)
	## - Bálsamo (em desenvolvimento)
	## - Última Esperança (em desenvolvimento)
	escolhido.habilidades = [
		"Ajudar os necessitados"  ## Habilidade Principal
	]
	
	## ITENS INICIAIS
	# TODO: Adicionar itens iniciais
	escolhido.inventario = [
		# "Disparo Medio",
		# "Anel de Astora",
		# "Frasco Estus",
	]
	
	return escolhido

## ============================================================================
## PERSONAGEM 3: JPdaMaldade - Quem Manda
## ============================================================================
static func criar_JP() -> CombatenteData:
	var JP = CombatenteData.new("JPdaMaldade", "jogador")
	
	## ATRIBUTOS FIXOS OBLIVIO
	JP.atributo_carne = 2        # Saúde média
	JP.atributo_forca = 0        # Força média
	JP.atributo_mente = 4        # Intelecto médio
	JP.atributo_fuga = 4        # Agilidade extrema
	JP.atributo_determinacao = 4 # Vontade elevada
	JP._calcular_atributos_mutaveis()
	
	## LIMITE DE ESTRESSE - Quem Manda: 10 + Carne
	## Distribuído por região: Torso(3), Braço D(2), Braço E(2), Perna D(2), Perna E(2)
	JP.estresse_por_regiao["Torso"]["limite"] = 3
	JP.estresse_por_regiao["Braço Direito"]["limite"] = 0 # JP não possui o Braço direito.
	JP.estresse_por_regiao["Braço Esquerdo"]["limite"] = 3
	JP.estresse_por_regiao["Perna Direita"]["limite"] = 2
	JP.estresse_por_regiao["Perna Esquerda"]["limite"] = 2
	
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
	JP.adicionar_especializacao("Saber")
	JP.adicionar_especializacao("Social")
	JP.adicionar_especializacao("Emocional")
	JP.adicionar_especializacao("Rastro")
	JP.adicionar_especializacao("Bandidagem")
	
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
	]
	
	## ITENS INICIAIS
	# TODO: Adicionar itens iniciais
	JP.inventario = [
		# "Disparo Longo",
		# "Bomba de fumaça",
		# "Fonte de luz",
	]
	
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
	match nome.to_lower():
		"Mob":
			return criar_mob()
		"Escolhido":
			return criar_escolhido()
		"JPdaMaldade":
			return criar_JP()
	
	# Padrão: retorna Guerreiro
	return criar_JP()

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

## ============================================================================
## TODO PARA PRÓXIMA SESSÃO
## ============================================================================
##
## 1. HABILIDADES:
##    - Criar HabilidadeData.gd com sistema de habilidades
##    - Adicionar habilidades específicas para cada personagem
##    - Implementar custos de PA e efeitos
##
## 2. PERÍCIAS AVANÇADAS:
##    - Completar treino em perícias adicionais
##    - Expandir conhecimentos especializados
##    - Vincular perícias a cenários de combate
##
## 3. ITENS:
##    - Criar ItemData.gd com sistema de itens
##    - Adicionar equipamentos e consumíveis
##    - Implementar bônus de itens aos atributos
##
## 4. UI PARA SELEÇÃO:
##    - Botão "Escolher Personagem Principal"
##    - Display de informações do personagem
##    - Preview de grupo (principal + party)
##
## 5. INTEGRAÇÃO COM COMBAT_MANAGER:
##    - Carregar grupo selecionado no combate
##    - Mostrar party no party_panel
##    - Permitir reviver membros com habilidades
##
## ============================================================================
