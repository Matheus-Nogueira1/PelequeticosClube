extends RefCounted
class_name EstatisticasCombate

# ============================================================
# ESTATÍSTICAS DE UM COMBATE
# Acumuladas pelo CombatManager nos eventos reais (nunca pelo
# CombatLog). Um objeto novo por combate; a pontuação é
# calculada uma única vez, ao encerrar.
#
#   P_base  = 1000 + Dc*10 + Ce*10 - Dr*5 - 200*Ad + 250*Ar + Estilo
#   P_final = max(0, round(P_base * M) + Ajuste)
# O bônus de recuperação (250*Ar) JÁ está na P_base.
# M (só em vitória rápida) e o Ajuste vêm de ClassificacaoCombate.
# ============================================================

# ------------------------------------------------------------
# CONFIGURAÇÃO
# ------------------------------------------------------------
const PONTUACAO_BASE: int = 1000
const PENALIDADE_DESMAIO: int = 200
const BONUS_REANIMACAO: int = 250
const PONTUACAO_MINIMA: int = 0
const PONTOS_POR_DANO: int = 10
const PONTOS_POR_CURA: int = 10
const PENALIDADE_POR_DANO_RECEBIDO: int = 5
const CONTAR_ESTRESSE_DE_FALHA: bool = false
# Categorias de ação (o que foi realmente executado).
const CATEGORIA_ATAQUE: String = "ataque"
const CATEGORIA_HABILIDADE: String = "habilidade"
const CATEGORIA_PERICIA: String = "pericia"
const CATEGORIA_ITEM: String = "item"
const CATEGORIA_MOVIMENTO: String = "movimento"  # preparada; nada a registra ainda
const CATEGORIAS_VALIDAS: Array[String] = [
	CATEGORIA_ATAQUE,
	CATEGORIA_HABILIDADE,
	CATEGORIA_PERICIA,
	CATEGORIA_ITEM,
	CATEGORIA_MOVIMENTO
]

# Pontos de variedade por quantidade de categorias DIFERENTES
# usadas por um personagem em um turno. Chave = quantidade.
const PONTOS_VARIEDADE: Dictionary = {
	1: 0,
	2: 100,
	3: 250,
	4: 450,
	5: 700
}

# ------------------------------------------------------------
# DADOS DO COMBATE
# ------------------------------------------------------------
var dano_causado: int = 0
var cura_efetiva: int = 0
var dano_recebido: int = 0
var aliados_desmaiados: int = 0
var aliados_reanimados: int = 0
# Estilo (variedade de ações), coletivo.
var pontos_estilo: int = 0
var detalhe_variedade: Array[Dictionary] = []

# Rodadas INICIADAS no combate. Fonte única da contagem.
var rodadas: int = 0
var _ultima_posicao_iniciativa: int = -1

# Registro de variedade POR ALIADO enquanto o turno está aberto:
# nome -> {categoria: true}. A chave só existe entre iniciar_turno e finalizar_turno.
var _categorias_turno: Dictionary = {}
# Combatentes que já agiram na rodada atual.
var _agiram_na_rodada: Array[CombatenteData] = []


# ------------------------------------------------------------
# EFICIÊNCIA
# ------------------------------------------------------------
func registrar_dano_causado(quantidade: int) -> void:
	if quantidade > 0:
		dano_causado += quantidade


func registrar_cura(quantidade: int) -> void:
	if quantidade > 0:
		cura_efetiva += quantidade


func registrar_dano_recebido(quantidade: int) -> void:
	if quantidade > 0:
		dano_recebido += quantidade


func registrar_desmaio() -> void:
	aliados_desmaiados += 1


func registrar_reanimacao() -> void:
	aliados_reanimados += 1


func bonus_recuperacao() -> int:
	return BONUS_REANIMACAO * aliados_reanimados

# ------------------------------------------------------------
# PONTUAÇÃO
# ------------------------------------------------------------
# ------------------------------------------------------------
# RODADAS
# Chamada SOMENTE quando o cursor da iniciativa avança para o
# próximo combatente (CombatManager._avancar_turno). "posicao" é
# a posição fixa do combatente na ordem inicial, que não muda
# com remoções. Nova rodada = o cursor deu a volta (posição menor
# ou igual à anterior). Uma ativação extra do mesmo combatente
# não chama esta função e, portanto, não conta rodada.
# ------------------------------------------------------------
func registrar_avanco_iniciativa(posicao: int) -> void:
	if posicao < 0:
		push_warning("[EstatisticasCombate] Combatente fora da ordem inicial: rodada não contada.")
		return
	if rodadas == 0 or posicao <= _ultima_posicao_iniciativa:
		rodadas += 1
	_ultima_posicao_iniciativa = posicao


# ------------------------------------------------------------
# TURNO E VARIEDADE
# Turno: aberto por iniciar_turno, fechado por finalizar_turno.
# Ação: registrar_acao, quantas vezes forem executadas no turno.
# ------------------------------------------------------------

