class_name UiUtil
extends RefCounted

## Aplica a compactação quando o botão entrar na árvore (o tema já resolvido).
static func aplicar(botao: Button, tamanho_fonte: int = 8) -> void:
	botao.ready.connect(
		func() -> void: compactar_botao(botao, tamanho_fonte),
		CONNECT_ONE_SHOT
	)

static func compactar_botao(botao: Button, tamanho_fonte: int = 8) -> void:
	if botao == null or not is_instance_valid(botao):
		return
	botao.add_theme_font_size_override("font_size", tamanho_fonte)
	for nome_estilo in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		if not botao.has_theme_stylebox(nome_estilo):
			continue
		var base: StyleBox = botao.get_theme_stylebox(nome_estilo)
		var compacto: StyleBox = base.duplicate() as StyleBox
		compacto.content_margin_top = 1
		compacto.content_margin_bottom = 1
		compacto.content_margin_left = 3
		compacto.content_margin_right = 3
		botao.add_theme_stylebox_override(nome_estilo, compacto)
