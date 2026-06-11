## Banco de dados de habilidades especiais OBLIVIO
## Habilidades são ações especiais com efeitos
## Classificação:
## - PRINCIPAL: Todos começam com (específica do Papel)
## - UNICA: Específica de cada Persona (ganha no jogo)
## - GERAL: Adquirida ao completar missões

class_name HabilidadeData
extends RefCounted

enum TipoHabilidade {
	PRINCIPAL = 1,  ## Todos começam com (específico do Papel)
	UNICA = 2,      ## Específica da Persona (ganha com jogo)
	GERAL = 3       ## Genérica (ganha em missões)
}

## Definição de uma habilidade
class Habilidade:
	var nome: String
	var descricao: String
	var custo_pa: int
	var tipo: String
	var tipo_habilidade: int

	var dano_dados: int = 0
	var dano_faces: int = 0
	var dano_bonus: int = 0

	var alcance: String = "Adjacente"

	var efeito: String
	var persona_origem: String = ""
	
	func _init(
		p_nome: String,
		p_descricao: String,
		p_custo: int,
		p_tipo: String,
		p_efeito: String,
		p_tipo_habilidade: int = TipoHabilidade.GERAL
	):
		nome = p_nome
		descricao = p_descricao
		custo_pa = p_custo
		tipo = p_tipo
		efeito = p_efeito
		tipo_habilidade = p_tipo_habilidade

## Banco de habilidades
var habilidades: Dictionary = {}

func _init() -> void:
	_inicializar_habilidades()

