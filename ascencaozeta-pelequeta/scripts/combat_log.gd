extends RichTextLabel
class_name CombatLog

const MAX_LINHAS_VISIBLES = 50
const TEMPO_SCROLL_DELAY = 0.1

func _ready() -> void:
	clear()
	bbcode_enabled = true
	scroll_following = true


# ============================================================================
# EVENTOS GERAIS
# ============================================================================

func registrar_evento(mensagem: String, tipo: String = "normal") -> void:
	"""Registra um evento genérico com cor baseada no tipo"""
	var cor = _get_cor_por_tipo(tipo)
	var icon = _get_icon_por_tipo(tipo)
	
	var texto = "[color=%s]%s %s[/color]\n" % [cor, icon, mensagem]
	append_text(texto)
	
	# Scroll automático
	await get_tree().create_timer(TEMPO_SCROLL_DELAY).timeout
	scroll_to_line(get_line_count() - 1)
	
	_limpar_overflow()

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
	if dados.get("dano_aplicado", 0) > 0:
		linhas.append(
			"  [color=red]→ DANO: %d[/color]" % dados["dano_aplicado"]
		)
	
	# Estresse (se houver)
	if dados.get("estresse_gerado", 0) > 0:
		linhas.append(
			"  [color=mediumpurple]→ ESTRESSE: +%d[/color]" % dados["estresse_gerado"]
		)
	
	# Adicionar todas as linhas
	for linha in linhas:
		append_text(linha + "\n")
	
	await get_tree().create_timer(TEMPO_SCROLL_DELAY).timeout
	scroll_to_line(get_line_count() - 1)
	
	_limpar_overflow()

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
