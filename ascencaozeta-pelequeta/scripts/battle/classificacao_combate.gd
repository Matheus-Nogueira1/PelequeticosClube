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
var limites_definidos: bool = false

# Pontuação mínima para alcançar cada rank (abaixo de B é C).
# Precisam estar em ordem crescente: B <= A <= S <= SS <= P.
var minimo_b: int = 0
var minimo_a: int = 0
var minimo_s: int = 0
var minimo_ss: int = 0
var minimo_p: int = 0

# Ajuste somado à pontuação conforme o resultado do combate.
# Para a Derrota, use um valor NEGATIVO.
var ajuste_vitoria: int = 0
var ajuste_derrota: int = 0
var ajuste_fuga: int = 0

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