func _inicializar_habilidades() -> void:
	"""Define todas as habilidades OBLIVIO disponíveis"""
	
	# HABILIDADES DE QUEM AGE
	habilidades["Voracidade"] = Habilidade.new(
		"Voracidade",
		"Habilidade Principal, Efeito Passivo",
		0,  # 	Custa 0 PA
		"ataque",
		"Na primeira vez que acertar um ataque e causar pontos de Estresse a um alvo, o seu atributo de Dano é dobrado.",
		TipoHabilidade.PRINCIPAL
	)
	habilidades["Voracidade"].persona_origem = "Quem Age"
	
	habilidades["Ataque em Dupla"] = Habilidade.new(
		"Ataque em Dupla",
		"Habilidade única, Ação Completa",
		3,  # Custa 3 PA
		"ataque",
		"Escolha uma Persona adjacente para realizar um ataque em conjunto com você. Ambas devem rolar seus Testes de Combate separadamente, mas causam dano ao alvo caso tenham sucessos.",
		TipoHabilidade.UNICA
	)
	habilidades["Ataque em Dupla"].persona_origem = "Quem Age"
	
	habilidades["Estocada"] = Habilidade.new(
		"Estocada",
		"Habilidade única, Ação regular + Movimento",
		2,  # Custa 2 PA
		"ataque",
		"Avança pelo menos 1 espaço, realizando um ataque contra um alvo. Se acertar o ataque, cause uma quantidade extra de dano igual ao número de espaços avançados. Mesmo que erre o ataque, o alvo deve realizar um teste de Reflexos, ficando No Chão com uma falha.",
		TipoHabilidade.UNICA
	)
	habilidades["Estocada"].persona_origem = "Quem Age"
	habilidades["Sede de Sangue"] = Habilidade.new(
		"Sede de Sangue",
		"Habilidade única, Efeito Passivo",
		0,  # Custa 0 PA
		"cura",
		"Ao eliminar um alvo, recupera uma quantidade de pontos de Estresse igual ao dano total do seu ataque final.",
		TipoHabilidade.UNICA
	)
	habilidades["Sede de Sangue"].persona_origem = "Quem Age"
	
	# HABILIDADES DE QUEM PROTEGE
	habilidades["Escudo Humano"] = Habilidade.new(
		"Escudo Humano",
		"Habilidade Principal, Efeito Passivo",
		0,  # Custa 0 PA
		"defesa",
		"Enquanto estiver na frente de outras Personas, todas recebem um bônus de Proteção igual à metade do seu atributo de Carne. Se Quem Protege ficar No Chão, todas as Personas atrás dela na fileira de combate deixam de se beneficiar dessa habilidade.",
		TipoHabilidade.PRINCIPAL
	)
	habilidades["Escudo Humano"].persona_origem = "Mob"
	
	habilidades["Armadura de Espinhos"] = Habilidade.new(
		"Armadura de Espinhos",
		"Habilidade única, Efeito Passivo",
		0,  # Custa 0 PA
		"defesa",
		"Sempre que sofrer um ataque com sucesso, seu atacante deve realizar um teste de Fuga. Se falhar, ele recebe uma quantidade de pontos de Estresse igual à metade do seu atributo de Carne (ou 1, o que for maior).",
		TipoHabilidade.UNICA
	)
	habilidades["Armadura de Espinhos"].persona_origem = "Mob"
	
	habilidades["Peso Pesado"] = Habilidade.new(
		"Peso Pesado",
		"Habilidade única, Efeito Passivo",
		0,  # Custa 0 PA
		"ataque",
		"Permite adicionar metade do seu atributo de Carne à rolagem de dano de ataques corpo a corpo.",
		TipoHabilidade.UNICA
	)
	habilidades["Peso Pesado"].persona_origem = "Mob"

	habilidades["Repartir a dor"] = Habilidade.new(
		"Repartir a dor",
		"Habilidade única, Efeito Passivo",
		0,  # Custa 0 PA
		"defesa",
		"Sempre que uma Persona que esteja atrás de seu Escudo Humano sofrer dano de um ataque ou habilidade, você pode dividir os Pontos de Estresse com ela.",
		TipoHabilidade.UNICA
	)
	habilidades["Repartir a dor"].persona_origem = "Mob"
	
	# HABILIDADES DE QUEM CUIDA
	habilidades["Ajudar os necessitados"] = Habilidade.new(
		"Ajudar os necessitados",
		"Habilidade Principal, Ação extra",
		0,  # Custa 0 PA
		"cura",
		"No início de cada rodada, ou uma vez por Cena de Descanso ou Interação, escolha até duas Personas adjacentes para recuperar uma quantidade de pontos de Estresse igual à metade do seu atributo de Mente.",
		TipoHabilidade.PRINCIPAL
	)
	habilidades["Ajudar os necessitados"].persona_origem = "Escolhido"	
	
	habilidades["Abrir feridas"] = Habilidade.new(
		"Abrir feridas",
		"Habilidade única, Ação regular",
		1,  # Custa 1 PA
		"ataque",
		"Você pode converter metade dos pontos de Estresse que curou de outras Personas com habilidades do seu Papel nessa Cena de Jogo em dano extra para um único ataque. Uma vez por rodada faça o Teste de Combate e, se acertar, cause uma quantidade de dano extra igual à metade do valor acumulado até então. Após isso, o valor retorna a zero.",
		TipoHabilidade.UNICA
	)
	habilidades["Abrir feridas"].persona_origem = "Escolhido"

	habilidades["Bálsamo"] = Habilidade.new(
		"Bálsamo",
		"Habilidade única, Ação regular",
		1,  # Custa 1 PA
		"cura",
		"Recupera a si ou uma Persona adjacente de uma mazela que esteja lhe afligindo. Uma vez por partida, também é possível recuperar uma região de corpo sua, ou de outra Persona, que tenha sido perdida, fazendo com que você receba uma quantidade de pontos de Estresse igual ao limite máximo dela",
		TipoHabilidade.UNICA
	)
	habilidades["Bálsamo"].persona_origem = "Escolhido"

	habilidades["Última Esperança"] = Habilidade.new(
		"Última Esperança",
		"Habilidade única, Ação regular",
		1,  # Custa 1 PA
		"cura",
		"Uma vez por Cena de Jogo, durante 3 rodadas no início dos seus turnos ou 3 momentos à sua escolha numa cena de Descanso ou Interação, recupera automaticamente uma quantidade de pontos de Estresse de todas as Personas do grupo, inclusive você, igual à metade do seu atributo de Mente",
		TipoHabilidade.UNICA
	)
	habilidades["Última Esperança"].persona_origem = "Escolhido"
	
	# HABILIDADES DE QUEM RESOLVE (JPdaMaldade)
	habilidades["Dar uma mãozinha"] = Habilidade.new(
		"Dar uma mãozinha",
		"Habilidade Principal, Ação extra",
		0,  # Custa 0 PA
		"utilidade",
		"Sempre que uma Persona tiver uma falha em um Teste de Conhecimento ou Combate, inclusive você, role 1D6. Se tirar de 4 a 6, você consegue transformar a falha em um sucesso. Se tirar de 1 a 3, a ação continua falhando e você recebe uma quantidade de Pontos de Estresse igual ao grau da falha (Regular = 1 Ponto, Extrema = 2 Pontos).",
		TipoHabilidade.PRINCIPAL
	)
	habilidades["Dar uma mãozinha"].persona_origem = "JPdaMaldade"
	
	habilidades["Animar os Ânimos"] = Habilidade.new(
		"Animar os Ânimos",
		"Habilidade única, Ação extra",
		0,  # Custa 0 PA
		"cura",
		"Uma vez por cena, na primeira vez que uma Persona adjacente alcançar o seu limite máximo de Estresse, você pode fazê-la recuperar uma quantidade de Pontos de Estresse igual à metade do seu atributo de Determinação, impedindo que ela fique Fora de Ação.",
		TipoHabilidade.UNICA
	)
	habilidades["Animar os Ânimos"].persona_origem = "JPdaMaldade"
	
	habilidades["Cópia barata"] = Habilidade.new(
		"Cópia barata",
		"Habilidade única, Ação Extra",
		0,  # Custa 0 PA
		"utilidade",
		"Escolha uma Habilidade Única de outra Persona que faça parte do seu grupo. Até o final dessa Cena de Jogo, você pode usar a habilidade escolhida como se fosse sua. Você pode copiar um máximo de habilidades igual à metade do seu atributo de Determinação, entre Cenas de Descanso. Depois de copiada uma vez, a habilidade não pode mais ser alvo de Cópia Barata até o final da Cena de Descanso.",
		TipoHabilidade.UNICA
	)
	habilidades["Cópia barata"].persona_origem = "JPdaMaldade"

	habilidades["Instrução Decisiva"] = Habilidade.new(
		"Instrução Decisiva",
		"Habilidade única, Ação regular",
		0,  # Custa 0 PA
		"utilidade",
		"Escolha uma Persona para realizar uma ação, que não seja Completa, fora de seu turno.",
		TipoHabilidade.UNICA
	)
	habilidades["Instrução Decisiva"].persona_origem = "JPdaMaldade"
	
	#HABILIDADES DE INIMIGOS
	habilidades["Disseminar Praga"] = Habilidade.new(
	"Disseminar Praga",
	"Ação Regular",
	1,
	"ataque",
	"A Carcaça ataca um alvo até em Alcance Adjacente, causando
	2D4+3 PE e obrigando ele a realizar um teste de Esforço, recebendo 1 ponto de Infecção se falhar. Ao final de cada Cena de
	Jogo, o alvo deve realizar outro teste de Esforço, recebendo
	um ponto adicional se falhar - ou se ficar Fora de Ação. Para se
	curar definitivamente, é necessário gastar um Kit de Primeiros
	Socorros por completo ou um uso da habilidade Bálsamo.
	• 1 ponto: Botando para Fora até o final da cena.
	• 2 a 3 pontos: Lentidão até se tratar.
	• 4 a 5 pontos: Fome até se tratar.
	• 6 pontos: Se torna uma Carcaça.",
	TipoHabilidade.GERAL
	)
	habilidades["Disseminar Praga"].dano_dados = 2
	habilidades["Disseminar Praga"].dano_faces = 4
	habilidades["Disseminar Praga"].dano_bonus = 0
	habilidades["Disseminar Praga"].alcance = "Curto"


