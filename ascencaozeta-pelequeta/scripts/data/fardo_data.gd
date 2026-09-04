## Sistema de Fardos - Maldições aplicadas quando Estresse de Torso atinge limite
## Baseado em Dark Souls: cada morte deixa uma marca permanente
## Jogador volta à vida mas com penalidades crescentes

class_name FardoData
extends RefCounted

## Tipos de Fardos
enum TipoFardo {
	GUILHOTINA = 1,         # Perde membro
	DETERIORACAO = 2,       # Atributo fixo -1D4
	COVARDIA = 3,          # -2x Coragem
	MAL_DAS_PERNAS = 4,    # -1 limite Estresse
	FRAGILIDADE = 5,       # +1D6 dano recebido
	ATAQUE_CARDIACO = 6    # Teste Esforço ou morre
}

## Classe que representa um Fardo aplicado a um personagem
class Fardo:
	var tipo: TipoFardo
	var nome: String
	var descricao: String
	var tempo_aplicacao: int  # Numero do desmaio quando foi aplicado
	var dados_fardo: Dictionary  # Dados específicos (ex: qual membro foi perdido)
	
	func _init(p_tipo: TipoFardo, p_tempo: int):
		tipo = p_tipo
		tempo_aplicacao = p_tempo
		dados_fardo = {}
		
		match tipo:
			TipoFardo.GUILHOTINA:
				nome = "Guilhotina"
				descricao = "Perdeu um membro"
			TipoFardo.DETERIORACAO:
				nome = "Deterioração"
				descricao = "Atributo fixo permanentemente reduzido"
			TipoFardo.COVARDIA:
				nome = "Covardia"
				descricao = "Perde 2x Coragem em testes"
			TipoFardo.MAL_DAS_PERNAS:
				nome = "Mal das Pernas"
				descricao = "Limite máximo de Estresse reduzido"
			TipoFardo.FRAGILIDADE:
				nome = "Fragilidade"
				descricao = "Ataques causam 1D6 dano adicional"
			TipoFardo.ATAQUE_CARDIACO:
				nome = "Ataque Cardíaco"
				descricao = "Teste de Esforço ou morre"

## Sorteio de Fardo aleatório (1D6)
static func sortear_fardo(numero_desmaio: int) -> Fardo:
	var dado = randi_range(1, 6)
	return Fardo.new(TipoFardo.get(TipoFardo.keys()[dado - 1]), numero_desmaio)

## Guilhotina: Determina qual membro é perdido
static func aplicar_guilhotina(combatente: CombatenteData) -> Dictionary:
	"""
	Perde um membro aleatório disponível
	Retorna qual foi perdido e seus efeitos
	"""
	var regioes_disponiveis = ["Braço Esquerdo", "Braço Direito", "Perna Direita", "Perna Esquerda"]
	var regioes_perdidas = combatente.regioes_perdidas
	
	# Remove regiões já perdidas
	regioes_disponiveis = regioes_disponiveis.filter(func(r): return not r in regioes_perdidas)
	
	if regioes_disponiveis.is_empty():
		return {"sucesso": false, "mensagem": "Nenhum membro disponível para perder!"}
	
	# Sorteia qual membro perder
	var regiao_perdida = regioes_disponiveis[randi() % regioes_disponiveis.size()]
	combatente.regioes_perdidas.append(regiao_perdida)
	
	# Reduz limite de estresse dessa região para 0
	if combatente.estresse_por_regiao.has(regiao_perdida):
		combatente.estresse_por_regiao[regiao_perdida]["limite"] = 0
	
	return {
		"sucesso": true,
		"membro_perdido": regiao_perdida,
		"mensagem": "%s perdeu o(a) %s!" % [combatente.nome, regiao_perdida]
	}

## Deterioração: Reduz atributo fixo
static func aplicar_deterioracao(combatente: CombatenteData) -> Dictionary:
	"""
	Escolhe atributo e reduz em 1D4 (mínimo 0, máximo 9)
	"""
	var dado_reducao = randi_range(1, 4)
	var dado_atributo = randi_range(1, 6)
	
	# Se rolou 6, rola novamente
	while dado_atributo == 6:
		dado_atributo = randi_range(1, 6)
	
	var atributo_afetado = ""
	var valor_atual = 0
	
	match dado_atributo:
		1:
			atributo_afetado = "Carne"
			valor_atual = combatente.atributo_carne
			combatente.atributo_carne = max(0, min(9, valor_atual - dado_reducao))
		2:
			atributo_afetado = "Força"
			valor_atual = combatente.atributo_forca
			combatente.atributo_forca = max(0, min(9, valor_atual - dado_reducao))
		3:
			atributo_afetado = "Fuga"
			valor_atual = combatente.atributo_fuga
			combatente.atributo_fuga = max(0, min(9, valor_atual - dado_reducao))
		4:
			atributo_afetado = "Mente"
			valor_atual = combatente.atributo_mente
			combatente.atributo_mente = max(0, min(9, valor_atual - dado_reducao))
		5:
			atributo_afetado = "Determinação"
			valor_atual = combatente.atributo_determinacao
			combatente.atributo_determinacao = max(0, min(9, valor_atual - dado_reducao))
	
	combatente._calcular_atributos_mutaveis()
	
	return {
		"sucesso": true,
		"atributo": atributo_afetado,
		"reducao": dado_reducao,
		"novo_valor": valor_atual - dado_reducao,
		"mensagem": "%s perdeu %d pontos de %s!" % [combatente.nome, dado_reducao, atributo_afetado]
	}

