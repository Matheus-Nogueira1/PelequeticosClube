extends Node2D

var regioes=["Cabeça","Tronco","Braço Direito","Braço Esquerdo","Pernas"]
var selecionadas=[false,false,false,false,false]
var indice_atual=0

@onready var label=$Label

func _ready():
	atualizar_texto()

func _process(delta):
	if Input.is_action_just_pressed("ui_up"):
		indice_atual=max(0,indice_atual-1)
		atualizar_texto()

	if Input.is_action_just_pressed("ui_down"):
		indice_atual=min(regioes.size()-1,indice_atual+1)
		atualizar_texto()

	if Input.is_action_just_pressed("ui_right"):
		selecionadas[indice_atual]=true
		atualizar_texto()

	if Input.is_action_just_pressed("ui_left"):
		selecionadas[indice_atual]=false
		atualizar_texto()

	if Input.is_action_just_pressed("ui_accept"):
		confirmar_selecao()

func atualizar_texto():
	var texto="Escolha as regiões (máx 5):\n\n"

	for i in range(regioes.size()):
		var cursor="> " if i==indice_atual else "  "
		var marcado="[X] " if selecionadas[i] else "[ ] "
		texto+=cursor+marcado+regioes[i]+"\n"

	texto+="\n↑↓ navegar | → marcar | ← desmarcar | Enter confirmar"

	label.text=texto

func confirmar_selecao():
	var escolhidas=[]

	for i in range(regioes.size()):
		if selecionadas[i]:
			escolhidas.append(regioes[i])

	if escolhidas.size()==0:
		print("Nenhuma região selecionada")
		return

	print("Regiões escolhidas:",escolhidas)
	rolar_dados(escolhidas.size())

func rolar_dados(qtd:int):
	for i in qtd:
		var resultado=randi_range(1,20)
		print("Dado:",resultado)
