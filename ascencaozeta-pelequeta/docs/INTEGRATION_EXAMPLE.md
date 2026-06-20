# 📝 Exemplo de Integração - Combat System

Este arquivo mostra PASSO A PASSO como integrar o sistema de combate à sua cena `combat.tscn`.

---

## 1️⃣ ESTRUTURA RECOMENDADA DA CENA

Edite sua `combat.tscn` para ter esta estrutura de nós:

```
Control (root)
├── Name: "Root"
├── Script: combat_manager.gd
│
├── MarginContainer
│   ├── margin_left = 12
│   ├── margin_right = 12
│   ├── margin_top = 12
│   ├── margin_bottom = 12
│   │
│   └── VBoxContainer
│       ├── Name: "MainLayout"
│       ├── separation = 8
│       │
│       ├── TopBar (PanelContainer)
│       │   ├── Name: "TopBar"
│       │   ├── custom_minimum_size = Vector2(0, 40)
│       │   │
│       │   └── HBoxContainer
│       │       ├── Name: "TopBarLayout"
│       │       ├── separation = 8
│       │       │
│       │       ├── PartyPanel (PanelContainer) ⭐
│       │       │   ├── Name: "PartyPanel"
│       │       │   ├── unique_name_in_owner = true  (%PartyPanel)
│       │       │   ├── custom_minimum_size = Vector2(180, 0)
│       │       │   ├── Script: party_panel.gd
│       │       │   │
│       │       │   └── VBoxContainer (criado pelo script)
│       │       │
│       │       ├── Battlefield (Control)
│       │       │   ├── Name: "Battlefield"
│       │       │   ├── unique_name_in_owner = true  (%Battlefield)
│       │       │   ├── size_flags_horizontal = 3
│       │       │   ├── size_flags_stretch_ratio = 3.0
│       │       │   │
│       │       │   └── Control (para animações)
│       │       │
│       │       ├── EnemyPanel (PanelContainer) ⭐
│       │       │   ├── Name: "EnemyPanel"
│       │       │   ├── unique_name_in_owner = true  (%EnemyPanel)
│       │       │   ├── custom_minimum_size = Vector2(180, 0)
│       │       │   ├── Script: enemy_panel.gd
│       │       │   │
│       │       │   └── VBoxContainer (criado pelo script)
│       │       │
│       │       ├── VBoxContainer
│       │       │   ├── Name: "RightPanel"
│       │       │   │
│       │       │   ├── RegionalPanel (PanelContainer) ⭐
│       │       │   │   ├── Name: "RegionalPanel"
│       │       │   │   ├── unique_name_in_owner = true  (%RegionalPanel)
│       │       │   │   ├── custom_minimum_size = Vector2(250, 0)
│       │       │   │   ├── size_flags_horizontal = 3
│       │       │   │   ├── size_flags_stretch_ratio = 2.0
│       │       │   │   ├── Script: regional_selector.gd
│       │       │   │   │
│       │       │   │   └── VBoxContainer (criado pelo script)
│       │       │   │
│       │       │   └── ActionPanel (PanelContainer) ⭐
│       │       │       ├── Name: "ActionPanel"
│       │       │       ├── unique_name_in_owner = true  (%ActionPanel)
│       │       │       ├── size_flags_horizontal = 3
│       │       │       ├── Script: action_panel.gd
│       │       │       │
│       │       │       └── VBoxContainer (criado pelo script)
│       │       │
│       │       └── PanelContainer (container para RegionalPanel + ActionPanel)
│       │           ├── Name: "SidePanel"
│       │
│       └── LogPanel (PanelContainer) ⭐
│           ├── Name: "LogPanel"
│           ├── unique_name_in_owner = true  (%LogPanel)
│           ├── custom_minimum_size = Vector2(0, 120)
│           ├── Script: combat_log.gd
│           │
│           └── RichTextLabel
│               ├── Name: "RichTextLabel"
│               ├── bbcode_enabled = true
│               ├── scroll_following = true
```

---

## 2️⃣ ATRIBUINDO SCRIPTS AOS NÓS

Clique em cada nó marcado com ⭐ e atribua o script correspondente:

| Nó | Script | Tipo |
|----|--------|------|
| PartyPanel | `party_panel.gd` | PanelContainer |
| EnemyPanel | `enemy_panel.gd` | PanelContainer |
| RegionalPanel | `regional_selector.gd` | PanelContainer |
| ActionPanel | `action_panel.gd` | PanelContainer |
| LogPanel | `combat_log.gd` | RichTextLabel |
| Root (Control) | `combat_manager.gd` | Control |

