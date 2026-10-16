extends Node

@export var caixa_dialogo_scene: PackedScene
@export var personagem_path: NodePath
@export var dialogo_id: String = "porta_ritual"

var caixa_dialogo_atual: Control = null
var personagem: Node = null


func _ready() -> void:
	if not personagem_path.is_empty():
		personagem = get_node_or_null(personagem_path)

	if caixa_dialogo_scene == null:
		push_error("TesteDialogoMapa: atribua CaixaDialogo.tscn no Inspector.")
		return

	if personagem == null:
		push_warning("TesteDialogoMapa: personagem ainda não foi configurado.")


func testar_dialogo() -> void:
	if caixa_dialogo_scene == null:
		push_error("A cena da caixa de diálogo não foi configurada.")
		return

	if is_instance_valid(caixa_dialogo_atual):
		return

	caixa_dialogo_atual = caixa_dialogo_scene.instantiate()

	if caixa_dialogo_atual.has_method("configurar_dialogo"):
		var dados_personagem = null

		if personagem != null and "dados" in personagem:
			dados_personagem = personagem.get("dados")

		caixa_dialogo_atual.configurar_dialogo(
			dados_personagem,
			dialogo_id,
			false
		)

	add_child(caixa_dialogo_atual)

	caixa_dialogo_atual.tree_exited.connect(
		func() -> void:
			caixa_dialogo_atual = null
	)
