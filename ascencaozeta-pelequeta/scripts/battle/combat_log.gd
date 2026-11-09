extends RichTextLabel
class_name CombatLog

## LOG DO COMBATE
## Registra todos os eventos que acontecem durante a luta:
## - Rolagens de dados
## - Danos causados
## - Fardos aplicados
## - Mortes
## - Mensagens gerais
## 
## Mostra na UI com cores para cada tipo de evento

const MAX_LINHAS_VISIBLES = 50
const TEMPO_SCROLL_DELAY = 0.0
# Tipos de evento que compõem o resumo da tela de resultados.
const TIPOS_RESUMO: Array[String] = ["critico", "dano", "sucesso"]
const COR_ATAQUE: String = "yellow"
const COR_DANO: String = "red"
# Velocidade da digitação (a mesma da caixa de diálogo).
const VELOCIDADE_ESCRITA: float = 0.05

var escrevendo: bool = false
var pular_escrita: bool = false
# Registro interno: guarda todos os eventos, exibidos ou não.
var historico: Array[Dictionary] = []
# Fila do que será apresentado ao jogador, uma mensagem por vez.
# Separada do histórico, que guarda tudo e alimenta o resumo final.
var fila_apresentacao: Array[Dictionary] = []
func _ready() -> void:
	clear()
	bbcode_enabled = true
	scroll_following = true
	add_theme_font_size_override("normal_font_size", 8)
	add_theme_font_size_override("bold_font_size", 8)

# ============================================================================
# EVENTOS GERAIS
# ============================================================================

func registrar_evento(mensagem: String, tipo: String = "normal", exibir: bool = true) -> void:
	"""Registra o evento e, se exibir, enfileira para a apresentação sequencial"""
	# 1) Registro completo: independe da apresentação.
	historico.append({"mensagem": mensagem, "tipo": tipo, "apresentado": exibir})
	# 2) Fila de apresentação ao jogador (consumida pelo CombatManager).
	if exibir:
		fila_apresentacao.append({"mensagem": mensagem, "tipo": tipo})

# Últimas linhas relevantes para o resumo final.
func obter_resumo(max_linhas: int = 6) -> Array[String]:
	var relevantes: Array[String] = []
	for evento in historico:
		if evento["tipo"] in TIPOS_RESUMO and evento.get("apresentado", true):
			relevantes.append(String(evento["mensagem"]))
	var resumo: Array[String] = []
	for i in range(maxi(0, relevantes.size() - max_linhas), relevantes.size()):
		resumo.append(relevantes[i])
	return resumo

func registrar_ataque(dados: Dictionary) -> void:
	"""
	Registra um ataque com todos os detalhes.
	
	dados esperado:
	{
		"atacante": "Nome",
		"alvo": "Nome",
		"regiao": "Torso",
		"dado": 5,
		"categoria": "Sucesso Regular",
		"dano_aplicado": 3,
		"estresse_gerado": 1
	}
	"""
	var linhas: Array[String] = []
	
	# Linha principal do ataque
	var icon = _get_icon_por_categoria(dados["categoria"])
	var cor = _get_cor_por_categoria(dados["categoria"])
	
	linhas.append(
		"[color=%s]%s %s atacou %s (%s) - Dado: %d[/color]" % [
			cor,
			icon,
			dados["atacante"],
			dados["alvo"],
			dados["regiao"],
			dados["dado"]
		]
	)
	
	# Dano (se houver)
	var dano_aplicado = 0
	if dados.has("dano_aplicado"):
		dano_aplicado = dados["dano_aplicado"]
	
	if dano_aplicado > 0:
		linhas.append(
			"  [color=red]→ DANO: %d[/color]" % dano_aplicado
		)
	
	# Estresse (se houver)
	var estresse_gerado = 0
	if dados.has("estresse_gerado"):
		estresse_gerado = dados["estresse_gerado"]
	
	if estresse_gerado > 0:
		linhas.append(
			"  [color=mediumpurple]→ ESTRESSE: +%d[/color]" % estresse_gerado
		)
	
	# Adicionar todas as linhas
	for linha in linhas:
		append_text(linha + "\n")
	
	await get_tree().create_timer(TEMPO_SCROLL_DELAY).timeout
	scroll_to_line(get_line_count() - 1)
	
	

