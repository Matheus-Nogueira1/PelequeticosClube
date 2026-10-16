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

	# Exemplo de diálogo com opções e teste de conhecimento.
	"porta_ritual": [
		{
			"speaker": "Inscrição",
			"text": "Símbolos antigos cobrem a porta. Algumas marcas parecem reagir à sua presença.",
			"options": [
				{
					"text": "Interpretar os símbolos",
					"knowledge": "Místico",
					"success_dialogue": "ritual_sucesso",
					"failure_dialogue": "ritual_falha"
				},
				{
					"text": "Forçar a porta",
					"next_dialogue": "porta_forcada"
				},
				{
					"text": "Deixar o local",
					"close_dialogue": true
				}
			]
		}
	],

	"ritual_sucesso": [
		{"speaker": "Inscrição", "text": "Você compreende o significado dos símbolos e encontra o mecanismo oculto."}
	],

	"ritual_falha": [
		{"speaker": "Inscrição", "text": "Os símbolos continuam incompreensíveis. Você não consegue decifrar o mecanismo."}
	],

	"porta_forcada": [
		{"speaker": "Inscrição", "text": "A porta resiste ao impacto. O som ecoa pelo corredor."}
	]
}


func get_conversa(id: String) -> Array:
	if not CONVERSAS.has(id):
		return []

	return CONVERSAS[id].duplicate(true)
