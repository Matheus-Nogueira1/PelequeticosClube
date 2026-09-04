# 🎮 Sistema de Combate OBLIVIO - Arquitetura de Scripts

## 📋 Visão Geral

Este sistema implementa o combate por turnos conforme as regras do OBLIVIO. Os scripts foram criados com tipos de ação separados (Ação Regular, Movimento, Extra, Completa) para que você possa adicionar os custos depois, sem mexer na estrutura.

---

## 📦 Scripts Criados

### 1. **CombatManager.gd** (Principal)
**Arquivo**: `scripts/combat_manager.gd`

**Responsabilidade**: Orquestra todo o fluxo de combate.

**Principais Métodos**:
```gdscript
# Inicialização
func _inicializar_combate() -> void
func _calcular_iniciativa() -> void

# Fluxo de turno
func _avancar_turno() -> void
func _encontrar_proximo_combatente() -> Dictionary

# Ações
func _iniciar_ataque() -> void
func _iniciar_pericia() -> void
func _iniciar_habilidade() -> void
func _iniciar_item() -> void

# Processamento
func _processar_ataque(atacante, alvo, regioes) -> void
func _derrotar_combatente(combatente) -> void
func _verificar_fim_combate() -> void
```

**Sinais Emitidos**:
- `turno_iniciado(combatente)` - Quando um novo turno começa
- `turno_finalizado(combatente)` - Quando um turno termina
- `combate_iniciado` - Combate começou
- `combate_finalizado(resultado)` - Combate acabou
- `estado_atualizado` - Qualquer mudança no estado

**TODO (Implementar depois)**:
```gdscript
# Sistema de custos de ação
var pontos_acao: Dictionary = {
	"Ação Regular": null,      # A definir
	"Movimento": null,          # A definir
	"Extra": null,              # A definir
	"Completa": null            # A definir
}

func _consumir_pontos_acao(combatente, tipo_acao) -> bool
```

---

### 2. **ActionPanel.gd**
**Arquivo**: `scripts/action_panel.gd`

**Responsabilidade**: UI dos botões de ação do jogador.

**Principais Métodos**:
```gdscript
func ativar_para(combatente: Dictionary) -> void
func habilitar_acoes() -> void
func desabilitar_acoes() -> void

# Stubs para implementação futura
func mostrar_menu_pericias(combatente) -> void
func mostrar_menu_habilidades(combatente) -> void
func mostrar_menu_itens(combatente) -> void
```

**Sinais Emitidos**:
- `acao_atacar` - Jogador clicou "ATACAR"
- `acao_pericia` - Jogador clicou "PERÍCIA"
- `acao_habilidade` - Jogador clicou "HABILIDADE"
- `acao_item` - Jogador clicou "ITEM"

**Botões**:
```
⚔️  ATACAR
✨ PERÍCIA
💥 HABILIDADE
🎒 ITEM
➡️  PASSAR TURNO
```

---

### 3. **RegionalSelector.gd**
**Arquivo**: `scripts/regional_selector.gd`

**Responsabilidade**: Seleção visual de regiões de ataque (adapta o seletor-corpo.gd).

**Principais Métodos**:
```gdscript
func ativar_para_ataque() -> void
func ativar_para_defesa() -> void
func desativar() -> void
func obter_regioes_selecionadas() -> Array[String]
func contar_selecionadas() -> int
```

**Sinais Emitidos**:
- `regiao_selecionada(nome, indice)` - Quando região é clicada
- `selecao_confirmada(regioes)` - Quando jogador confirma
- `selecao_cancelada` - Quando jogador cancela

**Regiões Disponíveis**:
```
1. Torso
2. Braço Direito
3. Braço Esquerdo
4. Perna Direita
5. Perna Esquerda
```

---

### 4. **EnemyPanel.gd**
**Arquivo**: `scripts/enemy_panel.gd`

**Responsabilidade**: Lista e gerencia seleção de inimigos.