# Abre o registro de variedade do aliado. Se já estiver aberto
# (ativação extra no mesmo turno), mantém o que já foi registrado.
func iniciar_turno(combatente: CombatenteData) -> void:
	if combatente == null or combatente.tipo == "inimigo":
		return
	if not _categorias_turno.has(combatente.nome):
		_categorias_turno[combatente.nome] = {}


# Registra uma ação REALMENTE executada. Devolve false (sem pontuar)
# se o combatente for inimigo, a categoria for inválida ou não houver
# turno aberto. Repetir a categoria no turno não soma de novo.
func registrar_acao(combatente: CombatenteData, categoria: String) -> bool:
	if combatente == null or combatente.tipo == "inimigo":
		return false
	if categoria not in CATEGORIAS_VALIDAS:
		push_warning("[EstatisticasCombate] Categoria inválida: %s" % categoria)
		return false
	if not _categorias_turno.has(combatente.nome):
		return false
	_categorias_turno[combatente.nome][categoria] = true
	return true


# Fecha o turno do aliado e converte as categorias em pontos, uma
# única vez: o registro é apagado aqui, então chamar de novo não
# gera pontos. Seguro mesmo se o turno nunca foi aberto.
func finalizar_turno(combatente: CombatenteData) -> void:
	if combatente == null or combatente.tipo == "inimigo":
		return
	if not _categorias_turno.has(combatente.nome):
		return

	var usadas: Array = _categorias_turno[combatente.nome].keys()
	_categorias_turno.erase(combatente.nome)
	if usadas.is_empty():
		return

	var pontos: int = _pontos_variedade(usadas.size())
	pontos_estilo += pontos
	detalhe_variedade.append({
		"combatente": combatente.nome,
		"rodada": rodadas,
		"categorias": usadas,
		"pontos": pontos
	})


# Pontos da maior faixa que a quantidade de categorias alcança.
func _pontos_variedade(quantidade: int) -> int:
	var faixa: int = 0
	for chave in PONTOS_VARIEDADE:
		if int(chave) <= quantidade and int(chave) > faixa:
			faixa = int(chave)
	return int(PONTOS_VARIEDADE.get(faixa, 0))


# ------------------------------------------------------------
# PONTUAÇÃO
# ------------------------------------------------------------

# Eficiência + estilo. O bônus de recuperação já está aqui dentro.
func pontuacao_base() -> int:
	return (
		PONTUACAO_BASE
		+ dano_causado * PONTOS_POR_DANO
		+ cura_efetiva * PONTOS_POR_CURA
		- dano_recebido * PENALIDADE_POR_DANO_RECEBIDO
		- PENALIDADE_DESMAIO * aliados_desmaiados
		+ bonus_recuperacao()
		+ pontos_estilo
	)


# O multiplicador (só em vitória rápida) amplifica a base; o ajuste do
# resultado é somado DEPOIS, sem ser amplificado. Piso no fim.
func pontuacao(classificacao: ClassificacaoCombate = null, resultado: String = "") -> int:
	var multiplicador: float = 1.0
	var ajuste: int = 0
	if classificacao != null:
		multiplicador = classificacao.multiplicador_por_rodadas(resultado, rodadas)
		ajuste = classificacao.ajuste_por_resultado(resultado)
	return maxi(
		PONTUACAO_MINIMA,
		roundi(float(pontuacao_base()) * multiplicador) + ajuste
	)


# Contrato de dados da tela de resultados. Os campos existentes
# mantêm nome e significado; os novos só acrescentam.
func montar_resultado(classificacao: ClassificacaoCombate, resultado: String = "") -> Dictionary:
	var multiplicador: float = classificacao.multiplicador_por_rodadas(resultado, rodadas)
	var ajuste: int = classificacao.ajuste_por_resultado(resultado)
	var pontos: int = pontuacao(classificacao, resultado)
	var rank: Dictionary = classificacao.classificar(pontos)
	return {
		"dano_causado": dano_causado,
		"contribuicao_dano": dano_causado * PONTOS_POR_DANO,
		"cura_efetiva": cura_efetiva,
		"contribuicao_cura": cura_efetiva * PONTOS_POR_CURA,
		"dano_recebido": dano_recebido,
		"penalidade_dano_recebido": dano_recebido * PENALIDADE_POR_DANO_RECEBIDO,
		"aliados_desmaiados": aliados_desmaiados,
		"penalidade_desmaios": PENALIDADE_DESMAIO * aliados_desmaiados,
		"aliados_reanimados": aliados_reanimados,
		"bonus_recuperacao": bonus_recuperacao(),
		"pontuacao_estilo": pontos_estilo,
		"detalhe_variedade": detalhe_variedade.duplicate(true),
		"pontuacao_base": pontuacao_base(),
		"rodadas": rodadas,
		"multiplicador_rodadas": multiplicador,
		"ajuste_resultado": ajuste,
		"pontuacao": pontos,
		"rank": rank["letra"],
		"nome_classificacao": rank["nome"],
		"rank_pendente": rank["pendente"]
	}
