extends Control


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


# ==========================================
# BOTÃO START
# ==========================================

func _on_start_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/testes/caixa-dialogo.tscn")


# ==========================================
# BOTÃO CRÉDITOS
# ==========================================

func _on_credits_btn_pressed() -> void:
	pass


# ==========================================
# BOTÃO SAIR
# ==========================================

func _on_quit_btn_pressed() -> void:
	get_tree().quit()
