extends ScrollContainer
class_name ScrollTeclado

# Rolagem por teclado para conteúdo sem botões focáveis (textos).
# PageUp/PageDown rolam uma página; Home/End vão ao início/fim.
# Com rolar_com_setas, ↑/↓ rolam um passo (use só onde as setas
# não navegam o foco, como na tela de resultados).
# Não consome o evento: outros painéis visíveis também reagem.

const PASSO: int = 16

@export var rolar_com_setas: bool = false


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not _deve_reagir():
		return

	if event.is_action_pressed("ui_page_down", true):
		scroll_vertical += int(size.y * 0.9)
	elif event.is_action_pressed("ui_page_up", true):
		scroll_vertical -= int(size.y * 0.9)
	elif event.is_action_pressed("ui_end"):
		scroll_vertical = int(get_v_scroll_bar().max_value)
	elif event.is_action_pressed("ui_home"):
		scroll_vertical = 0
	elif rolar_com_setas and event.is_action_pressed("ui_down", true):
		scroll_vertical += PASSO
	elif rolar_com_setas and event.is_action_pressed("ui_up", true):
		scroll_vertical -= PASSO


# Se o foco está dentro de OUTRO ScrollTeclado, as teclas são dele.
func _deve_reagir() -> bool:
	var no: Node = get_viewport().gui_get_focus_owner()
	if no != null and is_ancestor_of(no):
		return true
	while no != null:
		if no is ScrollTeclado:
			return false
		no = no.get_parent()
	return true
