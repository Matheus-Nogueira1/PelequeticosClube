
extends Node2D
class_name MapaController

@export var nome_mapa: String = "Firekeeper"

@onready var jogador: CharacterBody2D = get_node_or_null("Escolhido") as CharacterBody2D
@onready var caixa_dialogo: Control = get_node_or_null("CaixaDialogo") as Control
@onready var dado: Node = get_node_or_null("Dado")

var mapa_inicializado: bool = false


func _ready() -> void:
	inicializar_mapa()


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
			"Mapa %s: CaixaDialogo não foi encontrada."
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
		# O dado só aparece durante testes e não pode bloquear o jogador.
		var colisao_dado := dado.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if colisao_dado != null:
			colisao_dado.disabled = true
		(dado as CanvasItem).visible = false
	mapa_inicializado = true
	print("Mapa inicializado: ", nome_mapa)


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
