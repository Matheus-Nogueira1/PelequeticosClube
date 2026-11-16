extends RefCounted
class_name EstatisticasCombate

# ============================================================
# ESTATÍSTICAS DE UM COMBATE
# Acumuladas pelo CombatManager nos eventos reais (nunca pelo
# CombatLog). Um objeto novo por combate; a pontuação é
# calculada uma única vez, ao encerrar.
#   P = 1000 + Dc + Ce - Dr - 200*Ad + 250*Ar
# O bônus de recuperação (250*Ar) JÁ está na fórmula.
# ============================================================

# ------------------------------------------------------------
# CONFIGURAÇÃO
# ------------------------------------------------------------
const PONTUACAO_BASE: int = 1000
const PENALIDADE_DESMAIO: int = 200
const BONUS_REANIMACAO: int = 250
const PONTUACAO_MINIMA: int = 0
# O Estresse que o atacante sofre por falhar conta como dano recebido?
const CONTAR_ESTRESSE_DE_FALHA: bool = false

# ------------------------------------------------------------
# DADOS DO COMBATE
# ------------------------------------------------------------
var dano_causado: int = 0
var cura_efetiva: int = 0
var dano_recebido: int = 0
var aliados_desmaiados: int = 0
var aliados_reanimados: int = 0


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


# O bônus de recuperação já está dentro desta soma: não somar de novo.
# O ajuste do resultado é somado aqui, uma única vez, antes do piso.
func pontuacao(classificacao: ClassificacaoCombate = null, resultado: String = "") -> int:
	var total: int = (
		PONTUACAO_BASE
		+ dano_causado
		+ cura_efetiva
		- dano_recebido
		- PENALIDADE_DESMAIO * aliados_desmaiados
		+ bonus_recuperacao()
	)
	if classificacao != null:
		total += classificacao.ajuste_por_resultado(resultado)
	return maxi(PONTUACAO_MINIMA, total)


# Contrato de dados enviado à tela de resultados.
func montar_resultado(classificacao: ClassificacaoCombate, resultado: String = "") -> Dictionary:
	var pontos: int = pontuacao(classificacao, resultado)
	var rank: Dictionary = classificacao.classificar(pontos)
	return {
		"dano_causado": dano_causado,
		"cura_efetiva": cura_efetiva,
		"dano_recebido": dano_recebido,
		"aliados_desmaiados": aliados_desmaiados,
		"aliados_reanimados": aliados_reanimados,
		"bonus_recuperacao": bonus_recuperacao(),
		"pontuacao": pontos,
		"rank": rank["letra"],
		"nome_classificacao": rank["nome"],
		"rank_pendente": rank["pendente"]
	}
