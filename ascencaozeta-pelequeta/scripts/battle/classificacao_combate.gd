extends RefCounted
class_name ClassificacaoCombate

# ============================================================
# CLASSIFICAÇÃO DE DESEMPENHO
# Ordem oficial: C < B < A < S < SS < P (P é o máximo).
# ============================================================

# ------------------------------------------------------------
# CONFIGURAÇÃO: é aqui que você mexe nos valores
# ------------------------------------------------------------

# Enquanto for false, nenhum rank é atribuído (a tela mostra "?").
var limites_definidos: bool = true

# Pontuação mínima para alcançar cada rank (abaixo de B é C).
# Precisam estar em ordem crescente: B <= A <= S <= SS <= P.
var minimo_b: int = 1500
var minimo_a: int = 2000
var minimo_s: int = 3000
var minimo_ss: int = 4500
var minimo_p: int = 5000

# Ajuste somado à pontuação conforme o resultado do combate.
# Para a Derrota, use um valor NEGATIVO.
var ajuste_vitoria: int = 500
var ajuste_derrota: int = -1000
var ajuste_fuga: int = -500

# Multiplicador de pontuação para vitórias rápidas.
# Combates com rodadas iguais ou superiores à referência ficam em 1.0x.
var rodadas_referencia: int = 5
var bonus_por_rodada_antecipada: float = 0.5

# ------------------------------------------------------------
# Daqui para baixo não precisa mexer
# ------------------------------------------------------------

const NOMES: Dictionary = {
	"C": "Cadáver",
	"B": "Blasfêmia",
	"A": "Aniquilação",
	"S": "Sacrifício",
	"SS": "Super Sensual",
	"P": "Pelecomaníaco"
}


func ajuste_por_resultado(resultado: String) -> int:
	match resultado:
		"Vitória":
			return ajuste_vitoria
		"Derrota":
			return ajuste_derrota
		"Fuga":
			return ajuste_fuga
	return 0

func multiplicador_por_rodadas(resultado: String, rodadas: int) -> float:
	if resultado != "Vitória":
		return 1.0

	if rodadas_referencia <= 0 or rodadas >= rodadas_referencia:
		return 1.0

	var rodadas_economizadas: int = rodadas_referencia - rodadas
	return 1.0 + (
		float(rodadas_economizadas) * bonus_por_rodada_antecipada
	)

func classificar(pontuacao: int) -> Dictionary:
	if not limites_definidos:
		return {"letra": "", "nome": "", "pendente": true}

	if not (minimo_b <= minimo_a and minimo_a <= minimo_s
			and minimo_s <= minimo_ss and minimo_ss <= minimo_p):
		push_warning("[ClassificacaoCombate] Limites fora de ordem crescente: classificação pendente.")
		return {"letra": "", "nome": "", "pendente": true}

	var letra: String = "C"
	if pontuacao >= minimo_p:
		letra = "P"
	elif pontuacao >= minimo_ss:
		letra = "SS"
	elif pontuacao >= minimo_s:
		letra = "S"
	elif pontuacao >= minimo_a:
		letra = "A"
	elif pontuacao >= minimo_b:
		letra = "B"

	return {"letra": letra, "nome": NOMES[letra], "pendente": false}
