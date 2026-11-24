extends Button
class_name BotaoAjuda

# Botão de consulta: só emite um sinal. Quem decide se a ajuda pode abrir
# naquele momento é o controlador da cena (ex.: CombatManager).
# Configure "painel" e "ancora" no Inspector. Focus Mode = None.

signal solicitado(painel: String, ancora: String)

@export var painel: String = ""
@export var ancora: String = ""


func _ready() -> void:
	add_to_group("botao_ajuda")
	pressed.connect(func() -> void: solicitado.emit(painel, ancora))
	
