extends RefCounted
class_name InimigoIA

# ============================================================
# IA DOS INIMIGOS
# A IA decide. O CombatManager executa.
# ============================================================

const CUSTO_PA_ATAQUE: int = 2
const CUSTO_PA_CONHECIMENTO: int = 1

const ESTRESSE_FALHA_CRITICA: int = 2

const PERFIL_PADRAO: String = "agressivo"

const PERFIS: Dictionary = {
	"agressivo": {
		"max_dados": 5,
		"meta_probabilidade": 0.75,
		"arrisca_torso": true,
		"peso_vulnerabilidade": 1.0,
		"peso_quase_derrotado": 1.0,
		"peso_protecao": 0.5,
		"peso_ameaca": 0.0,
		"peso_ataque": 1.5,
		"peso_duelo": 0.25,
		"peso_rastro": 0.1
	},
	"defensivo": {
		"max_dados": 3,
		"meta_probabilidade": 0.5,
		"arrisca_torso": false,
		"peso_vulnerabilidade": 0.5,
		"peso_quase_derrotado": 0.5,
		"peso_protecao": 1.5,
		"peso_ameaca": 0.0,
		"peso_ataque": 1.0,
		"peso_duelo": 0.8,
		"peso_rastro": 0.4
	},
	"estrategico": {
		"max_dados": 4,
		"meta_probabilidade": 0.6,
		"arrisca_torso": true,
		"peso_vulnerabilidade": 0.5,
		"peso_quase_derrotado": 1.5,
		"peso_protecao": 0.5,
		"peso_ameaca": 1.0,
		"peso_ataque": 1.0,
		"peso_duelo": 1.3,
		"peso_rastro": 1.1
	}
}


# ============================================================
# DECISÃO PRINCIPAL
# ============================================================

static func decidir(
	inimigo: CombatenteData,
	aliados: Array[CombatenteData],
	conhecimentos_usados: Array[String] = []
) -> Dictionary:

	if inimigo == null or inimigo.morto or not inimigo.esta_consciente():
		return _passar("Inimigo incapacitado")

	var perfil: Dictionary = PERFIS.get(
		inimigo.perfil_ia,
		PERFIS[PERFIL_PADRAO]
	)

	var alvos := _alvos_validos(aliados)

	if alvos.is_empty():
		return _passar("Nenhum alvo válido")

	var alvo := _escolher_alvo(
		inimigo,
		alvos,
		perfil
	)

	var melhor_acao: Dictionary = _passar("Nenhuma ação disponível")
	var maior_pontuacao: float = -INF

	# --------------------------------------------------------
	# ATAQUE PADRÃO
	# --------------------------------------------------------

	var regioes_validas := _regioes_arriscaveis(
		inimigo,
		perfil
	)

	if (
		inimigo.pontos_acao_atuais >= CUSTO_PA_ATAQUE
		and not regioes_validas.is_empty()
	):
		var escolha := _escolher_regioes(
			inimigo,
			alvo,
			regioes_validas,
			perfil
		)

		var pontuacao_ataque: float = float(perfil["peso_ataque"])

		melhor_acao = {
			"tipo": "atacar",
			"alvo": alvo,
			"regioes": escolha["regioes"],
			"probabilidade": escolha["probabilidade"],
			"custo_pa": CUSTO_PA_ATAQUE,
			"motivo": "%s: %d região(ões), chance de quebrar Proteção %.0f%%" % [
				alvo.nome,
				escolha["regioes"].size(),
				float(escolha["probabilidade"]) * 100.0
			]
		}

		maior_pontuacao = pontuacao_ataque

	# --------------------------------------------------------
	# CONHECIMENTO: DUELO
	# --------------------------------------------------------

	if (
		inimigo.conhecimentos_especializados.has("Duelo")
		and not conhecimentos_usados.has("Duelo")
		and inimigo.pontos_acao_atuais >= CUSTO_PA_CONHECIMENTO
		and alvo.obter_protecao_atual() > 0
	):
		var pontuacao_duelo: float = float(perfil["peso_duelo"])

		if pontuacao_duelo > maior_pontuacao:
			melhor_acao = {
				"tipo": "conhecimento",
				"conhecimento": "Duelo",
				"alvo": alvo,
				"custo_pa": CUSTO_PA_CONHECIMENTO,
				"motivo": "Tentar identificar uma abertura na Proteção de %s" % alvo.nome
			}

			maior_pontuacao = pontuacao_duelo

	# --------------------------------------------------------
	# CONHECIMENTO: RASTRO
	# --------------------------------------------------------

	if (
		inimigo.conhecimentos_especializados.has("Rastro")
		and not conhecimentos_usados.has("Rastro")
		and inimigo.pontos_acao_atuais >= CUSTO_PA_CONHECIMENTO
	):
		var pontuacao_rastro: float = float(perfil["peso_rastro"])

		if pontuacao_rastro > maior_pontuacao:
			melhor_acao = {
				"tipo": "conhecimento",
				"conhecimento": "Rastro",
				"alvo": alvo,
				"custo_pa": CUSTO_PA_CONHECIMENTO,
				"motivo": "Investigar informações sobre %s" % alvo.nome
			}

			maior_pontuacao = pontuacao_rastro

	return melhor_acao


static func _passar(motivo: String) -> Dictionary:
	return {
		"tipo": "passar",
		"alvo": null,
		"regioes": [] as Array[String],
		"probabilidade": 0.0,
		"custo_pa": 0,
		"motivo": motivo
	}


# ============================================================
# ALVOS
# ============================================================