**Principais Métodos**:
```gdscript
func adicionar_inimigo(inimigo: Dictionary) -> void
func atualizar_inimigo(inimigo: Dictionary) -> void
func remover_inimigo(inimigo: Dictionary) -> void
func ativar_seletor_alvo() -> void
func desativar_seletor_alvo() -> void
func obter_inimigo_selecionado() -> Dictionary
```

**Sinais Emitidos**:
- `inimigo_selecionado(inimigo)` - Quando jogador seleciona um alvo

**Visual dos Inimigos**:
```
Nome  HP: 8/10  [████░░░░░░]
```

---

### 5. **PartyPanel.gd**
**Arquivo**: `scripts/party_panel.gd`

**Responsabilidade**: Mostra personagens do partido e indicador de turno.

**Principais Métodos**:
```gdscript
func adicionar_personagem(personagem: Dictionary) -> void
func atualizar_personagem(personagem: Dictionary) -> void
func indicar_personagem_ativo(personagem: Dictionary) -> void
func remover_destaque_turno() -> void
```

**Sinais Emitidos**: Nenhum (apenas leitura)

**Informações Mostradas**:
```
Nome do Personagem
HP: 15/15
Estresse: 5
```

---

### 6. **CombatLog.gd**
**Arquivo**: `scripts/combat_log.gd`

**Responsabilidade**: Registra e mostra histórico de eventos em tempo real.

**Principais Métodos**:
```gdscript
func registrar_evento(mensagem: String, tipo: String) -> void
func registrar_ataque(dados: Dictionary) -> void
func registrar_status(combatente: String, status: String, ativo: bool) -> void
func limpar_log() -> void
```

**Tipos de Evento**:
- `turno` - 🎯 Turno de alguém
- `acao` - ⚔️ Ação executada
- `info` - ℹ️ Informação geral
- `sucesso` - ✓ Sucesso
- `aviso` - ⚠️ Aviso
- `critico` - ✗ Evento crítico
- `movimento` - 🚶 Movimento

**Exemplo de Ataque Registrado**:
```
✓ Guerreiro atacou Goblin (Torso) - Dado: 5
  → DANO: 3
  → ESTRESSE: +1
```

---

## 🔌 Como Integrar à Cena Combat.tscn

### Passo 1: Adicionar nós à cena

Na sua `combat.tscn`, você precisa ter uma estrutura assim:

```
Control
├── MarginContainer
│   └── VBoxContainer
│       ├── TopBar
│       │   ├── PartyPanel (%PartyPanel)
│       │   ├── Battlefield (%Battlefield)
│       │   ├── EnemyPanel (%EnemyPanel)
│       │   ├── RegionalPanel (%RegionalPanel)
│       │   └── ActionPanel (%ActionPanel)
│       └── LogPanel (%LogPanel)
```

### Passo 2: Atribuir scripts aos nós

```
PartyPanel (PanelContainer) → party_panel.gd
EnemyPanel (PanelContainer) → enemy_panel.gd
RegionalPanel (PanelContainer) → regional_selector.gd
ActionPanel (PanelContainer) → action_panel.gd
LogPanel (RichTextLabel) → combat_log.gd
Control (raiz) → combat_manager.gd
```

### Passo 3: Configurar UniqueNames

Adicione `%` aos seguintes nós (clique direito → Renomear):

```
PartyPanel → %PartyPanel
EnemyPanel → %EnemyPanel
Battlefield → %Battlefield
RegionalPanel → %RegionalPanel
ActionPanel → %ActionPanel
LogPanel → %LogPanel
```

### Passo 4: Carregar Dados

No `CombatManager.gd`, substitua `_setup_exemplo()` para carregar dados reais:

```gdscript
func _inicializar_combate() -> void:
	# Carregar personagens e inimigos da cena/globais
	combatentes_jogador = CarregarPersonagens()  # Sua função
	combatentes_inimigo = CarregarInimigos()      # Sua função
	
	# Atualizar painéis
	party_panel.atualizar_todos(combatentes_jogador)
	enemy_panel.atualizar_todos(combatentes_inimigo)
	
	# Rest do código...
	_calcular_iniciativa()
	ordem_turno.sort_custom(...)
```

