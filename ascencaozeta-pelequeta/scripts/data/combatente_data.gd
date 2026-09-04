## Dados de um Combatente - Estrutura base para inimigos, jogadores e NPCs
## Em OBLIVIO: Estresse acumula de 0 até o LIMITE (não é HP)
## Quando região atinge seu limite, fica ESGOTADA (fadiga)

class_name CombatenteData
extends RefCounted

## Regiões do corpo
const REGIOES = ["Torso", "Braço Direito", "Braço Esquerdo", "Perna Direita", "Perna Esquerda"]

## Atributos do combatente
var nome: String
var tipo: String  # "jogador", "inimigo", "npc"

## Atributos Fixos OBLIVIO (5 pilares)
var atributo_carne: int = 1              # Saúde, vigor e integridade física
var atributo_forca: int = 1              # Potência muscular e capacidade de danificar
var atributo_mente: int = 1              # Aptidão e resiliência intelectual
var atributo_fuga: int = 1               # Agilidade e velocidade de reação
var atributo_determinacao: int = 1       # Resiliência e inteligência emocional

## Atributos Mutáveis (derivados dos Fixos: (fixo1 + fixo2) / 2, arredondado para baixo)
## - Fôlego = (Carne + Determinação) / 2
## - Dano = (Força + Carne) / 2
## - Coragem = (Determinação + Mente) / 2
## - Proteção = (Carne + Fuga) / 2
## - Velocidade = (Fuga + Determinação) / 2
var atributo_folego: int = 1             # Capacidade de recuperação durante ação
var atributo_dano: int = 1               # Intensidade de dano
var atributo_coragem: int = 1            # Firmeza e resiliência emocional
var atributo_protecao: int = 1           # Dificuldade de ser acertado
var atributo_velocidade: int = 1         # Velocidade de movimento


## Dados de combate
var arma_equipada: String = ""
var dano_arma: int = 1
var defesa_base: int = 1
var iniciativa: int = 0
var status: Array[String] = []
var desmaiado: bool = false
var reducao_protecao_temporaria: int = 0
var bonus_duelo_protecao := 0
var analisado_por_duelo := false

# Quem causou o último dano após quebrar a proteção
var atacante_que_quebrou_protecao: String = ""


## ESTRESSE POR REGIÃO (métrica principal em OBLIVIO)
## Começa com 0 e acumula até o LIMITE
## Quando atinge limite, região fica ESGOTADA (fadiga)
var estresse_por_regiao: Dictionary = {
	"Torso": {"atual": 0, "limite": 6},
	"Braço Direito": {"atual": 0, "limite": 3},
	"Braço Esquerdo": {"atual": 0, "limite": 3},
	"Perna Direita": {"atual": 0, "limite": 3},
	"Perna Esquerda": {"atual": 0, "limite": 3}
}

## Pontos de Ação
var pontos_acao_atuais: int = 3
var pontos_acao_maximos: int = 3

## CONHECIMENTOS (Perícias OBLIVIO)
## Nível de treino em cada um dos 10 Conhecimentos (sem máximo)
var conhecimentos_treino: Dictionary = { 
	"Bandidagem": 0,    # Delitos, furtividade de crimes
	"Duelo": 0,         # Estratégia marcial, brechas em defesa
	"Emocional": 0,     # Autocontrole, gestão de sentimentos
	"Esforço": 0,       # Físico desgastante, resistência corporal
	"Místico": 0,       # Sobrenatural, artes arcanas, seres outros
	"Mundo": 0,         # Natureza, animais, sobrevivência
	"Rastro": 0,        # Percepção, detalhes ocultos, sensoriais
	"Reflexos": 0,      # Esquiva, corporais rápidos, movimento
	"Saber": 0,         # Memória, estudos, conhecimento geral
	"Social": 0         # Persuasão, manipulação emocional, charisma
}

## Conhecimentos Especializados (persona tem 3 + Mente/2 especializados)
## Ao testar especializado, soma +2 ao resultado
var conhecimentos_especializados: Array[String] = []


## Habilidades especiais
var habilidades: Array[String] = []

## Itens
var inventario: Array[String] = []


## Sistema de Fardos (Dark Souls curses) - Aplicados quando Torso atinge limite
var fardos: Array = []                           # Array de Fardo aplicados
var regioes_perdidas: Array[String] = []       # Membros perdidos por Guilhotina
var numero_desmaios_total: int = 0             # Total de vezes que atingiu limite de Torso
var limite_estresse_maximo_reducao: int = 0    # Redução permanente por Mal das Pernas

## Sistema de Próteses - Permitem manter regiões após dano severo
## Chave = nome da região, Valor = Protese object
var proteses: Dictionary = {}                   # Próteses por região
var habilidade_sobrecarga_ativa: bool = false  # Ir Além - permite arriscar múltiplas vezes mesma região

