
extends CharacterBody2D
class_name NPCController

## Identificação do NPC
@export var npc_id: String = "Elizabeth"
@export var mapa_id: String = "mapa_principal"

## Identificador existente em Dialogos.CONVERSAS
@export var dialogo_id: String = "Elizabeth"

## Caminho da área que detecta o jogador
@export var caminho_area_interacao: NodePath = ^"InteractionArea"

var jogador_proximo: bool = false
var dialogo_em_andamento: bool = false
var jogador_atual: Node2D = null
@export var caminho_dica_interacao: NodePath = "CaixaDialogo/PanelContainer/MarginContainer/Panel/VBoxContainer/DicaLabel"

@onready var dica_interacao: Label = get_node_or_null(
	caminho_dica_interacao
) as Label

@onready var area_interacao: Area2D = get_node_or_null(
	caminho_area_interacao
) as Area2D


func _ready() -> void:
	add_to_group("npcs")

	if area_interacao == null:
		push_error(
			"NPC '%s': InteractionArea não encontrada." % npc_id
		)
		return

	area_interacao.body_entered.connect(_ao_jogador_entrar)
	area_interacao.body_exited.connect(_ao_jogador_sair)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	if not jogador_proximo:
		return

	if dialogo_em_andamento:
		return

	if dialogo_id.is_empty():
		push_warning(
			"NPC '%s' não possui um dialogo_id configurado." % npc_id
		)
		return

	var caixa := _obter_caixa_dialogo()

	if caixa == null:
		push_error(
			"NPC '%s': não foi encontrada uma CaixaDialogo." % npc_id
		)
		return

	if caixa.ativo:
		return

	var personagem: CombatenteData = (
		GrupoAtual.obter_personagem_principal()
	)

	if personagem == null:
		push_error(
			"NPC '%s': nenhum personagem principal foi definido." % npc_id
		)
		return

	dialogo_em_andamento = true
	caixa.ocultar_dica_interacao()

	caixa.iniciar_dialogo_npc(
		personagem,
		dialogo_id,
		self
	)

	get_viewport().set_input_as_handled()
	await caixa.dialogo_encerrado

	dialogo_em_andamento = false

	if jogador_proximo:
		caixa.mostrar_dica_interacao()


func _ao_jogador_entrar(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	jogador_atual = body
	jogador_proximo = true

	if dialogo_em_andamento:
		return

	var caixa := _obter_caixa_dialogo()

	if caixa != null:
		caixa.mostrar_dica_interacao()


func _ao_jogador_sair(body: Node2D) -> void:
	if body != jogador_atual:
		return

	jogador_atual = null
	jogador_proximo = false

	var caixa := _obter_caixa_dialogo()

	if caixa != null:
		caixa.ocultar_dica_interacao()

func _obter_caixa_dialogo() -> Node:
	var caixas := get_tree().get_nodes_in_group("dialogue_box")

	for caixa in caixas:
		if is_instance_valid(caixa):
			return caixa

	return null
