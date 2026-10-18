extends Node

const CONVERSAS: Dictionary = {
#INTROS

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

#CABANA ELIZABETH

	"Elizabeth": [
		{"speaker": "Elizabeth", "text": "Olá Escolhido."},
		{"speaker": "Elizabeth", "text": "Seja bem vindo a nossa cabana."},
		{"speaker": "Elizabeth", "text": "Você compreende o motivo dessa reunião?", "options":
		[{"text": "Onde estou?"}, 
		{"text": "Quem é você?"},
		{"text": "Usar Social", "knowledge": "Social", "success_dialogue": "elizabeth_social_sucesso"}]}
	],
	"elizabeth_social_sucesso": [
		{
			"speaker": "Escolhido",
			"text": "Eu entendo. Esse mundo parece tomado pela escuridão, como você está sozinha nesta cabana, precisa da minha ajuda. Como recompensa terei as respostas que procuro, acertei?"
		},
		{
			"speaker": "Elizabeth",
			"text": "Na mosca."
		}
	],

#BASTILHA INTERAÇÔES

"parede_estranha": [
	{
		"speaker": "Testemunha",
		"text": "Era pra ter mais uma porta aqui, mas uma parede estranha parece bloquear a passagem...",
		"options": [
			{
				"text": "Usar Esforço",
				"knowledge": "Esforço",
				"success_dialogue": "parede_esforco_sucesso",
				"failure_dialogue": "parede_esforco_falha",
				"critical_failure_dialogue": "parede_esforco_falha_critica",
				"extreme_success_dialogue": "parede_esforco_sucesso_extremo"
			},
			{
				"text": "Usar Místico",
				"knowledge": "Místico",
				"success_dialogue": "parede_mistico_sucesso",
				"failure_dialogue": "parede_mistico_falha",
				"critical_failure_dialogue": "parede_mistico_falha_critica",
				"extreme_success_dialogue": "parede_mistico_sucesso_extremo"
			},
			{
				"text": "Usar Bandidagem",
				"knowledge": "Bandidagem",
				"success_dialogue": "parede_bandidagem_sucesso",
				"failure_dialogue": "parede_bandidagem_falha",
				"critical_failure_dialogue": "parede_bandidagem_falha_critica",
				"extreme_success_dialogue": "parede_bandidagem_sucesso_extremo"
			}
		]
	}
],
	# ESFORÇO — FALHA CRÍTICA
	"parede_esforco_falha_critica": [
		{
			"speaker": "Testemunha",
			"text": "Você prepara um golpe com toda a sua força, no momento em que encosta na parede, tropeça , atravessa a parede e cai de cara no chão. Era apenas uma ilusão. Você sente uma dor aguda em sua cabeça."
		},
		{
			"speaker": "Testemunha",
			"text": "Recebeu 1 de estresse."
		}
	],

	# ESFORÇO — SUCESSO EXTREMO
	"parede_esforco_sucesso_extremo": [
		{
			"speaker": "Testemunha",
			"text": "Você concentra toda a sua força e avança sem hesitar. No instante do impacto, a parede se desfaz como fumaça. Você atravessa a ilusão com tanta força que chega ao outro lado antes mesmo de perceber que a passagem estava livre."
		}
	],

	# MÍSTICO — FALHA CRÍTICA
	"parede_mistico_falha_critica": [
		{
			"speaker": "Testemunha",
			"text": "Você aproxima a mão da parede e tenta sentir sua essência. Por um instante, algo responde ao seu toque. Uma presença fria percorre seu braço, e a sensação desaparece antes que você consiga compreender o que despertou."
		}
	],

	# MÍSTICO — SUCESSO EXTREMO
	"parede_mistico_sucesso_extremo": [
		{
			"speaker": "Testemunha",
			"text": "Você fecha os olhos e sente a energia que distorce o espaço diante de si. A ilusão se revela por completo: não existe parede alguma. Por um breve instante, você também percebe uma segunda presença escondida além da passagem."
		}
	],

	# BANDIDAGEM — FALHA CRÍTICA
	"parede_bandidagem_falha_critica": [
		{
			"speaker": "Testemunha",
			"text": "Você examina as frestas e passa os dedos pela superfície. Um mecanismo oculto dispara sob sua mão. Um estalo ecoa pela sala, seguido por um ruído vindo de algum lugar além da parede. Uma flecha perfura seu peito."
		}
	],

	# BANDIDAGEM — SUCESSO EXTREMO
	"parede_bandidagem_sucesso_extremo": [
		{
			"speaker": "Testemunha",
			"text": "Você percebe uma irregularidade quase imperceptível e acompanha o contorno da ilusão com os dedos. Em poucos instantes, encontra o ponto exato em que a magia falha. A passagem se abre diante de você, revelando não apenas o caminho, mas também marcas que indicam que alguém atravessou por ali recentemente."
		}
	],

	"parede_esforco_sucesso": [
		{
			"speaker": "Testemunha",
			"text": "Você prepara com um golpe com toda a sua força, no momento em que encosta na parede, ela se dissipa e revela ser apenas uma ilusão."
		}
	],

	"parede_esforco_falha": [
		{
			"speaker": "Parede Estranha",
			"text": "Você prepara um golpe com toda a sua força, no momento em que encosta na parede, tropeça , atravessa a parede e cai de cara no chão. Era apenas uma ilusão."
		}
	],

	"parede_mistico_sucesso": [
		{
			"speaker": "Testemunha",
			"text": "Você sente as energias místicas e uma aura arcana nessa parede estranha... ao se aproximar percebe que é uma ilusão."
		}
	],

	"parede_mistico_falha": [
		{
			"speaker": "Testemunha",
			"text": "Você tenta entender o que há de errado com essa parede, porém, tudo parece estar correto."
		}
	],

	"parede_bandidagem_sucesso": [
		{
			"speaker": "Testemunha",
			"text": "Você examina as frestas e procura sinais de uma passagem disfarçada. Um detalhe denuncia o truque, e você encontra uma maneira de atravessar a ilusão."
		}
	],

	"parede_bandidagem_falha": [
		{
			"speaker": "Testemunha",
			"text": "Você procura mecanismos, frestas e irregularidades, tudo parece correto. "
		}
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