## Flags de efeitos de Fardos
var tem_covardia: bool = false                  # -2x Coragem em testes
var tem_fragilidade: bool = false              # +1D6 dano recebido
var tem_ataque_cardiaco: bool = false          # Risco de morte em próxima vez
var morto: bool = false                         # Flag de morte permanente


## ===== MÉTODOS =====

func _init(p_nome: String, p_tipo: String) -> void:
	nome = p_nome
	tipo = p_tipo
	_calcular_atributos_mutaveis()

## Calcula todos os Atributos Mutáveis baseado nos Atributos Fixos
func _calcular_atributos_mutaveis() -> void:
	atributo_folego = (atributo_carne + atributo_determinacao) / 2
	atributo_dano = (atributo_forca + atributo_carne) / 2
	atributo_coragem = (atributo_determinacao + atributo_mente) / 2
	atributo_protecao = (atributo_carne + atributo_fuga) / 2
	atributo_velocidade = (atributo_fuga + atributo_determinacao) / 2

## Atualiza atributo fixo e recalcula os mutáveis
func atualizar_atributo_fixo(atributo: String, valor: int) -> void:
	match atributo.to_lower():
		"carne": atributo_carne = valor
		"forca": atributo_forca = valor
		"mente": atributo_mente = valor
		"fuga": atributo_fuga = valor
		"determinacao": atributo_determinacao = valor
	_calcular_atributos_mutaveis()

## ===== CONHECIMENTOS (PERÍCIAS OBLIVIO) =====

## Verifica se um Conhecimento é especializado
func tem_especializacao(conhecimento: String) -> bool:
	return conhecimento in conhecimentos_especializados

## Adiciona especialização a um conhecimento
func adicionar_especializacao(conhecimento: String) -> void:
	if conhecimento in conhecimentos_treino and not tem_especializacao(conhecimento):
		conhecimentos_especializados.append(conhecimento)

## Remove especialização de um conhecimento
func remover_especializacao(conhecimento: String) -> void:
	if tem_especializacao(conhecimento):
		conhecimentos_especializados.erase(conhecimento)

## Retorna nível de treino em um conhecimento
func obter_treino_conhecimento(conhecimento: String) -> int:
	if conhecimentos_treino.has(conhecimento):
		return conhecimentos_treino[conhecimento]
	return 0

## Aumenta nível de treino em um conhecimento
func aumentar_treino_conhecimento(conhecimento: String, quantidade: int = 1) -> void:
	if conhecimentos_treino.has(conhecimento):
		conhecimentos_treino[conhecimento] += quantidade

## ===== VERIFICAÇÃO DE STATUS =====

## Verifica se combatente ainda está consciente (Apenas o Torso)
func esta_consciente() -> bool:
	return not desmaiado

## Verifica se combatente desmaiou (TODAS regiões esgotadas)
func esta_desmaiado() -> bool:
	return not esta_consciente()

## Verifica se região específica está esgotada (estresse >= limite)
func regiao_esgotada(regiao: String) -> bool:
	if not estresse_por_regiao.has(regiao):
		return false
	var estresse = estresse_por_regiao[regiao]
	return estresse["atual"] >= estresse["limite"]

## Verifica se região ainda pode ser arriscada (não esgotada)
func regiao_pode_ser_arriscada(regiao: String) -> bool:
	return not regiao_esgotada(regiao)

## ===== APLICAÇÃO DE EFEITOS =====

## Aplica estresse a uma região (métrica principal em OBLIVIO)
## Se superar limite, transborda para torso (exceto se for torso)
# REGRA OBLIVIO: Dano que supera limite transborda para torso
func aplicar_estresse(regiao: String, estresse_quantidade: int) -> Dictionary:
	var resultado: Dictionary = {}
	if not estresse_por_regiao.has(regiao):
		return {}
	var regiao_stress = estresse_por_regiao[regiao]
	regiao_stress["atual"] += estresse_quantidade
	# Torso
	if regiao == "Torso":
		if regiao_stress["atual"] >= regiao_stress["limite"]:
			regiao_stress["atual"] = regiao_stress["limite"]
			if not desmaiado:
				desmaiado = true
				resultado = processar_limite_torso()
				
				
		return resultado
	# Regiões normais - CAP no limite (não marca como perdida permanentemente)
	if regiao_stress["atual"] >= regiao_stress["limite"]:
		regiao_stress["atual"] = regiao_stress["limite"]
		resultado = {
			"regiao_esgotada": true,
			"regiao": regiao,
			"mensagem": "%s não pode mais ser arriscado." % regiao
		}
		return resultado
		# Apenas bloqueia seleção enquanto esgotada - pode recuperar depois
	
	var excesso = regiao_stress["atual"] - regiao_stress["limite"]
	if excesso > 0:
		regiao_stress["atual"] = regiao_stress["limite"]
		var torso_stress = estresse_por_regiao["Torso"]
		torso_stress["atual"] += excesso
		
		if torso_stress["atual"] >= torso_stress["limite"]:
			torso_stress["atual"] = torso_stress["limite"]
			resultado = processar_limite_torso()
			
	return resultado

