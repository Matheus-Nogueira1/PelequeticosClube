extends Node2D

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
