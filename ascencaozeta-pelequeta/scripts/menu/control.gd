extends Control

@onready var slots: Array[Node] = $CenterContainer/HBoxContainer.get_children()
@onready var name_label: Label = $CharacterName
@onready var description_label: Label = $DescriptionPanel/VBoxContainer/Description

# Ordem visual dos personagens na tela.
var character_ids: Array[String] = [
	"Escolhido",
	"JP da Maldade",
	"Mob"
]

var selected_index: int = 1


func _ready() -> void:
	await get_tree().process_frame

	if slots.is_empty():
		push_error("EscolherPersonagem: nenhum personagem encontrado no HBoxContainer.")
		return

	if slots.size() != character_ids.size():
		push_error(
			"EscolherPersonagem: a quantidade de slots não corresponde " +
			"à quantidade de personagens."
		)
		return

	selected_index = clampi(selected_index, 0, slots.size() - 1)

	update_visual(true)


func _input(event: InputEvent) -> void:
	if slots.is_empty():
		return

	if event.is_action_pressed("ui_right"):
		selected_index = (selected_index + 1) % slots.size()
		update_visual()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_left"):
		selected_index = (selected_index - 1 + slots.size()) % slots.size()
		update_visual()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_accept"):
		select_character()


## Consulta os dados centralizados em PersonagensData.gd.
func obter_personagem_selecionado() -> Dictionary:
	return PersonagensData.obter_dados_apresentacao(
		character_ids[selected_index]
	)	


func update_visual(skip_animation: bool = false) -> void:
	update_name(skip_animation)
	update_description(skip_animation)

	# Atualiza apenas a transparência dos personagens.
	# Não altera posição, escala ou dimensões.
	for i in range(slots.size()):
		var slot: Control = slots[i] as Control

		if slot == null:
			continue

		if slot.has_meta("tween"):
			var old_tween = slot.get_meta("tween")
			if old_tween is Tween and old_tween.is_running():
				old_tween.kill()

		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)
		slot.set_meta("tween", tween)

		var target_color: Color

		if i == selected_index:
			target_color = Color.WHITE
		else:
			target_color = Color(0.45, 0.45, 0.45, 1.0)

		if skip_animation:
			slot.modulate = target_color
		else:
			tween.tween_property(
				slot, "modulate", target_color, 0.2
			)


func update_name(skip_animation: bool = false) -> void:
	var dados: Dictionary = obter_personagem_selecionado()
	var novo_nome: String = dados["nome"]

	if name_label.has_meta("tween"):
		var old_tween = name_label.get_meta("tween")
		if old_tween is Tween and old_tween.is_running():
			old_tween.kill()

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	name_label.set_meta("tween", tween)

	if skip_animation:
		name_label.text = novo_nome
		name_label.modulate.a = 1.0
	else:
		tween.tween_property(name_label, "modulate:a", 0.0, 0.1)
		tween.tween_callback(func() -> void:
			name_label.text = novo_nome
		)
		tween.tween_property(name_label, "modulate:a", 1.0, 0.15)


func update_description(skip_animation: bool = false) -> void:
	var dados: Dictionary = obter_personagem_selecionado()
	var novo_texto: String = dados["descricao"]

	if description_label.has_meta("tween"):
		var old_tween = description_label.get_meta("tween")
		if old_tween is Tween and old_tween.is_running():
			old_tween.kill()

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	description_label.set_meta("tween", tween)

	if skip_animation:
		description_label.text = novo_texto
		description_label.modulate.a = 1.0
	else:
		tween.tween_property(
			description_label, "modulate:a", 0.0, 0.1
		)
		tween.tween_callback(func() -> void:
			description_label.text = novo_texto
		)
		tween.tween_property(
			description_label, "modulate:a", 1.0, 0.2
		)


func select_character() -> void:
	var dados: Dictionary = obter_personagem_selecionado()
	
	print("Personagem selecionado: ", dados["nome"])
	print("Identificador interno: ", character_ids[selected_index])
	get_tree().change_scene_to_file(
		"res://scenes/mapas/world.tscn"
	)
