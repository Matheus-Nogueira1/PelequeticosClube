
extends Node
class_name CombatenteAnimation

@export var sprite_path: NodePath

const ANIMACAO_ATAQUE: StringName = &"Atacando"
const ANIMACAO_ESQUIVA: StringName = &"Dodge"
const ANIMACAO_DANO: StringName = &"Hit"
const ANIMACAO_MORTE: StringName = &"Morrendo"
var sprite: AnimatedSprite2D
var morto: bool = false
var animacao_idle: StringName = &""

func configurar(sprite_animado: AnimatedSprite2D) -> void:
	sprite = sprite_animado

	if sprite == null:
		push_error("[CombatantAnimation] AnimatedSprite2D não foi encontrado.")
		return

	if sprite.sprite_frames == null:
		push_error("[CombatantAnimation] SpriteFrames não configurado.")
		return

	# Usa a animação inicial configurada no próprio AnimatedSprite2D.
	animacao_idle = sprite.animation

	if not sprite.sprite_frames.has_animation(animacao_idle):
		push_error(
			"[CombatenteAnimation] Animação inicial inválida: %s"
			% String(animacao_idle)
		)
		return

	_definir_idle()

func _definir_idle() -> void:
	if sprite == null or not is_instance_valid(sprite):
		return

	if animacao_idle.is_empty():
		return

	if not sprite.sprite_frames.has_animation(animacao_idle):
		return

	sprite.stop()
	sprite.animation = animacao_idle
	sprite.frame = 0

func _tocar_e_retornar_idle(nome: StringName) -> void:
	if sprite == null or morto:
		return

	if not sprite.sprite_frames.has_animation(nome):
		push_warning(
			"[CombatenteAnimation] Animação inexistente: %s" % String(nome)
		)
		return

	var loop_anterior: bool = sprite.sprite_frames.get_animation_loop(nome)

	# Garante que a animação termine e emita animation_finished.
	sprite.sprite_frames.set_animation_loop(nome, false)
	sprite.play(nome)

	await sprite.animation_finished

	# Restaura a configuração original da animação.
	if is_instance_valid(sprite):
		sprite.sprite_frames.set_animation_loop(nome, loop_anterior)

		# Não interrompe uma animação de morte ou outra animação
		# que tenha substituído a atual.
		if not morto and sprite.animation == nome:
			_definir_idle()

func tocar_animacao(nome: StringName) -> void:
	await _tocar_e_retornar_idle(nome)


func tocar_ataque() -> void:
	await _tocar_e_retornar_idle(ANIMACAO_ATAQUE)


func tocar_esquiva() -> void:
	await _tocar_e_retornar_idle(ANIMACAO_ESQUIVA)

func tocar_dano() -> void:
	await _tocar_e_retornar_idle(ANIMACAO_DANO)

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