---

## 🎮 Fluxo de Combate

```
1. INICIALIZAR
   ├─ Calcular iniciativa
   ├─ Ordenar combatentes
   └─ Mostrar party + inimigos

2. TURNO DE JOGADOR
   ├─ Mostrar ActionPanel
   │
   ├─ SE ATACAR:
   │  ├─ Ativar RegionalSelector
   │  ├─ Jogador seleciona regiões (1-3)
   │  ├─ Ativar EnemyPanel seletor
   │  ├─ Jogador seleciona alvo
   │  ├─ Rolar D6 + calcular resultado
   │  ├─ Aplicar dano/estresse
   │  └─ Próximo turno
   │
   ├─ SE PERÍCIA/HABILIDADE/ITEM:
   │  ├─ Mostrar menu (stub)
   │  ├─ Executar efeito
   │  └─ Próximo turno
   │
   └─ SE PASSAR:
	  └─ Próximo turno

3. TURNO DE INIMIGO
   ├─ IA escolhe ação (stub)
   └─ Próximo turno

4. VERIFICAR FIM COMBATE
   ├─ SE todos inimigos mortos → Vitória
   ├─ SE todos jogadores mortos → Derrota
   └─ SENÃO → Próximo turno
```

---

## 📊 Estrutura de Dados - Combatente

```gdscript
{
	"nome": "Guerreiro",
	"tipo": "jogador",  # ou "inimigo"
	
	# Saúde
	"saude_maxima": 15,
	"saude_atual": 15,
	
	# Defesa
	"defesa_base": 2,
	
	# Dano
	"dano_arma": 2,
	"atributo_dano": 1,
	
	# Estresse por região
	"estresse_por_regiao": {
		"Torso": 0,
		"Braço Direito": 0,
		"Braço Esquerdo": 0,
		"Perna Direita": 0,
		"Perna Esquerda": 0
	},
	
	# Status ativos
	"status": [
		{"nome": "Defesa Reforçada", "duracao": 1},
		{"nome": "Ferido", "duracao": 2}
	],
	
	# Iniciativa (calculada)
	"iniciativa": 5
}
```

---

## 🚀 Próximos Passos

### Implementar Depois (Custos de Ação):

1. **Definir custos de ação**:
   ```gdscript
   ActionType.ACAO_REGULAR: custo em PA
   ActionType.MOVIMENTO: custo em PA
   ActionType.EXTRA: custo em PA
   ActionType.COMPLETA: custo em PA
   ```

2. **Adicionar sistema de P.A.**:
   - Cada combatente começa turno com P.A. máximo
   - Consumir P.A. ao executar ação
   - Se P.A. > 0, continua na ordem

3. **Expandir menus**:
   - `mostrar_menu_pericias()` - selecionar perícia
   - `mostrar_menu_habilidades()` - selecionar habilidade
   - `mostrar_menu_itens()` - selecionar item do inventário

4. **Implementar IA de inimigos**:
   - `_executar_turno_inimigo()` - decisão automática
   - Selecionar ação baseado em estado

5. **Efeitos visuais**:
   - Animar ataques no Battlefield
   - Highlight de regiões/inimigos
   - Feedback visual de dano

---

## 🔗 Referências de Regras OBLIVIO

- **Iniciativa**: Rolar D6 no começo do combate
- **Regiões**: 5 áreas (Torso, Braços, Pernas)
- **Categorias de Resultado**:
  - 6: Sucesso Extremo (2 acertos)
  - 4-5: Sucesso Regular (1 acerto)
  - 2-3: Falha Regular (0 acertos, +1 estresse)
  - 1: Falha Crítica (0 acertos, +2 estresse)
- **Estresse Crítico**: ≥ 12 (próxima falha crítica = morte)
- **Dano**: Aplicado quando sucessos ≥ proteção do alvo
