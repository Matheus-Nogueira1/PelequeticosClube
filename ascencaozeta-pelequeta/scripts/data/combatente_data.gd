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

## Atributos fixos OBLIVIO (5 pilares)
var atributo_carne: int = 1      # Define limite base de estresse representa a sua saúde, vigor e integridade física;
var atributo_forca: int = 1	    # Representa a sua potência muscular e capacidadede danificar;
var atributo_mente: int = 1		# Representa a sua aptidão e resiliência intelectual;
var atributo_fuga: int = 1		# Representa a sua agilidade e velocidade de reação;
var atributo_determinacao: int = 1		# Representa a sua resiliência e inteligência emocional;

## Atributos Mutáveis é derivado de dois Atributos Fixos específicos, e para calculá-lo basta somar os valores dos Atributos Fixos correspondentes, dividir por 2 e arredondar para baixo.

var atributo_folego: int = 1		# Representa a sua capacidade de recuperação durante momentos de ação;
var atributo_dano: int = 1      	# Representa a intensidade com que você machuca alguma coisa;
var atributo_coragem: int = 1		# Representa até que ponto você consegue se manter firme;
var atributo_protecao: int = 1		# Representa o quão difícil é te acertar com um ataque;
var atributo_velocidade: int = 1		# Representa o quão rápido consegue se mover;


## Dados de combate
var dano_arma: int = 1
var defesa_base: int = 1
var iniciativa: int = 0
var status: Array[String] = []

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

## Pericias conhecidas
var pericias: Dictionary = { "Bandidagem": 1 # É usado para cometer delitos ou fazer o seu melhor para não te pegarem enquanto os comete; 
, "Duelo": 1 # É usado para testar seus conhecimentos marciais e identificar brechas ou vantagens em um combate	
, "Emocional": 1 # É usado para testar as suas emoções e definir o quão bem você consegue lidar com elas;
, "Esforço": 1 # É usado para realizar ações físicas desgastantes, como manter o fôlego, empurrar algo pesado, resistir a venenos…;
, "Místico": 1 # É usado para saber de temas não-mundanos, como artes ritualísticas, religiosas, místicas…;
, "Mundo": 1 # É usado para saber sobre o mundo natural, a terra, o que habita nela e como sobreviver;
, "Rastro": 1 # É usado para testar seus sentidos e a sua capacidade de perceber detalhes ocultos no ambiente;
, "Reflexos": 1 # É usado para testar a sua agilidade enquanto se esquiva ou acerta  alguma coisa;
, "Saber": 1 # É usado para testar diferentes conhecimentos adquiridos através de estudo, educação ou conversas;
, "Social": 1 # É usado para influenciar emoções alheias e alterar a percepção que outras pessoas têm sobre você; 
}  # {"nome": nivel}


## Habilidades especiais
var habilidades: Array[String] = []

## Itens
var inventario: Array[String] = []


## ===== MÉTODOS =====

func _init(p_nome: String, p_tipo: String) -> void:
	nome = p_nome
	tipo = p_tipo

## ===== VERIFICAÇÃO DE STATUS =====

## Verifica se combatente ainda está consciente (pelo menos uma região não esgotada)
func esta_consciente() -> bool:
	for regiao_stress in estresse_por_regiao.values():
		if regiao_stress["atual"] < regiao_stress["limite"]:
			return true
	return false

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
func aplicar_estresse(regiao: String, estresse_quantidade: int) -> void:
	if not estresse_por_regiao.has(regiao):
		print("[CombatenteData] Região inválida: %s" % regiao)
		return
	
	var regiao_stress = estresse_por_regiao[regiao]
	regiao_stress["atual"] += estresse_quantidade
	
	# REGRA OBLIVIO: Dano que supera limite transborda para torso
	if regiao != "Torso" and regiao_stress["atual"] > regiao_stress["limite"]:
		var transbordado = regiao_stress["atual"] - regiao_stress["limite"]
		regiao_stress["atual"] = regiao_stress["limite"]  # Capa no limite
		
		# Transborda para torso
		if transbordado > 0:
			print("[CombatenteData] Estresse de %s transbordo %d para Torso!" % [regiao, transbordado])
			var torso_stress = estresse_por_regiao["Torso"]
			torso_stress["atual"] += transbordado

## Reduz estresse de uma região (cura/recuperação)
func aliviar_estresse(regiao: String, quantidade: int) -> void:
	if estresse_por_regiao.has(regiao):
		estresse_por_regiao[regiao]["atual"] = max(0, estresse_por_regiao[regiao]["atual"] - quantidade)

## ===== CÁLCULOS =====

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

## ===== DESMAIOS =====

## Verifica se personagem desmaiou e trata
func verificar_desmaio() -> bool:
	if esta_desmaiado():
		morto = true
		print("[CombatenteData] %s morreu!" % nome)
		return true
	return false

## ===== COMPATIBILIDADE COM DICTIONÁRIO =====

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
		"atributo_velocidade": atributo_velocidade,
		"status": status,
		"estresse_por_regiao": estresse_por_regiao,
		"pontos_acao_atuais": pontos_acao_atuais,
		"pontos_acao_maximos": pontos_acao_maximos,
		"pericias": pericias,
		"habilidades": habilidades,
		"inventario": inventario,
		"desmaios": desmaios,
		"morto": morto
	}

## Cria a partir de um Dictionary
static func de_dictionary(dados: Dictionary) -> CombatenteData:
	var combatente = CombatenteData.new(dados.get("nome", "Desconhecido"), dados.get("tipo", "npc"))
	
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
	
	if dados.has("pericias"):
		combatente.pericias = dados["pericias"]
	if dados.has("habilidades"):
		combatente.habilidades = dados["habilidades"]
	if dados.has("inventario"):
		combatente.inventario = dados["inventario"]
	
	if dados.has("desmaios"):
		combatente.desmaios = dados["desmaios"]
	if dados.has("morto"):
		combatente.morto = dados["morto"]
	
	return combatente
