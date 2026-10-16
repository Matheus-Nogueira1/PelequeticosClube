extends Node2D

@export var caixa_dialogo_scene: PackedScene
@export var dialogo_parent: Control
var character_scenes = {
	"Escolhido": preload("res://scenes/personagens/Escolhido.tscn"),
	"JP": preload("res://scenes/personagens/Jp.tscn"),
	"Mob": preload("res://scenes/personagens/Mob.tscn")
}


func _ready():

	print("================================")
	print("WORLD INICIADO")
	print("Personagem escolhido: ", Global.selected_character)
	print("================================")

	if not character_scenes.has(Global.selected_character):
		print("ERRO: personagem não encontrado!")
		return

	var character_scene = character_scenes[Global.selected_character]

	print("Cena encontrada: ", character_scene)

	var player = character_scene.instantiate()

	print("Personagem instanciado: ", player)

	$Player.add_child(player)


	print("Personagem adicionado ao Player!")
	print("Posição do Player: ", $Player.position)
	print("Posição do personagem: ", player.position)

func abrir_dialogo(
	personagem: CombatenteData,
	id_dialogo: String
) -> void:
	if caixa_dialogo_scene == null:
		push_error("A cena CaixaDialogo.tscn não foi configurada.")
		return

	if dialogo_parent == null:
		push_error("O nó pai da caixa de diálogo não foi configurado.")
		return

	var caixa = caixa_dialogo_scene.instantiate()

	caixa.configurar_dialogo(
		personagem,
		id_dialogo,
		false
	)

	dialogo_parent.add_child(caixa)
