extends Resource
class_name PaletaDialogo

# Paleta de cores dos nomes na caixa de diálogo.
# Editável no Inspector (arquivo .tres), sem mexer em scripts.
# Chaves em minúsculas, sem acento nos ids de personagem.

@export var cor_padrao: Color = Color("d8d2c4")
@export var cores: Dictionary[String, Color] = {}
# Nome escrito na fala (minúsculo) -> chave da paleta. Ex.: "???" -> "misterio"
@export var apelidos: Dictionary[String, String] = {}


# Converte o texto de "speaker" na chave usada em "cores".
func resolver_chave(falante: String) -> String:
	var id: String = PersonagensData.normalizar_id(falante)
	if id != "":
		return id
	var texto: String = falante.strip_edges().to_lower()
	return apelidos.get(texto, texto)


func cor_do_falante(chave: String) -> Color:
	return cores.get(chave, cor_padrao)
