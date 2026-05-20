## Sistema de Próteses - OBLIVIO 2.2
## Próteses permitem manter regiões após dano severo
## Aparecem como customizável, representam qualquer região EXCETO Torso

class_name ProteseData
extends RefCounted

class Protese:
	var nome: String                              ## Nome/aparência da prótese
	var regiao_representada: String               ## Qual região ela substitui
	var estresse_atual: int = 0                   ## 0-5 pontos
	var estresse_maximo: int = 5
	var falhas_extremas_sofridas: int = 0        ## Contador de falhas extremas
	var destruida: bool = false
	var pode_arriscar: bool = true                ## Pode ser arriscada em combate?
	
	func _init(p_nome: String, p_regiao: String):
		nome = p_nome
		regiao_representada = p_regiao
	
	func sofrer_estresse(quantidade: int) -> int:
		"""Aplica estresse à prótese, retorna excedente"""
		estresse_atual += quantidade
		if estresse_atual > estresse_maximo:
			var excedente = estresse_atual - estresse_maximo
			estresse_atual = estresse_maximo
			return excedente
		return 0
	
	func recuperar_estresse(quantidade: int) -> void:
		"""Recupera estresse da prótese"""
		estresse_atual = max(0, estresse_atual - quantidade)
	
	func sofrer_falha_extrema() -> void:
		"""Registra uma falha extrema sofrida"""
		falhas_extremas_sofridas += 1

## ===== FUNÇÕES UTILITÁRIAS =====

## Cria uma prótese padrão
static func criar_protese(nome: String, regiao: String) -> Protese:
	return Protese.new(nome, regiao)

## Cria prótese do Escolhido (Braço Direito)
static func criar_protese_escolhido() -> Protese:
	var protese = Protese.new("Prótese Mecânica", "Braço Direito")
	protese.estresse_atual = 0
	return protese

## Verifica se prótese deve ser destruída (Falhas Extremas > Carne/2)
static func verificar_destruicao(protese: Protese, carne_combatente: int) -> bool:
	"""
	Prótese é destruída se sofreu Falhas Extremas > Carne/2
	"""
	var limite_falhas = carne_combatente / 2  # Integer division
	return protese.falhas_extremas_sofridas > limite_falhas

## Destrói a prótese e redistribui limite de estresse
static func destruir_protese(combatente: CombatenteData, protese: Protese) -> Dictionary:
	"""
	Destrói a prótese e redistribui o limite máximo entre as demais regiões
	"""
	protese.destruida = true
	protese.pode_arriscar = false
	
	var regiao_perdida = protese.regiao_representada
	var limite_a_redistribuir = protese.estresse_maximo
	
	# Remove a prótese do combatente (ele perde a região)
	combatente.regioes_perdidas.append(regiao_perdida)
	
	# Redistribui o limite entre as demais regiões
	var regioes_disponiveis = combatente.estresse_por_regiao.keys()
	regioes_disponiveis.erase(regiao_perdida)  # Remove a região perdida
	
	if regioes_disponiveis.size() > 0:
		var aumento_por_regiao = limite_a_redistribuir / regioes_disponiveis.size()
		for regiao in regioes_disponiveis:
			if combatente.estresse_por_regiao.has(regiao):
				combatente.estresse_por_regiao[regiao]["limite"] += aumento_por_regiao
	
	return {
		"sucesso": true,
		"regiao_perdida": regiao_perdida,
		"limite_redistribuido": limite_a_redistribuir,
		"mensagem": "Prótese de %s foi destruída! Limite de estresse redistribuído." % regiao_perdida
	}

## Recupera estresse de prótese (Kit de Reparos ou Ajudar os Necessitados)
static func recuperar_protese(protese: Protese, quantidade: int) -> Dictionary:
	"""
	Recupera estresse de uma prótese
	NÃO pode ser recuperada com Coragem
	"""
	if protese.destruida:
		return {
			"sucesso": false,
			"mensagem": "Prótese %s foi destruída e não pode ser reparada." % protese.nome
		}
	
	var estresse_antes = protese.estresse_atual
	protese.recuperar_estresse(quantidade)
	
	return {
		"sucesso": true,
		"regiao": protese.regiao_representada,
		"estresse_antes": estresse_antes,
		"estresse_depois": protese.estresse_atual,
		"recuperado": estresse_antes - protese.estresse_atual,
		"mensagem": "Prótese de %s reparada! Recuperou %d pontos." % [
			protese.regiao_representada,
			estresse_antes - protese.estresse_atual
		]
	}

## Verifica se região pode ser arriscada em combate
static func pode_arriscar_regiao(combatente: CombatenteData, regiao: String) -> bool:
	"""
	Retorna false se:
	- Região foi perdida (sem prótese)
	- Prótese foi destruída
	- Outra razão (TODO: revisar)
	"""
	# Verifica se é uma região perdida
	if regiao in combatente.regioes_perdidas:
		return false
	
	# Se tem prótese, verifica se não foi destruída
	if combatente.proteses.has(regiao):
		var protese = combatente.proteses[regiao]
		return not protese.destruida
	
	return true

## Retorna todas as próteses do combatente
static func obter_proteses(combatente: CombatenteData) -> Array[ProteseData.Protese]:
	var proteses: Array[ProteseData.Protese] = []
	for regiao in combatente.proteses:
		proteses.append(combatente.proteses[regiao])
	return proteses

## Conta falhas extremas totais de todas as próteses
static func contar_falhas_extremas_proteses(combatente: CombatenteData) -> int:
	var total = 0
	for regiao in combatente.proteses:
		total += combatente.proteses[regiao].falhas_extremas_sofridas
	return total
