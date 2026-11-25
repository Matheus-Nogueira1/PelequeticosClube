extends RefCounted
class_name FaseInimigo

# ============================================================
# FASES DE UM INIMIGO DE DOIS ESTÁGIOS (ex.: o espantalho)
#   PASSIVA  -> só passa o turno; ao "morrer" pela 1ª vez, a morte é
#              revertida e a fase vira AGRESSIVA (uma única vez).
#   AGRESSIVA -> usa a IA ofensiva; a próxima morte é definitiva.
# O estado vive no próprio CombatenteData (fase_ia, dois_estagios).
# O CombatManager só consulta estas funções.
# ============================================================

const PASSIVA: String = "passiva"
const AGRESSIVA: String = "agressiva"

# Fração do Estresse removida na transição (1.0 = zera tudo).
# REGRA NÃO DEFINIDA: ajuste aqui.
const FRACAO_RECUPERADA: float = 1.0


static func pode_atacar(c: CombatenteData) -> bool:
	return not c.dois_estagios or c.fase_ia == AGRESSIVA


static func deve_transicionar(c: CombatenteData) -> bool:
	return c.dois_estagios and c.fase_ia == PASSIVA


# Reverte a "morte", recupera Estresse e passa para a fase agressiva.
# Só mexe no Estresse e nos flags de morte; os atributos ficam intactos.
static func transicionar(c: CombatenteData) -> void:
	c.fase_ia = AGRESSIVA
	c.morto = false
	c.desmaiado = false
	for regiao in c.estresse_por_regiao:
		var dados: Dictionary = c.estresse_por_regiao[regiao]
		dados["atual"] = int(round(float(dados["atual"]) * (1.0 - FRACAO_RECUPERADA)))
	c.reducao_protecao_temporaria = 0
	c.atacante_que_quebrou_protecao = ""
