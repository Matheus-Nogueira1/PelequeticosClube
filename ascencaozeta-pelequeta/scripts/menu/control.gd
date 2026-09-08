extends Control

@onready var slots = $CenterContainer/HBoxContainer.get_children()
@onready var name_label = $CharacterName
@onready var panel_name_label = $DescriptionPanel/VBoxContainer/Name
@onready var description_label = $DescriptionPanel/VBoxContainer/Description

var selected_index = 1

# 🧠 nomes dos personagens
var character_names = [
	"Escolhido",
	"JP da Maldade",
	"Mob"
]

# 📜 descrições
var character_descriptions = [
	"Um escolhido marcado por um destino desconhecido.\nSeu passado é um mistério, mas seu futuro será sangrento.",

	"JP da Maldade, um ser caótico e imprevisível.\nDizem que onde ele passa, apenas ruína permanece.",

	"Um simples mob... ou talvez não?\nMesmo os mais fracos podem esconder perigos inesperados."
]

func _ready():
	await get_tree().process_frame
		
	name_label.modulate = Color(0.9, 0.8, 0.6)
	panel_name_label.modulate = Color(0.8, 0.7, 0.5)
	description_label.modulate = Color(0.6, 0.7, 1.0)

	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	panel_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	update_visual(true)


func _input(event):
	if event.is_action_pressed("ui_right"):
		selected_index = (selected_index + 1) % slots.size()
		update_visual()

	elif event.is_action_pressed("ui_left"):
		selected_index = (selected_index - 1 + slots.size()) % slots.size()
		update_visual()

	elif event.is_action_pressed("ui_accept"):
		select_character()


func update_visual(skip_animation := false):

	# 🔥 atualiza tudo
	update_name(skip_animation)
	update_panel_name(skip_animation)
	update_description(skip_animation)

	for i in range(slots.size()):
		var slot = slots[i]

		if slot.has_meta("tween"):
			var old_tween = slot.get_meta("tween")
			if old_tween:
				old_tween.kill()

		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		slot.set_meta("tween", tween)

		var size = slot.size

		if i < selected_index:
			slot.pivot_offset = Vector2(0, size.y / 2)
		elif i > selected_index:
			slot.pivot_offset = Vector2(size.x, size.y / 2)
		else:
			slot.pivot_offset = size / 2

		var target_scale = Vector2(1.2, 1.2) if i == selected_index else Vector2(0.75, 0.75)
		var target_color = Color(1,1,1,1) if i == selected_index else Color(0.2,0.2,0.2,1)

		if skip_animation:
			slot.scale = target_scale
			slot.modulate = target_color
		else:
			tween.tween_property(slot, "scale", target_scale, 0.25)
			tween.tween_property(slot, "modulate", target_color, 0.25)


# 🔝 Nome grande (topo)
func update_name(skip_animation):

	var new_name = character_names[selected_index]
	var container = $CenterContainer/HBoxContainer

	var target_pos = container.global_position + container.size / 3.65	
	target_pos.y -= 120

	if name_label.has_meta("tween"):
		var old = name_label.get_meta("tween")
		if old:
			old.kill()

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	name_label.set_meta("tween", tween)

	if skip_animation:
		name_label.text = new_name
		name_label.global_position = target_pos
		name_label.modulate.a = 1
	else:
		tween.tween_property(name_label, "modulate:a", 0, 0.1)

		tween.tween_callback(func():
			name_label.text = new_name
		)

		tween.parallel().tween_property(name_label, "global_position", target_pos, 0.25)
		tween.parallel().tween_property(name_label, "modulate:a", 1, 0.15)


# 📛 Nome dentro do painel (título)
func update_panel_name(skip_animation := false):

	var new_name = character_names[selected_index]

	if panel_name_label.has_meta("tween"):
		var old = panel_name_label.get_meta("tween")
		if old:
			old.kill()

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	panel_name_label.set_meta("tween", tween)

	if skip_animation:
		panel_name_label.text = new_name
		panel_name_label.modulate.a = 1
	else:
		tween.tween_property(panel_name_label, "modulate:a", 0, 0.1)

		tween.tween_callback(func():
			panel_name_label.text = new_name
		)

		tween.tween_property(panel_name_label, "modulate:a", 1, 0.2)


# 📜 Descrição
func update_description(skip_animation := false):

	var new_text = character_descriptions[selected_index]

	if description_label.has_meta("tween"):
		var old = description_label.get_meta("tween")
		if old:
			old.kill()

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	description_label.set_meta("tween", tween)

	if skip_animation:
		description_label.text = new_text
		description_label.modulate.a = 1
	else:
		tween.tween_property(description_label, "modulate:a", 0, 0.1)

		tween.tween_callback(func():
			description_label.text = new_text
		)

		tween.tween_property(description_label, "modulate:a", 1, 0.2)


func select_character():
	print("Escolhido:", character_names[selected_index])
