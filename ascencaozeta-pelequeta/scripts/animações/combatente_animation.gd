
extends Node
class_name CombatenteAnimation

@export var sprite_path: NodePath

const ANIMACAO_ATAQUE: StringName = &"Atacando"
const ANIMACAO_ESQUIVA: StringName = &"Dodge"
const ANIMACAO_DANO: StringName = &"Hit"
const ANIMACAO_MORTE: StringName = &"Morrendo"

var sprite: AnimatedSprite2D
var morto: bool = false


func configurar(sprite_animado: AnimatedSprite2D) -> void:
	sprite = sprite_animado

	if sprite == null:
		push_error("[CombatantAnimation] AnimatedSprite2D não foi encontrado.")


func tocar_animacao(nome: StringName) -> void:
	if sprite == null or morto:
		return

	if not sprite.sprite_frames.has_animation(nome):
		push_warning(
			"[CombatantAnimation] Animação inexistente: %s" % String(nome)
		)
		return

	sprite.play(nome)


func tocar_ataque() -> void:
	if sprite == null or morto:
		return

	if not sprite.sprite_frames.has_animation(ANIMACAO_ATAQUE):
		push_warning(
			"[CombatantAnimation] Animação Atacando inexistente."
		)
		return

	# O ataque deve tocar apenas uma vez.
	sprite.sprite_frames.set_animation_loop(ANIMACAO_ATAQUE, false)
	sprite.play(ANIMACAO_ATAQUE)

	# Espera a animação terminar antes de continuar o combate.
	await sprite.animation_finished

	# Não interrompe uma animação de morte que tenha começado nesse intervalo.
	if not morto:
		sprite.stop()


func tocar_esquiva() -> void:
	tocar_animacao(ANIMACAO_ESQUIVA)


func tocar_dano() -> void:
	tocar_animacao(ANIMACAO_DANO)


func tocar_morte() -> void:
	if sprite == null or morto:
		return

	morto = true

	if not sprite.sprite_frames.has_animation(ANIMACAO_MORTE):
		push_warning("[CombatenteAnimation] Animação Morrendo inexistente.")
		return

	sprite.sprite_frames.set_animation_loop(ANIMACAO_MORTE, false)
	sprite.play(ANIMACAO_MORTE)
	await sprite.animation_finished
	sprite.pause()
