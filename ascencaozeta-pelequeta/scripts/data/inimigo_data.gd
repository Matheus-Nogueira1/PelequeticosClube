## Banco de dados de inimigos - Tipos e definições
## Cada inimigo é um template que pode ser instanciado
## Em OBLIVIO: Estresse acumula até o LIMITE, não HP

class_name InimigoData
extends RefCounted

## Template de inimigo
static func criar_carcaca() -> CombatenteData:
	"""A Carcaça - Criatura não-morta
	
	Dano: 3
	Proteção/Carne: 2
	Velocidade/Agilidade: 2
	Limite de estresse: 22 pontos em 4 regiões (sem pernas)
	"""
	var carcaca = CombatenteData.new("Carcaça", "inimigo")
	
	# Atributos OBLIVIO (Carne em vez de Vitalidade!)
	carcaca.atributo_carne = 2       # Define limite base de estresse
	carcaca.atributo_forca = 3       # Dano
	carcaca.atributo_agilidade = 2   # Velocidade
	carcaca.atributo_vontade = 2     # Resistência psicológica
	carcaca.atributo_inteligencia = 1
	
	# Combate
	carcaca.dano_arma = 3
	carcaca.defesa_base = 2
	
	# Estresse por região - limite total 22 em 4 regiões (sem pernas)
	# Limite = Carne + Papel. Carcaça tem Carne 2, então base é 2, distrib
	carcaca.estresse_por_regiao = {
		"Torso": {"atual": 0, "limite": 10},       # Centro vital - maior limite
		"Braço Direito": {"atual": 0, "limite": 4},
		"Braço Esquerdo": {"atual": 0, "limite": 4},
		"Perna Direita": {"atual": 0, "limite": 2},
		"Perna Esquerda": {"atual": 0, "limite": 2}
	}
	
	carcaca.status = ["Não-morta", "Visão Escura"]
	
	return carcaca

static func goblin() -> CombatenteData:
	"""Goblin comum - criatura básica
	
	Pequena, fraca, mas esperta
	Limite de estresse: ~12 pontos
	"""
	var goblin = CombatenteData.new("Goblin", "inimigo")
	
	goblin.atributo_carne = 1
	goblin.atributo_forca = 1
	goblin.atributo_agilidade = 2
	goblin.atributo_vontade = 1
	goblin.atributo_inteligencia = 2
	
	goblin.dano_arma = 1
	goblin.defesa_base = 1
	
	goblin.estresse_por_regiao = {
		"Torso": {"atual": 0, "limite": 5},
		"Braço Direito": {"atual": 0, "limite": 2},
		"Braço Esquerdo": {"atual": 0, "limite": 2},
		"Perna Direita": {"atual": 0, "limite": 2},
		"Perna Esquerda": {"atual": 0, "limite": 1}
	}
	
	return goblin

static func orc_guerreiro() -> CombatenteData:
	"""Orc Guerreiro - inimigo forte
	
	Forte, resistente
	Limite de estresse: ~18 pontos
	"""
	var orc = CombatenteData.new("Orc Guerreiro", "inimigo")
	
	orc.atributo_carne = 2
	orc.atributo_forca = 3
	orc.atributo_agilidade = 1
	orc.atributo_vontade = 2
	orc.atributo_inteligencia = 1
	
	orc.dano_arma = 3
	orc.defesa_base = 2
	
	orc.estresse_por_regiao = {
		"Torso": {"atual": 0, "limite": 7},
		"Braço Direito": {"atual": 0, "limite": 3},
		"Braço Esquerdo": {"atual": 0, "limite": 3},
		"Perna Direita": {"atual": 0, "limite": 3},
		"Perna Esquerda": {"atual": 0, "limite": 2}
	}
	
	return orc

## Retorna lista de inimigos por dificuldade
static func inimigos_por_dificuldade(dificuldade: String) -> Array[CombatenteData]:
	var inimigos: Array[CombatenteData] = []
	
	match dificuldade:
		"facil":
			inimigos.append(goblin())
		"normal":
			inimigos.append(orc_guerreiro())
		"dificil":
			inimigos.append(criar_carcaca())
			inimigos.append(orc_guerreiro())
		"muito_dificil":
			inimigos.append(criar_carcaca())
			inimigos.append(orc_guerreiro())
			inimigos.append(orc_guerreiro())
	
	return inimigos

## Retorna um inimigo aleatório de uma dificuldade
static func inimigo_aleatorio(dificuldade: String) -> CombatenteData:
	var lista = inimigos_por_dificuldade(dificuldade)
	if lista.is_empty():
		return goblin()
	return lista[randi() % lista.size()]