static func _alvos_validos(
	aliados: Array[CombatenteData]
) -> Array[CombatenteData]:

	var validos: Array[CombatenteData] = []

	for aliado in aliados:
		if aliado != null and not aliado.morto and aliado.esta_consciente():
			validos.append(aliado)

	return validos


static func _escolher_alvo(
	inimigo: CombatenteData,
	alvos: Array[CombatenteData],
	perfil: Dictionary
) -> CombatenteData:

	var maior_dano: float = 1.0

	for alvo in alvos:
		maior_dano = maxf(
			maior_dano,
			float(alvo.atributo_dano)
		)

	var melhor: CombatenteData = alvos[0]
	var melhor_pontuacao: float = -INF

	for alvo in alvos:
		var pontuacao: float = _pontuar_alvo(
			inimigo,
			alvo,
			perfil,
			maior_dano
		)

		if pontuacao > melhor_pontuacao:
			melhor_pontuacao = pontuacao
			melhor = alvo

	return melhor


static func _pontuar_alvo(
	inimigo: CombatenteData,
	alvo: CombatenteData,
	perfil: Dictionary,
	maior_dano: float
) -> float:

	var torso: Dictionary = alvo.estresse_por_regiao.get(
		"Torso",
		{}
	)

	if torso.is_empty():
		return 0.0

	var limite: float = maxf(float(torso["limite"]), 1.0)
	var restante: int = int(torso["limite"]) - int(torso["atual"])

	var vulnerabilidade: float = float(torso["atual"]) / limite

	var quase_derrotado: float = 1.0 if (
		restante <= inimigo.atributo_dano
	) else 0.0

	var protecao: float = 1.0 / (
		1.0 + float(alvo.obter_protecao_atual())
	)

	var ameaca: float = float(alvo.atributo_dano) / maior_dano

	return (
		float(perfil["peso_vulnerabilidade"]) * vulnerabilidade
		+ float(perfil["peso_quase_derrotado"]) * quase_derrotado
		+ float(perfil["peso_protecao"]) * protecao
		+ float(perfil["peso_ameaca"]) * ameaca
	)


# ============================================================
# REGIÕES ARRISCÁVEIS
# ============================================================

static func _regioes_arriscaveis(
	inimigo: CombatenteData,
	perfil: Dictionary
) -> Array[String]:

	var validas: Array[String] = []

	for regiao in inimigo.estresse_por_regiao.keys():
		if inimigo.regioes_perdidas.has(regiao):
			continue

		if (
			inimigo.proteses.has(regiao)
			and inimigo.proteses[regiao].destruida
		):
			continue

		if not inimigo.regiao_pode_ser_arriscada(regiao):
			continue

		if regiao == "Torso" and not _pode_arriscar_torso(inimigo, perfil):
			continue

		validas.append(regiao)

	return validas


static func _pode_arriscar_torso(
	inimigo: CombatenteData,
	perfil: Dictionary
) -> bool:

	if not bool(perfil["arrisca_torso"]):
		return false

	var torso: Dictionary = inimigo.estresse_por_regiao["Torso"]

	var restante: int = (
		int(torso["limite"]) - int(torso["atual"])
	)

	return restante > ESTRESSE_FALHA_CRITICA


# ============================================================
# ESCOLHA DAS REGIÕES
# ============================================================

static func _escolher_regioes(
	inimigo: CombatenteData,
	alvo: CombatenteData,
	validas: Array[String],
	perfil: Dictionary
) -> Dictionary:

	var folga: Dictionary = {}

	for regiao in validas:
		var dados: Dictionary = inimigo.estresse_por_regiao[regiao]

		folga[regiao] = (
			int(dados["limite"]) - int(dados["atual"])
		)

	var ordenadas: Array[String] = validas.duplicate()

	ordenadas.sort_custom(
		func(a: String, b: String) -> bool:
			return int(folga[a]) > int(folga[b])
	)

	var maximo: int = mini(
		int(perfil["max_dados"]),
		ordenadas.size()
	)

	var protecao: int = alvo.obter_protecao_atual()
	var quantidade: int = maximo

	var probabilidade: float = _probabilidade_quebrar(
		maximo,
		protecao
	)

	for n in range(1, maximo + 1):
		var chance: float = _probabilidade_quebrar(
			n,
			protecao
		)

		if chance >= float(perfil["meta_probabilidade"]):
			quantidade = n
			probabilidade = chance
			break

	var regioes: Array[String] = []

	for i in range(quantidade):
		regioes.append(ordenadas[i])

	return {
		"regioes": regioes,
		"probabilidade": probabilidade
	}


# ============================================================
# PROBABILIDADE DE QUEBRAR A PROTEÇÃO
# ============================================================

static func _probabilidade_quebrar(
	dados: int,
	protecao: int
) -> float:

	if protecao <= 0:
		return 1.0

	var por_dado: Array[float] = [0.0, 0.0, 0.0]

	for face in range(1, 7):
		var categoria: String = RolagemD6.avaliar_resultado_d6(face)

		var acertos: int = 0

		if categoria == "Sucesso Extremo":
			acertos = 2
		elif categoria == "Sucesso Regular":
			acertos = 1

		por_dado[acertos] += 1.0 / 6.0

	var distribuicao: Array[float] = [1.0]

	for i in range(dados):
		var nova: Array[float] = []
		nova.resize(distribuicao.size() + 2)
		nova.fill(0.0)

		for soma in range(distribuicao.size()):
			for acertos in range(3):
				nova[soma + acertos] += (
					distribuicao[soma] * por_dado[acertos]
				)

		distribuicao = nova

	var total: float = 0.0

	for soma in range(distribuicao.size()):
		if soma >= protecao:
			total += distribuicao[soma]

	return total
