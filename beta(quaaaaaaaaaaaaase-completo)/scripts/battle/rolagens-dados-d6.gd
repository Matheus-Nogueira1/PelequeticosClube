extends CharacterBody2D
class_name RolagemD6
@onready var dado_sprite: AnimatedSprite2D = $AnimatedSprite2D

const ZONA_ACERTO_EXTREMO = 6
const ZONA_ACERTO_REGULAR = 4
const REGIOES_CORPO = ["Torso", "Braço Esquerdo", "Braço Direito", "Perna Esquerda", "Perna Direita"]
signal rolagem_confirmada

## Ajustes do pulo (mexa nestes valores para sentir o dado do seu jeito)
const PULOS: int = 3
const ALTURA_PULO: float = 16.0
const DURACAO_PULO: float = 0.3
const VELOCIDADE_GIRO: float = 10.0

@onready var label_rolar: Label = get_node_or_null("LabelRolar") as Label
var aguardando_confirmacao: bool = false

func _ready():
	randomize()

	if label_rolar != null:
		label_rolar.hide()

	# A animação "rolar" não repete e é mais curta que os pulos: deixa em loop.
	if dado_sprite != null and dado_sprite.sprite_frames != null:
		dado_sprite.sprite_frames.set_animation_loop("rolar", true)
		dado_sprite.sprite_frames.set_animation_speed("rolar", VELOCIDADE_GIRO)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		print("clicou no dado")
	#	rolar_dado()

#func rolar_dado():
	##var resultado = rolar_teste_conhecimento_d6(false)
	#await rodar_e_mostrar_face(resultado.dado)
	#print("Resultado Conhecimento:", resultado)

	#var resultado_especial = rolar_teste_conhecimento_d6(true)
	#print("Conhecimento Especializado:", resultado_especial)

	#var regioes = ["Torso", "Braço Direito", "Perna Esquerda"]
	#var resultado_combate = rolar_teste_combate_d6(regioes, 3, 2, 1)
	#print("Combate:", resultado_combate)

func aguardar_confirmacao() -> void:
	# Mostra o dado parado e espera o jogador apertar ENTER ou E.
	if dado_sprite != null:
		dado_sprite.stop()
		dado_sprite.animation = "rolar"
		dado_sprite.frame = 0

	if label_rolar != null:
		label_rolar.show()

	aguardando_confirmacao = true
	await rolagem_confirmada

	if label_rolar != null:
		label_rolar.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not aguardando_confirmacao:
		return

	if event.is_action_pressed("ui_accept"):
		aguardando_confirmacao = false
		get_viewport().set_input_as_handled()
		rolagem_confirmada.emit()


