extends RefCounted
class_name DestaqueTurno

# ============================================================
# DESTAQUE DO CARD DO COMBATENTE ATIVO
# Usado por PartyPanel e EnemyPanel. Troca o estilo "panel" do card
# pelo estilo de destaque e devolve o estilo ORIGINAL ao remover
# (se o card já tinha um override na cena, ele não se perde).
# A transição é um fade curto do próprio estilo (self_modulate afeta
# só o desenho do painel, não os textos do card).
# Para desligar a animação, ponha DURACAO_FADE em 0.
# ============================================================

const DURACAO_FADE: float = 0.15
const META_ATIVO: StringName = &"destaque_turno_ativo"
const META_ORIGINAL: StringName = &"destaque_turno_original"
const META_TWEEN: StringName = &"destaque_turno_tween"


static func aplicar(card: Control, estilo: StyleBox) -> void:
	if card == null or estilo == null:
		return
	# Já destacado: não reinicia a animação a cada atualização do painel.
	if bool(card.get_meta(META_ATIVO, false)):
		return
	card.set_meta(META_ATIVO, true)

	# Guarda o override original (null = o card usava o tema).
	if card.has_theme_stylebox_override("panel"):
		card.set_meta(META_ORIGINAL, card.get_theme_stylebox("panel"))
	card.add_theme_stylebox_override("panel", estilo)

	_cancelar_tween(card)
	if DURACAO_FADE <= 0.0:
		card.self_modulate = Color.WHITE
		return
	card.self_modulate = Color(1, 1, 1, 0)
	var tween: Tween = card.create_tween()
	tween.tween_property(card, "self_modulate", Color.WHITE, DURACAO_FADE)
	card.set_meta(META_TWEEN, tween)


static func remover(card: Control) -> void:
	if card == null:
		return
	_cancelar_tween(card)
	card.self_modulate = Color.WHITE
	if not bool(card.get_meta(META_ATIVO, false)):
		return
	card.set_meta(META_ATIVO, false)

	var original: Variant = card.get_meta(META_ORIGINAL, null)
	if original is StyleBox:
		card.add_theme_stylebox_override("panel", original)
	else:
		card.remove_theme_stylebox_override("panel")
	if card.has_meta(META_ORIGINAL):
		card.remove_meta(META_ORIGINAL)


static func _cancelar_tween(card: Control) -> void:
	var tween: Variant = card.get_meta(META_TWEEN, null)
	if tween is Tween and (tween as Tween).is_valid():
		(tween as Tween).kill()
	if card.has_meta(META_TWEEN):
		card.remove_meta(META_TWEEN)
