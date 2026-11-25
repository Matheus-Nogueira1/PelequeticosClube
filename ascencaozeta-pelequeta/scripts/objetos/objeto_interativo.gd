extends Area2D
class_name ObjetoInterativo

# ============================================================
# OBJETO INTERATIVO DA CABANA (cama, escada...)
# Mesmo padrão do NPCController: área de interação + ação "interact".
#   DIALOGO  -> mostra dialogo_id (e a animação "Levantar", se ligada).
#   FIM_DEMO -> diálogo opcional, fade para preto, "Continua..." e fim.
# ============================================================

enum Tipo { DIALOGO, FIM_DEMO }

@export var tipo: Tipo = Tipo.DIALOGO
@export var dialogo_id: String = ""
@export var tocar_levantar: bool = false
# FIM_DEMO: arraste o ColorRect "Preto" (com o Label "Continua...").
@export var tela_fim: Control
@export var duracao_fade: float = 1.5

var _jogador: Node2D = null
var _ocupado: bool = false


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)
	if tela_fim == null:
		var mapa := get_tree().current_scene
		if mapa != null:
			tela_fim = mapa.get_node_or_null("FimDemo/Preto") as Control

	if tela_fim == null:
		push_error("[ObjetoInterativo] Tela final não configurada na escada.")
		return

	tela_fim.visible = true
	tela_fim.modulate.a = 0.0

	var fade := create_tween()
	fade.tween_property(tela_fim, "modulate:a", 1.0, duracao_fade)
	await fade.finished


func _ao_entrar(body: Node2D) -> void:
	if not body.is_in_group("player") or Global.demo_encerrada:
		return
	_jogador = body
	var caixa := _caixa()
	if caixa != null and not _ocupado:
		caixa.mostrar_dica_interacao()


func _ao_sair(body: Node2D) -> void:
	if body != _jogador:
		return
	_jogador = null
	var caixa := _caixa()
	if caixa != null and not _ocupado:
		caixa.ocultar_dica_interacao()


func _unhandled_input(event: InputEvent) -> void:
	if _jogador == null or _ocupado or Global.demo_encerrada:
		return
	if not event.is_action_pressed("interact"):
		return
	var caixa := _caixa()
	if caixa == null or caixa.ativo:
		return
	get_viewport().set_input_as_handled()
	_ocupado = true
	caixa.ocultar_dica_interacao()

	if tipo == Tipo.FIM_DEMO:
		await _encerrar_demo(caixa)
		return

	await _mostrar_dialogo(caixa)
	if tocar_levantar:
		await _animar_levantar()
	_ocupado = false
	if _jogador != null:
		caixa.mostrar_dica_interacao()


func _mostrar_dialogo(caixa: Node) -> void:
	if dialogo_id.is_empty() or Dialogos.get_conversa(dialogo_id).is_empty():
		return
	caixa.iniciar_dialogo_npc(GrupoAtual.obter_personagem_principal(), dialogo_id, self)
	await caixa.dialogo_encerrado


# Reaproveita a animação "Levantar" do Escolhido (a mesma da introdução).
func _animar_levantar() -> void:
	if _jogador == null:
		return
	var walk := _jogador.get_node_or_null("Walk") as AnimatedSprite2D
	var levantar := _jogador.get_node_or_null("Levantar") as AnimatedSprite2D
	if walk == null or levantar == null:
		return
	_jogador.call("travar", true)
	levantar.sprite_frames.set_animation_loop("Levantar", false)
	levantar.position = walk.position
	levantar.offset = walk.offset
	levantar.flip_h = walk.flip_h
	walk.visible = false
	levantar.visible = true
	levantar.play("Levantar")
	await levantar.animation_finished
	levantar.visible = false
	walk.visible = true
	_jogador.call("travar", false)

func _encerrar_demo(caixa: Node) -> void:
	# A música começa no momento em que o jogador interage com a escada.
	AudioManager.tocar_musica(&"ciclo")

	# Primeiro apresenta o diálogo da escada.
	await _mostrar_dialogo(caixa)

	# Evita encerrar sem uma tela final válida.
	if tela_fim == null or not is_instance_valid(tela_fim):
		push_error("[ObjetoInterativo] Não foi possível exibir a tela final.")
		_ocupado = false
		return

	# A partir daqui não há volta.
	Global.demo_encerrada = true

	if _jogador != null:
		_jogador.call("travar", true)

	tela_fim.visible = true
	tela_fim.modulate.a = 0.0

	var fade := create_tween()
	fade.set_trans(Tween.TRANS_SINE)
	fade.set_ease(Tween.EASE_IN_OUT)
	fade.tween_property(
		tela_fim,
		"modulate:a",
		1.0,
		duracao_fade
	)

	await fade.finished

func _caixa() -> Node:
	for caixa in get_tree().get_nodes_in_group("dialogue_box"):
		if is_instance_valid(caixa):
			return caixa
	return null
