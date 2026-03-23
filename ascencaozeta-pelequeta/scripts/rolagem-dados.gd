extends Node

func _ready():
	randomize()
	# Exemplo: Jogador rola 3 dados (Parada de Dados)
	var resultado = rolar_teste_oblivio(3)
	
	print("RESULTADO FINAL: ", resultado.total_acertos, " acertos!")
	print("Dados individuais: ", resultado.resumo_dados)

func rolar_teste_oblivio(quantidade: int) -> Dictionary:
	# Garante o limite de 1 a 5 dados do sistema
	quantidade = clamp(quantidade, 1, 5)
	
	var total_acertos = 0
	var lista_dados = []
	
	for i in range(quantidade):
		var dado = randi_range(1, 20)
		var acertos_deste_dado = 0
		
		# Lógica de faixas e peso dos acertos
		if dado == 20:
			acertos_deste_dado = 2 # Sucesso Extremo vale 2
		elif dado >= 13:
			acertos_deste_dado = 1 # Sucesso Regular vale 1
		elif dado == 1:
			acertos_deste_dado = 0 # Falha Extrema
		else:
			acertos_deste_dado = 0 # Falha Regular
			
		total_acertos += acertos_deste_dado
		lista_dados.append(dado)
		
	return {
		"total_acertos": total_acertos,
		"resumo_dados": lista_dados,
		"quantidade_rolada": quantidade
	}