---

## 3️⃣ MARCANDO UNIQUE NAMES

Para cada nó com ⭐, marque como Unique Name:

1. Clique direito no nó
2. Selecione "Rename"
3. Adicione `%` no início: `%PartyPanel`
4. Pressione Enter

Isso permite usar `@onready var party_panel = %PartyPanel` nos scripts.

---

## 4️⃣ CONECTAR SINAIS NO _READY() DO CombatManager

No seu `CombatManager.gd`, o `_ready()` já chama `_conectar_sinais_paineis()`, que conecta:

```gdscript
action_panel.acao_atacar.connect(_iniciar_ataque)
action_panel.acao_pericia.connect(_iniciar_pericia)
action_panel.acao_habilidade.connect(_iniciar_habilidade)
action_panel.acao_item.connect(_iniciar_item)

regional_selector.regiao_selecionada.connect(_on_regiao_selecionada)
enemy_panel.inimigo_selecionado.connect(_on_inimigo_selecionado)
```

✅ **Automático!** Não precisa fazer nada.

---

## 5️⃣ CARREGAR DADOS DE COMBATE

Substitua a função `_setup_exemplo()` para carregar dados reais:

### Opção A: Carregar do Autoload Dialogos

Se seus personagens estão no autoload:

```gdscript
func _inicializar_combate() -> void:
	print("[CombatManager] Inicializando combate...")
	
	# Carregar personagens do sistema global
	combatentes_jogador = [
		{
			"nome": Dialogos.personagem_jogador["nome"],
			"tipo": "jogador",
			"saude_maxima": Dialogos.personagem_jogador["vida"],
			"saude_atual": Dialogos.personagem_jogador["vida"],
			"defesa_base": 2,
			"dano_arma": 2,
			"atributo_dano": 1,
			"estresse_por_regiao": {
				"Torso": 0,
				"Braço Direito": 0,
				"Braço Esquerdo": 0,
				"Perna Direita": 0,
				"Perna Esquerda": 0
			},
			"status": [],
			"iniciativa": 0
		}
	]
	
	# Inimigos hardcoded por enquanto
	combatentes_inimigo = [
		{
			"nome": "Goblin",
			"tipo": "inimigo",
			"saude_maxima": 8,
			"saude_atual": 8,
			"defesa_base": 1,
			"dano_arma": 1,
			"atributo_dano": 0,
			"estresse_por_regiao": {
				"Torso": 0,
				"Braço Direito": 0,
				"Braço Esquerdo": 0,
				"Perna Direita": 0,
				"Perna Esquerda": 0
			},
			"status": [],
			"iniciativa": 0
		}
	]
	
	# Rest do código continua igual...
	var todos = combatentes_jogador + combatentes_inimigo
	ordem_turno = todos.duplicate(true)
	
	_calcular_iniciativa()
	ordem_turno.sort_custom(func(a, b): return a["iniciativa"] > b["iniciativa"])
	
	# Atualizar painéis
	party_panel.atualizar_todos(combatentes_jogador)
	enemy_panel.atualizar_todos(combatentes_inimigo)
	
	combate_ativo = true
	combate_iniciado.emit()
	
	_avancar_turno()
```

### Opção B: Carregar de um Manager de Combate Global

```gdscript
func _setup_exemplo() -> void:
	if CombatSetup.has_method("carregar_combate"):
		var dados = CombatSetup.carregar_combate()
		combatentes_jogador = dados["jogadores"]
		combatentes_inimigo = dados["inimigos"]
	else:
		# Fallback
		_setup_exemplo_padrao()
```

---

## 6️⃣ EXECUTAR E TESTAR

1. **Abra a cena `combat.tscn`**
2. **Clique em Play** (F5)
3. **Você deve ver**:
   - ✅ PartyPanel com personagem
   - ✅ EnemyPanel com inimigos
   - ✅ ActionPanel com 4 botões
   - ✅ RegionalPanel escondido inicialmente
   - ✅ LogPanel vazio
   - ✅ "🎯 Turno de [Nome]!" no log

4. **Teste fluxo básico**:
   - Clique em "⚔️ ATACAR"
   - RegionalPanel deve aparecer
   - Selecione 1-3 regiões
   - Clique "Confirmar"
   - EnemyPanel destaca inimigos
   - Clique em um inimigo
   - Veja resultado no LogPanel