## ===== CÁLCULOS =====
func calcular_dano_ataque() -> int:
	var dano = atributo_dano
	if arma_equipada != "":
		dano += ArmaData.rolar_dano_arma(
			arma_equipada
		)
	return dano
## Retorna estresse total (soma de todas regiões)
func get_estresse_total() -> int:
	var total = 0
	for regiao_est in estresse_por_regiao.values():
		total += regiao_est["atual"]
	return total

## Retorna limite de estresse total
func get_limite_estresse_total() -> int:
	var total = 0
	for regiao_est in estresse_por_regiao.values():
		total += regiao_est["limite"]
	return total

## Retorna porcentagem de fadiga geral (0-100%)
func get_porcentagem_fadiga() -> float:
	var total = get_estresse_total()
	var limite = get_limite_estresse_total()
	if limite == 0:
		return 0.0
	return (float(total) / float(limite)) * 100.0

## Retorna quantas regiões estão esgotadas
func contar_regioes_esgotadas() -> int:
	var count = 0
	for regiao in REGIOES:
		if regiao_esgotada(regiao):
			count += 1
	return count

func obter_protecao_atual() -> int:
	return max(
		0,
		atributo_protecao
		- reducao_protecao_temporaria
		- bonus_duelo_protecao
	)
## ===== PA (PONTOS DE AÇÃO) =====

## Restaura PA no início do turno
func restaurar_pontos_acao() -> void:
	pontos_acao_atuais = pontos_acao_maximos

## Consome PA para uma ação
func consumir_pontos_acao(custo: int) -> bool:
	if pontos_acao_atuais >= custo:
		pontos_acao_atuais -= custo
		return true
	return false

## ===== DESMAIOS E FARDOS =====

func processar_limite_torso() -> Dictionary:
	print("=== PROCESSAR LIMITE TORSO ===")
	print(nome)
	print(tipo)
	
	# Inimigos morrem na primeira
	if tipo == "inimigo":
		morto = true
		desmaiado = true
		return {
			"sucesso": true,
			"derrotado": true,
		}

	# Jogadores recebem Fardos
	numero_desmaios_total += 1

	# 3ª desmaio (ou mais) com Ataque Cardíaco = MORTE PERMANENTE
	if numero_desmaios_total >= 3 and tem_ataque_cardiaco:
		morto = true
		desmaiado = true
		return {
			"numero_desmaio": numero_desmaios_total,
			"morto": true,
			"mensagem": "ATAQUE CARDÍACO! %s morreu permanentemente!" % nome
		}

	# Sorteio normal de Fardo
	var novo_fardo = FardoData.sortear_fardo(numero_desmaios_total)
	var resultado_fardo = FardoData.aplicar_fardo(self, novo_fardo)

	return {
		"numero_desmaio": numero_desmaios_total,
		"fardo_aplicado": novo_fardo.nome,
		"resultado_fardo": resultado_fardo,
		"mensagem": "Desmaiou #%d - %s!" % [numero_desmaios_total, novo_fardo.nome]
	}

## Revive um combatente (reduz 1 ponto de Torso para acordar)
func reviver() -> void:
	"""Revive o combatente desmaiado removendo 1 Torso (pode agir novamente)"""
	var torso = estresse_por_regiao["Torso"]
	torso["atual"] = max(0, torso["atual"] - 1)

## Verifica se personagem está desmaiado (TODAS regiões no limite)
func verificar_desmaio() -> bool:
	"""Apenas verifica, sem aplicar Fardo (use processar_limite_torso() para isso)"""
	return esta_desmaiado()

## ===== COMPATIBILIDADE COM DICIONÁRIO =====