## Obtém uma habilidade pelo nome
func get_habilidade(nome: String) -> Habilidade:
	if habilidades.has(nome):
		return habilidades[nome]
	return null

## Lista habilidades por tipo
func habilidades_por_tipo(tipo: String) -> Array:
	var lista = []
	for nome in habilidades:
		if habilidades[nome].tipo == tipo:
			lista.append(habilidades[nome])
	return lista

## Lista habilidades que um combatente conhece
func habilidades_conhecidas(combatente: CombatenteData) -> Array:
	var lista = []
	for nome in combatente.habilidades:
		var hab = get_habilidade(nome)
		if hab:
			lista.append(hab)
	return lista

## Verifica se combatente pode usar habilidade (tem PA e conhece)
func pode_usar_habilidade(combatente: CombatenteData, nome_habilidade: String) -> bool:
	if not combatente.habilidades.has(nome_habilidade):
		return false
	
	var hab = get_habilidade(nome_habilidade)
	if hab == null:
		return false
	
	return combatente.pontos_acao_atuais >= hab.custo_pa

## Usa uma habilidade (consome PA)
func usar_habilidade(combatente: CombatenteData, nome_habilidade: String) -> Dictionary:
	var hab = get_habilidade(nome_habilidade)
	
	if hab == null:
		return {
			"sucesso": false,
			"erro": "Habilidade não encontrada: %s" % nome_habilidade
		}
	
	if not combatente.habilidades.has(nome_habilidade):
		return {
			"sucesso": false,
			"erro": "%s não conhece essa habilidade" % combatente.nome
		}
	
	if not combatente.consumir_pontos_acao(hab.custo_pa):
		return {
			"sucesso": false,
			"erro": "PA insuficiente (precisa de %d, tem %d)" % [hab.custo_pa, combatente.pontos_acao_atuais]
		}
	
	return {
		"sucesso": true,
		"habilidade": hab.nome,
		"custo_pa": hab.custo_pa,
		"tipo": hab.tipo,
		"efeito": hab.efeito,
		"personagem": combatente.nome
	}

## Retorna todas as habilidades disponíveis
func get_todas_habilidades() -> Array:
	var lista = []
	for nome in habilidades:
		lista.append(habilidades[nome])
	return lista

func rolar_dano_habilidade(hab: Habilidade) -> int:
	var dano = hab.dano_bonus
	for i in range(hab.dano_dados):
		dano += randi_range(1, hab.dano_faces)
	return dano

## Filtra habilidades pelo tipo (PRINCIPAL, UNICA, GERAL)
static func obter_habilidades_por_tipo(habilidades_array: Array[String], tipo: int) -> Array[String]:
	"""Retorna array de nomes de habilidades que pertencem ao tipo especificado"""
	var resultado: Array[String] = []
	var db = HabilidadeData.new()
	
	for nome_hab in habilidades_array:
		var hab = db.get_habilidade(nome_hab)
		if hab and hab.tipo_habilidade == tipo:
			resultado.append(nome_hab)
	
	return resultado
