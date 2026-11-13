extends CharacterBody2D
class_name DummyController

@export var cena_combate: String = "res://scenes/battle/combat.tscn"
@export var caminho_area_interacao: NodePath = ^"InteractionArea"
@export var zoom_alvo: float = 2.5
@export var duracao_zoom: float = 0.6
@export var duracao_flash: float = 0.15


var combate_iniciado: bool = false

@onready var area_interacao: Area2D = get_node_or_null(
	caminho_area_interacao
) as Area2D
@onready var flash: ColorRect = get_node_or_null("EfeitoEncontro/Flash") as ColorRect

func _ready() -> void:
	if area_interacao == null:
		push_error("[Dummy] InteractionArea não encontrada.")
		return

	area_interacao.body_entered.connect(_ao_jogador_entrar)


func _ao_jogador_entrar(body: Node2D) -> void:
	if combate_iniciado or not body.is_in_group("player"):
		return

	if GrupoAtual.obter_personagem_principal() == null:
		push_error("[Dummy] Nenhum personagem principal foi selecionado.")
		return

	combate_iniciado = true
	if body.has_method("travar"):
		body.travar(true)

	await _efeito_encontro()

	var erro := get_tree().change_scene_to_file(cena_combate)
	if erro != OK:
		combate_iniciado = false
		if body.has_method("travar"):
			body.travar(false)
		push_error(
			"[Dummy] Não foi possível abrir a cena de combate. Erro: %s"
			% erro
		)


# Flash branco e zoom da câmera ao encostar no inimigo.
func _efeito_encontro() -> void:
	# Pulso inicial de flash (não bloqueia o zoom).
	if flash != null:
		flash.visible = true
		flash.modulate.a = 0.0
		var pulso := create_tween()
		pulso.tween_property(flash, "modulate:a", 0.9, 0.06)
		pulso.tween_property(flash, "modulate:a", 0.0, 0.25)

	var camera := get_viewport().get_camera_2d()
	if camera != null:
		var zoom := create_tween()
		zoom.set_trans(Tween.TRANS_EXPO)
		zoom.set_ease(Tween.EASE_OUT)
		zoom.tween_property(camera, "zoom", camera.zoom * zoom_alvo, duracao_zoom)
		await zoom.finished
	else:
		await get_tree().create_timer(duracao_zoom).timeout

	# Flash final cobre a troca de cena.
	if flash != null:
		var fim := create_tween()
		fim.tween_property(flash, "modulate:a", 1.0, duracao_flash)
		await fim.finished