## Mal das Pernas: Reduz limite máximo de Estresse
static func aplicar_mal_das_pernas(combatente: CombatenteData) -> Dictionary:
	"""
	Reduz limite máximo de estresse em 1 ponto
	Afeta todos os danos futuros
	"""
	combatente.limite_estresse_maximo_reducao += 1
	
	return {
		"sucesso": true,
		"reducao": 1,
		"mensagem": "%s tem sua resistência reduzida!" % combatente.nome
	}

## Fragilidade: Aumenta dano recebido
static func aplicar_fragilidade(combatente: CombatenteData) -> Dictionary:
	"""
	Marca combatente como frágil
	Próximos ataques bem-sucedidos causam +1D6 dano adicional
	"""
	combatente.tem_fragilidade = true
	
	return {
		"sucesso": true,
		"mensagem": "%s ficou frágil! Ataques causam 1D6 dano adicional." % combatente.nome
	}

## Covardia: Afeta testes de Coragem
static func aplicar_covardia(combatente: CombatenteData) -> Dictionary:
	"""
	Marca combatente como covarde
	Perde 2x Coragem em testes e Emocional com dificuldade +1
	"""
	combatente.tem_covardia = true
	
	return {
		"sucesso": true,
		"mensagem": "%s está paralisado pelo medo!" % combatente.nome
	}

## Ataque Cardíaco: Risco de morte instantânea
static func aplicar_ataque_cardiaco(combatente: CombatenteData) -> Dictionary:
	"""
	Marca combatente como tendo fardo de Ataque Cardíaco
	Próxima vez que atingir limite de Torso: faz teste de Esforço
	Se falhar: morre
	"""
	combatente.tem_ataque_cardiaco = true
	
	return {
		"sucesso": true,
		"mensagem": "%s sente o coração disparar perigosamente!" % combatente.nome
	}

## Teste para Ataque Cardíaco
static func testar_ataque_cardiaco(combatente: CombatenteData) -> Dictionary:
	"""
	Teste de Esforço contra Ataque Cardíaco
	Falha = morte instantânea
	"""
	var pericia_data = PericiaData.new()
	var resultado = pericia_data.testar_conhecimento(combatente, "Esforço", 0)
	
	var sobrevive = resultado["sucesso"]
	
	return {
		"sobrevive": sobrevive,
		"resultado_teste": resultado,
		"mensagem": "Teste de Esforço contra Ataque Cardíaco!" if not sobrevive else "Coração continua batendo..."
	}

## Aplica um Fardo específico ao combatente
static func aplicar_fardo(combatente: CombatenteData, fardo: Fardo) -> Dictionary:
	"""
	Aplica o fardo e retorna resultado com mensagens
	"""
	combatente.fardos.append(fardo)
	
	match fardo.tipo:
		TipoFardo.GUILHOTINA:
			return aplicar_guilhotina(combatente)
		TipoFardo.DETERIORACAO:
			return aplicar_deterioracao(combatente)
		TipoFardo.COVARDIA:
			return aplicar_covardia(combatente)
		TipoFardo.MAL_DAS_PERNAS:
			return aplicar_mal_das_pernas(combatente)
		TipoFardo.FRAGILIDADE:
			return aplicar_fragilidade(combatente)
		TipoFardo.ATAQUE_CARDIACO:
			return aplicar_ataque_cardiaco(combatente)
	
	return {"sucesso": false, "mensagem": "Fardo desconhecido"}

## Retorna descrição dos Fardos do combatente
static func listar_fardos(combatente: CombatenteData) -> Array[String]:
	"""
	Retorna lista de descrições dos fardos atuais
	"""
	var lista: Array[String] = []
	for fardo in combatente.fardos:
		lista.append("%s (desmaio #%d): %s" % [fardo.nome, fardo.tempo_aplicacao, fardo.descricao])
	return lista