func registrar_status(combatente: String, status: String, ativo: bool = true) -> void:
	"""Registra mudança de status de um combatente"""
	var tipo = "aviso" if ativo else "info"
	var sinal = "✓" if ativo else "✗"
	
	registrar_evento(
		"%s %s [%s]" % [sinal, combatente, status],
		tipo
	)

# ============================================================================
# HELPERS DE FORMATAÇÃO
# ============================================================================

func _get_cor_por_tipo(tipo: String) -> String:
	"""Retorna cor HEX baseada no tipo de evento"""
	match tipo:
		"turno":      return "gold"
		"acao":       return "lightyellow"
		"info":       return "white"
		"sucesso":    return "lime"
		"aviso":      return "orange"
		"critico":    return "red"
		"movimento":  return "lightblue"
		_:            return "white"

func _get_icon_por_tipo(tipo: String) -> String:
	"""Retorna ícone baseado no tipo de evento"""
	match tipo:
		"turno":      return "🎯"
		"acao":       return "⚔️"
		"info":       return "ℹ️"
		"sucesso":    return "✓"
		"aviso":      return "⚠️"
		"critico":    return "✗"
		"movimento":  return "🚶"
		_:            return "•"
		"ataque":     return COR_ATAQUE
		"dano":       return COR_DANO

func _get_cor_por_categoria(categoria: String) -> String:
	"""Retorna cor baseada na categoria de resultado de combate"""
	match categoria:
		"Sucesso Extremo": return "lime"
		"Sucesso Regular":  return "yellow"
		"Falha Regular":    return "orange"
		"Falha Crítica":    return "red"
		_:                  return "white"

func _get_icon_por_categoria(categoria: String) -> String:
	"""Retorna ícone baseado na categoria de resultado"""
	match categoria:
		"Sucesso Extremo": return "✓✓"
		"Sucesso Regular":  return "✓"
		"Falha Regular":    return "✗"
		"Falha Crítica":    return "✗✗"
		_:                  return "?"

# ============================================================================
# LIMPEZA
# ============================================================================

func _limpar_overflow() -> void:
	"""Remove linhas antigas para manter performance"""
	if get_line_count() > MAX_LINHAS_VISIBLES:
		# Remover as primeiras linhas
		var texto = get_text()
		var linhas = texto.split("\n")
		
		# Manter apenas as últimas MAX_LINHAS_VISIBLES
		var inicio = max(0, linhas.size() - MAX_LINHAS_VISIBLES)
		var novo_texto = "\n".join(linhas.slice(inicio))
		
		clear()
		append_text(novo_texto)

func limpar_log() -> void:
	"""Limpa todo o conteúdo do log"""
	clear()

# Rolagem por teclado (a caixa não recebe foco): PageUp/PageDown.
func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var barra := get_v_scroll_bar()
	if event.is_action_pressed("ui_page_up", true):
		barra.value -= barra.page * 0.9
	elif event.is_action_pressed("ui_page_down", true):
		barra.value += barra.page * 0.9

# Entrega e esvazia a fila de apresentação.
func retirar_pendentes() -> Array[Dictionary]:
	var pendentes: Array[Dictionary] = []
	pendentes.append_array(fila_apresentacao)
	fila_apresentacao.clear()
	return pendentes

# Mostra uma única mensagem com efeito de digitação.
# Termina quando o texto está completo (ou quando pular_escrita é ativado).
func mostrar_mensagem(mensagem: String, tipo: String = "normal") -> void:
	clear()
	append_text("[color=%s]%s[/color]" % [_get_cor_por_tipo(tipo), mensagem])
	visible_characters = 0
	escrevendo = true
	pular_escrita = false

	# O texto sem BBCode define o ritmo e as pausas da digitação.
	var plano: String = get_parsed_text()
	for i in range(plano.length()):
		if pular_escrita:
			break
		visible_characters = i + 1

		var pausa: float = VELOCIDADE_ESCRITA
		var caractere: String = plano.substr(i, 1)
		if caractere == "." or caractere == "!" or caractere == "?":
			pausa += 0.20
		elif caractere == "," or caractere == ":" or caractere == ";":
			pausa += 0.10

		await get_tree().create_timer(pausa).timeout

	visible_characters = -1
	escrevendo = false
	pular_escrita = false
