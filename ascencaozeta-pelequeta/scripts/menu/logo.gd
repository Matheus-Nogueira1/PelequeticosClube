extends Control


func _ready() -> void:
	var conteudo = $ColorRect/VBoxContainer
	
	conteudo.modulate.a = 0.0
	# TEMPO EM QUE A LOGO FICA INVISÍVEL
	await get_tree().create_timer(0.1).timeout
	# FADE IN
	var fade_in = create_tween()
	fade_in.tween_property(conteudo, "modulate:a", 1.0, 3.0)
	await fade_in.finished
	
	# TEMPO COM A LOGO VISÍVEL
	await get_tree().create_timer(2.0).timeout
	
	# FADE OUT
	var fade_out = create_tween()
	fade_out.tween_property(conteudo, "modulate:a", 0.0, 1.0)
	await fade_out.finished
	

	$Timer.start()


func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/TelaInicial.tscn")