---

## 7️⃣ ESTRUTURA DE DADOS - EXEMPLO COMPLETO

```gdscript
# Estrutura de um combatente no combate
var guerreiro = {
	"nome": "Guerreiro",
	"tipo": "jogador",
	
	# Saúde
	"saude_maxima": 15,
	"saude_atual": 15,
	
	# Defesa
	"defesa_base": 2,
	
	# Ataque
	"dano_arma": 2,
	"atributo_dano": 1,
	
	# Estresse por região (essencial para OBLIVIO)
	"estresse_por_regiao": {
		"Torso": 0,
		"Braço Direito": 0,
		"Braço Esquerdo": 0,
		"Perna Direita": 0,
		"Perna Esquerda": 0
	},
	
	# Status ativos
	"status": [],
	
	# Calculado automaticamente
	"iniciativa": 5
}
```

---

## 8️⃣ PRÓXIMAS IMPLEMENTAÇÕES

### Quando Estiver Pronto para Custos de Ação

Abra `CombatManager.gd` e complete:

```gdscript
# TODO: Adicionar enum de tipos de ação
var pontos_acao_por_tipo = {
	CombatManager.ActionType.ACAO_REGULAR: 1,     # Definir depois
	CombatManager.ActionType.MOVIMENTO: 1,        # Definir depois
	CombatManager.ActionType.EXTRA: 1,            # Definir depois
	CombatManager.ActionType.COMPLETA: 3          # Definir depois
}

func _consumir_pontos_acao(combatente: Dictionary, tipo_acao: int) -> bool:
	var custo = pontos_acao_por_tipo.get(tipo_acao, 1)
	
	if combatente.get("pontos_acao", 0) >= custo:
		combatente["pontos_acao"] -= custo
		return true
	
	return false
```

### Implementar Menus

Em `ActionPanel.gd`, complete os stubs:

```gdscript
func mostrar_menu_pericias(combatente: Dictionary) -> void:
	# Criar PopupMenu com pericias disponiveis
	# Emitir sinal com perícia selecionada
	pass

func mostrar_menu_habilidades(combatente: Dictionary) -> void:
	# Criar PopupMenu com habilidades
	# Emitir sinal com habilidade selecionada
	pass

func mostrar_menu_itens(combatente: Dictionary) -> void:
	# Criar PopupMenu com itens do inventário
	# Emitir sinal com item selecionado
	pass
```

---

## 🐛 DEBUGGING

Se algo não funcionar, adicione prints:

```gdscript
# No _ready() do CombatManager
print("PartyPanel carregado:", party_panel != null)
print("EnemyPanel carregado:", enemy_panel != null)
print("ActionPanel carregado:", action_panel != null)
print("RegionalSelector carregado:", regional_selector != null)
print("CombatLog carregado:", log_panel != null)
print("Combatentes jogador:", combatentes_jogador.size())
print("Combatentes inimigo:", combatentes_inimigo.size())
```

Verifique no Output se todos retornam `true` e números corretos.

---

## ✅ CHECKLIST DE INTEGRAÇÃO

- [ ] Nós criados na cena conforme estrutura
- [ ] Scripts atribuídos aos nós corretos
- [ ] Unique names marcados com `%`
- [ ] CombatManager.gd no nó raiz (Control)
- [ ] Dados de combate carregados em `_inicializar_combate()`
- [ ] Cena pronta para Play (F5)
- [ ] Fluxo básico testado (Atacar → Selecionar Regiões → Selecionar Alvo → Ver Resultado)

---

## 📞 REFERÊNCIA RÁPIDA

| Tarefa | Arquivo | Método |
|--------|---------|--------|
| Iniciar combate | `combat_manager.gd` | `_inicializar_combate()` |
| Avançar turno | `combat_manager.gd` | `_avancar_turno()` |
| Processar ataque | `combat_manager.gd` | `_processar_ataque()` |
| Registrar evento | `combat_log.gd` | `registrar_evento()` |
| Ativar regiões | `regional_selector.gd` | `ativar_para_ataque()` |
| Selecionar inimigo | `enemy_panel.gd` | `ativar_seletor_alvo()` |
| Habilitar ações | `action_panel.gd` | `habilitar_acoes()` |
| Atualizar personagem | `party_panel.gd` | `atualizar_personagem()` |