func rodar_e_mostrar_face(lado: int) -> void:
	if dado_sprite == null:
		push_error("AnimatedSprite2D não foi encontrado no dado.")
		return

	lado = clampi(lado, 1, 6)

	var posicao_base: Vector2 = dado_sprite.position
	var escala_base: Vector2 = dado_sprite.scale

	dado_sprite.stop()
	dado_sprite.animation = "rolar"
	dado_sprite.frame = 0
	dado_sprite.play()

	# Cada pulo é menor que o anterior, e o dado achata ao tocar o chão.
	for i in range(PULOS):
		var altura: float = ALTURA_PULO / float(i + 1)
		var tween: Tween = create_tween()

		tween.tween_property(
			dado_sprite, "position:y", posicao_base.y - altura, DURACAO_PULO / 2.0
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		tween.tween_property(
			dado_sprite, "position:y", posicao_base.y, DURACAO_PULO / 2.0
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		tween.tween_property(
			dado_sprite, "scale", Vector2(escala_base.x * 1.15, escala_base.y * 0.85), 0.04
		)
		tween.tween_property(dado_sprite, "scale", escala_base, 0.06)

		await tween.finished

	dado_sprite.position = posicao_base
	dado_sprite.scale = escala_base
	dado_sprite.stop()
	dado_sprite.animation = "default"
	dado_sprite.frame = lado - 1

func rolar_teste_conhecimento_d6(
	combatente: CombatenteData,
	conhecimento: String
) -> Dictionary:
	if combatente == null:
		push_error("Não foi fornecido um CombatenteData para o teste.")
		return {}

	var dado: int = randi_range(1, 6)
	var especializado: bool = combatente.conhecimentos_especializados.has(conhecimento)
	var bonus_especializacao: int = 2 if especializado else 0
	var bonus_total: int = combatente.calcular_bonus_conhecimento(conhecimento)
	var bonus_treinamento: int = bonus_total - bonus_especializacao
	var total: int = dado + bonus_total
	var categoria: String

	if dado == 1:
		categoria = "Falha Crítica"
	else:
		categoria = avaliar_resultado_d6(total)

	return {
		"tipo": "Conhecimento D6",
		"conhecimento": conhecimento,
		"especializado": especializado,
		"dado": dado,
		"bonus_especializacao": bonus_especializacao,
		"bonus_treinamento": bonus_treinamento,
		"bonus_total": bonus_total,
		"total": total,
		"categoria": categoria,	
		"sucesso": categoria in ["Sucesso Regular", "Sucesso Extremo"],
		"falha": categoria in ["Falha Regular", "Falha Crítica"]
	}

func rolar_teste_combate_d6(regioes_arriscadas: Array, protecao_alvo: int, dano_arma: int, atributo_dano: int) -> Dictionary:
	var quantidade = clamp(regioes_arriscadas.size(), 1, 5)
	regioes_arriscadas = regioes_arriscadas.slice(0, quantidade)

	var resultados = []
	var sucessos_regulares = 0
	var sucessos_extremos = 0
	var falhas_regulares = 0
	var falhas_criticas = 0
	var estresse_gerado = 0

	for regiao in regioes_arriscadas:
		var dado = randi_range(1, 6)
		var categoria = avaliar_resultado_d6(dado)
		var acertos = 0

		if categoria == "Sucesso Extremo":
			acertos = 2
			sucessos_extremos += 1
		elif categoria == "Sucesso Regular":
			acertos = 1
			sucessos_regulares += 1
		elif categoria == "Falha Crítica":
			falhas_criticas += 1
			estresse_gerado += 2
		else:
			falhas_regulares += 1
			estresse_gerado += 1

		resultados.append({
			"regiao": regiao,
			"dado": dado,
			"categoria": categoria,
			"acertos": acertos
		})

	var total_sucessos = sucessos_regulares + (sucessos_extremos * 2)
	var dano_aplicado = 0
	var protecao_temporaria = max(protecao_alvo - total_sucessos, 0)
	var dano_causado = false

	if total_sucessos >= protecao_alvo:
		dano_aplicado = dano_arma + atributo_dano
		dano_causado = true
		protecao_temporaria = 0

	return {
		"tipo": "Combate D6",
		"regioes_arriscadas": regioes_arriscadas,
		"resultados_por_regiao": resultados,
		"sucessos_regulares": sucessos_regulares,
		"sucessos_extremos": sucessos_extremos,
		"falhas_regulares": falhas_regulares,
		"falhas_criticas": falhas_criticas,
		"total_sucessos": total_sucessos,
		"estresse_gerado": estresse_gerado,
		"protecao_alvo": protecao_alvo,
		"protecao_temporaria": protecao_temporaria,
		"dano_aplicado": dano_aplicado,
		"dano_causado": dano_causado
	}

static func avaliar_resultado_d6(valor: int) -> String:
	if valor >= 6:
		return "Sucesso Extremo"
	elif valor >= 4:
		return "Sucesso Regular"
	elif valor == 1:
		return "Falha Crítica"
	else:
		return "Falha Regular"

static func calcular_teste_conhecimento(
	combatente: CombatenteData,
	conhecimento: String
) -> Dictionary:
	if combatente == null:
		push_error("Não foi fornecido um CombatenteData para o teste.")
		return {}

	if not combatente.conhecimentos_especializados.has(conhecimento):
		push_warning("O personagem não possui a especialização: " + conhecimento)
		return {}

	var dado: int = randi_range(1, 6)
	var bonus_especializacao: int = 2
	var bonus_total: int = combatente.calcular_bonus_conhecimento(conhecimento)
	var bonus_treinamento: int = bonus_total - bonus_especializacao
	var total: int = dado + bonus_total
	var categoria: String

	if dado == 1:
		categoria = "Falha Crítica"
	else:
		categoria = avaliar_resultado_d6(total)

	return {
		"tipo": "Conhecimento D6",
		"conhecimento": conhecimento,
		"especializado": true,
		"dado": dado,
		"bonus_especializacao": bonus_especializacao,
		"bonus_treinamento": bonus_treinamento,
		"bonus_total": bonus_total,
		"total": total,
		"categoria": categoria,
		"sucesso": categoria in ["Sucesso Regular", "Sucesso Extremo"],
		"falha": categoria in ["Falha Regular", "Falha Crítica"]
	}
