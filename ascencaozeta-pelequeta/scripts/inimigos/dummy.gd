extends CharacterBody2D
class_name DummyController

@export var cena_combate: String = "res://scenes/battle/combat.tscn"
@export var caminho_area_interacao: NodePath = ^"InteractionArea"

var jogador_proximo: bool = false
var combate_iniciado: bool = false

@onready var area_interacao: Area2D = get_node_or_null(
	caminho_area_interacao
) as Area2D


func _ready() -> void:
	if area_interacao == null:
		push_error("[Dummy] InteractionArea não encontrada.")
		return

	area_interacao.body_entered.connect(_ao_jogador_entrar)
	area_interacao.body_exited.connect(_ao_jogador_sair)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	if not jogador_proximo or combate_iniciado:
		return

	if GrupoAtual.obter_personagem_principal() == null:
		push_error("[Dummy] Nenhum personagem principal foi selecionado.")
		return

	combate_iniciado = true
	get_viewport().set_input_as_handled()

	var erro := get_tree().change_scene_to_file(cena_combate)

	if erro != OK:
		combate_iniciado = false
		push_error(
			"[Dummy] Não foi possível abrir a cena de combate. Erro: %s"
			% erro
		)


func _ao_jogador_entrar(body: Node2D) -> void:
	if body.is_in_group("player"):
		jogador_proximo = true
		print("[Dummy] Jogador próximo. Pressione Enter para iniciar o combate.")


func _ao_jogador_sair(body: Node2D) -> void:
	if body.is_in_group("player"):
		jogador_proximo = false
