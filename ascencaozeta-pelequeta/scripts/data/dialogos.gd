extends Node

const CONVERSAS: Dictionary = {
	"intro": [
		{"speaker": "Testemunha", "text": "O abismo não grita, ele sussurra."},
		{"speaker": "Testemunha", "text": "Quem pulou? Tolos, nunca tiveram chance, quem desce jamais volta."},
		{"speaker": "Testemunha", "text": "Na morte, uma esperança, o brilho das chamas no meio de um lugar sombrio.."},
		{"speaker": "Testemunha", "text": "Em um universo repleto de dor e arrependimento quem será o salvador das pobres almas perdidas?"},
		{"speaker": "Testemunha", "text": "Aqueles que possuem o fogo terão sua glória."}
	],
	"DonMaldade-inicio": [
		{"speaker": "Testemunha", "text": "Escolham as regiões que vão arriscar."},
		{"speaker": "Testemunha", "text": "Quando confirmarem, os dados vão rolar."}
	],
	"Mob-inicio": [
		{"speaker": "Testemunha", "text": "Escolham as regiões que vão arriscar."},
		{"speaker": "Testemunha", "text": "Quando confirmarem, os dados vão rolar."}
	],
	"Escolhido-inicio": [
		{"speaker": "Testemunha", "text": "Escolham as regiões que vão arriscar."},
		{"speaker": "Testemunha", "text": "Quando confirmarem, os dados vão rolar."}
	],
}

func get_conversa(id: String) -> Array:
	if not CONVERSAS.has(id):
		return []
	return CONVERSAS[id].duplicate(true)
