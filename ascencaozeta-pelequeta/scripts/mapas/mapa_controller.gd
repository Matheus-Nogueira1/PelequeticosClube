
extends Node2D
class_name MapaController

@export var nome_mapa: String = "Cabana"
@export var executar_introducao: bool = true

@onready var jogador: CharacterBody2D = get_node_or_null("Escolhido") as CharacterBody2D
@onready var caixa_dialogo: Control = get_node_or_null("Escolhido/Camera2D/CanvasLayer/CaixaDialogo") as Control
@onready var dado: Node = get_node_or_null("Dado")

var mapa_inicializado: bool = false
var introducao_em_andamento: bool = false


func _ready() -> void:
	inicializar_mapa()

	if mapa_inicializado and executar_introducao:
		await executar_introducao_firekeeper()


func inicializar_mapa() -> void:
	if jogador == null:
		push_error(
			"Mapa %s: não foi encontrada a instância Escolhido."
			% nome_mapa
		)
		return

	jogador.add_to_group("player")

	if caixa_dialogo == null:
		push_warning(
			"Mapa %s: CaixaDialogo não foi encontrada. Confira o caminho do nó."
			% nome_mapa
		)
	else:
		caixa_dialogo.add_to_group("dialogue_box")

	if dado == null:
		push_warning(
			"Mapa %s: Dado não foi encontrado."
			% nome_mapa
		)
	else:
		var colisao_dado := dado.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if colisao_dado != null:
			colisao_dado.disabled = true

		if dado is CanvasItem:
			(dado as CanvasItem).visible = false

	mapa_inicializado = true
	print("Mapa inicializado: ", nome_mapa)


func executar_introducao_firekeeper() -> void:
	if introducao_em_andamento:
		return

	var walk := jogador.get_node_or_null("Walk") as AnimatedSprite2D
	var levantar := jogador.get_node_or_null("Levantar") as AnimatedSprite2D
	var black_screen := get_node_or_null("CanvasLayer/BlackScreen") as ColorRect

	if walk == null:
		push_error("Introdução: nó Walk não encontrado no jogador.")
		return

	if levantar == null:
		push_error("Introdução: nó Levantar não encontrado no jogador.")
		return

	if black_screen == null:
		push_error("Introdução: nó CanvasLayer/BlackScreen não encontrado.")
		return

	introducao_em_andamento = true

	print("Firekeeper: iniciando introdução")

	# Mantém a tela preta e bloqueia o movimento.
	black_screen.visible = true
	black_screen.color = Color.BLACK
	black_screen.modulate.a = 1.0

	jogador.set("pode_andar", false)
	jogador.velocity = Vector2.ZERO
	jogador.set_physics_process(true)

	walk.visible = false

	levantar.stop()
	levantar.visible = false
	levantar.sprite_frames.set_animation_loop("Levantar", false)
	levantar.speed_scale = 1.0

	await get_tree().create_timer(0.3).timeout

	if not is_instance_valid(jogador):
		return

	# Alinha a animação ao sprite normal.
	levantar.position = walk.position
	levantar.offset = walk.offset
	levantar.flip_h = walk.flip_h
	levantar.rotation = walk.rotation
	levantar.scale = walk.scale

	levantar.visible = true
	levantar.play("Levantar")

	print("Firekeeper: personagem levantando")

	# Clareia a tela gradualmente.
	var fade := create_tween()
	fade.set_trans(Tween.TRANS_SINE)
	fade.set_ease(Tween.EASE_IN_OUT)
	fade.tween_property(black_screen, "modulate:a", 0.0, 1.2)

	# Aguarda a animação terminar.
	await levantar.animation_finished

	print("Firekeeper: animação concluída")

	await get_tree().create_timer(1.3).timeout

	# Retorna ao sprite normal.
	levantar.stop()
	levantar.visible = false

	walk.visible = true
	walk.play("walk_down")

	jogador.velocity = Vector2.ZERO
	jogador.set_physics_process(true)
	jogador.set("pode_andar", true)

	black_screen.visible = false
	introducao_em_andamento = false

	print("Firekeeper: jogador liberado!")


func obter_jogador() -> CharacterBody2D:
	return jogador


func obter_caixa_dialogo() -> Control:
	return caixa_dialogo


func jogador_pode_interagir() -> bool:
	if jogador == null or not is_instance_valid(jogador):
		return false

	if caixa_dialogo == null or not is_instance_valid(caixa_dialogo):
		return false

	return true
