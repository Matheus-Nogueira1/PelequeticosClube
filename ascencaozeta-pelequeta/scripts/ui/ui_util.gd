class_name UiUtil
extends RefCounted

## Aplica a compactação quando o botão entrar na árvore (o tema já resolvido).
static func aplicar(
	botao: Button,
	tamanho_fonte: int = 8,
	usar_hover_como_foco: bool = false
) -> void:
	botao.ready.connect(
		func() -> void:
			compactar_botao(
				botao,
				tamanho_fonte,
				usar_hover_como_foco
			),
		CONNECT_ONE_SHOT
	)

static func compactar_botao(
	botao: Button,
	tamanho_fonte: int = 8,
	usar_hover_como_foco: bool = false
) -> void:
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
	if usar_hover_como_foco:
		var estilo_hover: StyleBox = botao.get_theme_stylebox("hover")
		botao.add_theme_stylebox_override(
			"focus",
			estilo_hover.duplicate()
		)