## Converte para Dictionary para compatibilidade
func para_dictionary() -> Dictionary:
	return {
		"nome": nome,
		"tipo": tipo,
		"atributo_carne": atributo_carne,
		"atributo_forca": atributo_forca,
		"atributo_mente": atributo_mente,
		"atributo_fuga": atributo_fuga,
		"atributo_determinacao": atributo_determinacao,
		"atributo_folego": atributo_folego,
		"atributo_dano": atributo_dano,
		"atributo_coragem": atributo_coragem,
		"atributo_protecao": atributo_protecao,
		"reducao_protecao_temporaria": reducao_protecao_temporaria,
		"atacante_que_quebrou_protecao": atacante_que_quebrou_protecao,
		"atributo_velocidade": atributo_velocidade,
		"status": status,
		"estresse_por_regiao": estresse_por_regiao,
		"pontos_acao_atuais": pontos_acao_atuais,
		"pontos_acao_maximos": pontos_acao_maximos,
		"conhecimentos_treino": conhecimentos_treino,
		"conhecimentos_especializados": conhecimentos_especializados,
		"analisado_por_duelo": analisado_por_duelo,
		"habilidades": habilidades,
		"inventario": inventario,
		"fardos": fardos,
		"regioes_perdidas": regioes_perdidas,
		"numero_desmaios_total": numero_desmaios_total,
		"morto": morto
	}
## Cria a partir de um Dictionary
static func de_dictionary(dados: Dictionary) -> CombatenteData:
	var nome_temp = "Desconhecido"
	if dados.has("nome"):
		nome_temp = dados["nome"]
	
	var tipo_temp = "npc"
	if dados.has("tipo"):
		tipo_temp = dados["tipo"]
	
	var combatente = CombatenteData.new(nome_temp, tipo_temp)
	
	if dados.has("atributo_carne"):
		combatente.atributo_carne = dados["atributo_carne"]
	if dados.has("atributo_forca"):
		combatente.atributo_forca = dados["atributo_forca"]
	if dados.has("atributo_mente"):
		combatente.atributo_mente = dados["atributo_mente"]
	if dados.has("atributo_fuga"):
		combatente.atributo_fuga = dados["atributo_fuga"]
	if dados.has("atributo_determinacao"):
		combatente.atributo_determinacao = dados["atributo_determinacao"]
	
	if dados.has("atributo_folego"):
		combatente.atributo_folego = dados["atributo_folego"]
	if dados.has("atributo_dano"):
		combatente.atributo_dano = dados["atributo_dano"]
	if dados.has("atributo_coragem"):
		combatente.atributo_coragem = dados["atributo_coragem"]
	if dados.has("atributo_protecao"):
		combatente.atributo_protecao = dados["atributo_protecao"]
	if dados.has("atributo_velocidade"):
		combatente.atributo_velocidade = dados["atributo_velocidade"]
	combatente._calcular_atributos_mutaveis()
	if dados.has("dano_arma"):
		combatente.dano_arma = dados["dano_arma"]
	if dados.has("defesa_base"):
		combatente.defesa_base = dados["defesa_base"]
	if dados.has("iniciativa"):
		combatente.iniciativa = dados["iniciativa"]
	
	if dados.has("estresse_por_regiao"):
		combatente.estresse_por_regiao = dados["estresse_por_regiao"]
	
	if dados.has("pontos_acao_atuais"):
		combatente.pontos_acao_atuais = dados["pontos_acao_atuais"]
	if dados.has("pontos_acao_maximos"):
		combatente.pontos_acao_maximos = dados["pontos_acao_maximos"]
	
	if dados.has("conhecimentos_treino"):
		combatente.conhecimentos_treino = dados["conhecimentos_treino"]
	if dados.has("conhecimentos_especializados"):
		combatente.conhecimentos_especializados = dados["conhecimentos_especializados"]
	if dados.has("habilidades"):
		combatente.habilidades = dados["habilidades"]
	if dados.has("inventario"):
		combatente.inventario = dados["inventario"]
	if dados.has("numero_desmaios_total"):
		combatente.numero_desmaios_total = dados["numero_desmaios_total"]
	if dados.has("regioes_perdidas"):
		combatente.regioes_perdidas = dados["regioes_perdidas"]
	if dados.has("morto"):
		combatente.morto = dados["morto"]
	if dados.has("desmaiado"):
		combatente.desmaiado = dados["desmaiado"]
	
	return combatente

## ===== SISTEMA DE PRÓTESES =====

## Adiciona uma prótese ao combatente
func adicionar_protese(protese: ProteseData.Protese) -> void:
	proteses[protese.regiao_representada] = protese

## Obtém uma prótese por região
func obter_protese(regiao: String) -> ProteseData.Protese:
	if proteses.has(regiao):
		return proteses[regiao]
	return null

## Verifica se região tem prótese
func tem_protese(regiao: String) -> bool:
	return proteses.has(regiao) and not proteses[regiao].destruida

## Aplica estresse à prótese (retorna excedente)
func aplicar_estresse_protese(regiao: String, quantidade: int) -> int:
	var protese = obter_protese(regiao)
	if protese:
		return protese.sofrer_estresse(quantidade)
	return quantidade

## Recupera estresse da prótese
func recuperar_protese(regiao: String, quantidade: int) -> void:
	var protese = obter_protese(regiao)
	if protese:
		protese.recuperar_estresse(quantidade)
