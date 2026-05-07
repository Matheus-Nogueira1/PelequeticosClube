# 🎮 Sistema de Combate OBLIVIO - Índice de Arquivos

Documentação completa do sistema de combate criado para `ascencaozeta-pelequeta`.

---

## 📚 Arquivos de Documentação

### 1. **COMBAT_SYSTEM_README.md** 🔴 COMECE AQUI
Visão geral completa do sistema:
- Descrição de cada script
- Métodos principais
- Sinais emitidos
- Estrutura de dados
- Fluxo de combate
- TODO list para implementações futuras

**Quando ler**: Primeira vez para entender a arquitetura geral

---

### 2. **INTEGRATION_EXAMPLE.md** 🟠 IMPLEMENTAÇÃO
Guia passo-a-passo de integração à cena:
- Estrutura visual de nós
- Como atribuir scripts
- Como marcar unique names
- Como carregar dados
- Debugging
- Checklist completo

**Quando ler**: Quando for integrar à cena `combat.tscn`

---

### 3. **SIGNALS_REFERENCE.md** 🟡 COMUNICAÇÃO
Referência rápida de sinais:
- Diagrama de comunicação
- Sinais de cada script
- Fluxo de exemplo (ataque)
- Tabela de conexões
- Como adicionar novo sinal

**Quando ler**: Quando precisar entender comunicação entre scripts

---

### 4. **ARCHITECTURE_VISUAL.md** 🟢 VISUAL
Diagramas e layouts:
- Estrutura visual de nós
- Estados da UI
- Fluxo de estados
- Mapeamento de cores
- Estrutura de dados visual
- Fluxograma completo

**Quando ler**: Quando quiser ver como fica visualmente

---

## 💻 Scripts Criados

### **combat_manager.gd** (PRINCIPAL)
**Localização**: `scripts/combat_manager.gd`

Orquestra todo o combate:
- Inicialização (carrega dados, calcula iniciativa)
- Turnos (próximo combatente, ativa ações)
- Processamento de ataque (rola dados, aplica dano)
- Fin de combate (verifica derrotas)

**Tamanho**: ~600 linhas
**Complexidade**: Alta (coordena tudo)
**Próximas adições**: Sistema de custos de ação

---

### **action_panel.gd**
**Localização**: `scripts/action_panel.gd`

UI dos botões de ação:
- ⚔️ ATACAR
- ✨ PERÍCIA
- 💥 HABILIDADE
- 🎒 ITEM
- ➡️ PASSAR TURNO

**Tamanho**: ~150 linhas
**Complexidade**: Baixa
**Próximas adições**: Menus (perícias, habilidades, itens)

---

### **regional_selector.gd**
**Localização**: `scripts/regional_selector.gd`

Seleção visual de regiões de ataque:
- 5 regiões clicáveis (Torso, Braços, Pernas)
- Seleção de 1-3 regiões
- Confirmação/cancelamento
- Modo ataque/defesa

**Tamanho**: ~180 linhas
**Complexidade**: Média
**Status**: Completo

---

### **enemy_panel.gd**
**Localização**: `scripts/enemy_panel.gd`

Gerenciamento de inimigos:
- Lista com health-bars visuais
- Seleção de alvo
- Modo seletor
- Remoção ao ser derrotado

**Tamanho**: ~180 linhas
**Complexidade**: Média
**Status**: Completo

---

### **party_panel.gd**
**Localização**: `scripts/party_panel.gd`

Exibição do partido (personagens):
- Lista com HP, Estresse, Status
- Destaque de turno ativo
- Cores dinâmicas
- Atualização em tempo real

**Tamanho**: ~200 linhas
**Complexidade**: Média
**Status**: Completo

---

### **combat_log.gd**
**Localização**: `scripts/combat_log.gd`

Histórico de combate:
- Eventos coloridos por tipo
- Registro de ataques com resultado
- Rastreamento de status
- Auto-cleanup de linhas antigas

**Tamanho**: ~200 linhas
**Complexidade**: Baixa
**Status**: Completo

---

## 📖 Como Usar Esta Documentação

### Para Iniciantes
1. Leia **COMBAT_SYSTEM_README.md** (visão geral)
2. Veja **ARCHITECTURE_VISUAL.md** (como fica visualmente)
3. Siga **INTEGRATION_EXAMPLE.md** (passo-a-passo)

### Para Desenvolvedores
1. Abra os scripts e leia o código
2. Use **SIGNALS_REFERENCE.md** para entender comunicação
3. Use comentários `# TODO:` nos scripts para saber o que falta

### Para Debug
1. Verifique **SIGNALS_REFERENCE.md** (seção Debug)
2. Adicione prints nos métodos
3. Use o Console (Output) do Godot

---

## 🔄 Fluxo de Leitura Recomendado

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  Primeira Vez?                                          │
│     ↓                                                   │
│  COMBAT_SYSTEM_README.md                               │
│     ↓                                                   │
│  ARCHITECTURE_VISUAL.md                                │
│     ↓                                                   │
│  INTEGRATION_EXAMPLE.md ← IMPLEMENTAR                  │
│     ↓                                                   │
│  SIGNALS_REFERENCE.md (se não funcionar)              │
│     ↓                                                   │
│  Scripts ← Ler código                                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 Objetivos de Cada Arquivo

| Arquivo | Objetivo | Audiência |
|---------|----------|-----------|
| COMBAT_SYSTEM_README.md | Entender arquitetura | Todos |
| INTEGRATION_EXAMPLE.md | Implementar na cena | Devs |
| SIGNALS_REFERENCE.md | Entender comunicação | Devs Avançados |
| ARCHITECTURE_VISUAL.md | Visualizar layout | Todos |
| combat_manager.gd | Orquestrar combate | Devs |
| action_panel.gd | UI de ações | Devs |
| regional_selector.gd | Selecionar regiões | Devs |
| enemy_panel.gd | Selecionar alvo | Devs |
| party_panel.gd | Mostrar personagens | Devs |
| combat_log.gd | Registrar eventos | Devs |

---

## 🚀 Próximas Implementações

### Imediatas (Você vai querer fazer logo)
- [ ] Integrar à cena `combat.tscn`
- [ ] Testar fluxo básico de ataque
- [ ] Carregar dados reais (não só exemplo)

### Curto Prazo (Próximas semanas)
- [ ] Definir custos de ação (tipos: Regular, Movimento, Extra, Completa)
- [ ] Implementar sistema de P.A. (Pontos de Ação)
- [ ] Expandir menus (perícias, habilidades, itens)

### Médio Prazo (Próximos passos)
- [ ] IA de inimigos
- [ ] Efeitos visuais (animações, highlights)
- [ ] Sistema de inventário
- [ ] Fim de combate (resultado, XP, loot)

### Longo Prazo (Quando tudo acima funcionar)
- [ ] Balanceamento (vida, dano, proteção)
- [ ] Perícias especiais
- [ ] Habilidades únicas por classe
- [ ] Combates em grupo (múltiplos aliados)

---

## 📋 Estrutura de Pasta

```
scripts/
├── COMBAT_SYSTEM_README.md      ← Você está aqui (visão geral)
├── INTEGRATION_EXAMPLE.md       ← Guia de implementação
├── SIGNALS_REFERENCE.md         ← Referência de sinais
├── ARCHITECTURE_VISUAL.md       ← Diagramas e layouts
│
├── combat_manager.gd            ← Principal
├── action_panel.gd              ← Botões de ação
├── regional_selector.gd         ← Seleção de regiões
├── enemy_panel.gd               ← Lista de inimigos
├── party_panel.gd               ← Lista de personagens
├── combat_log.gd                ← Histórico
│
├── rolagens-dados-d6.gd         ← Existente (rolagem)
├── seletor-corpo.gd             ← Existente (regiões)
├── dados.gd                     ← Existente (dados)
│
└── [outros scripts já existentes]
```

---

## 🔗 Dependências Entre Arquivos

```
combat_manager.gd (PRINCIPAL)
├── Conecta sinais de:
│   ├── action_panel.gd
│   ├── regional_selector.gd
│   └── enemy_panel.gd
│
├── Atualiza:
│   ├── party_panel.gd
│   ├── enemy_panel.gd
│   └── combat_log.gd
│
└── Usa dados de:
    └── rolagens-dados-d6.gd (para D6 no futuro)
```

---

## 💡 Dicas Importantes

1. **Não edite os scripts listados em "Próximas Implementações"** - deixe os TODOs como estão
2. **Use unique_name (%)** para referenciar nós na cena
3. **Confira prints no Output** para debug
4. **Teste fluxo básico primeiro** antes de implementar menus
5. **Leia INTEGRATION_EXAMPLE.md** quando for integrar à cena

---

## ❓ Perguntas Frequentes

**P: Por onde começo?**
R: Leia COMBAT_SYSTEM_README.md, depois INTEGRATION_EXAMPLE.md

**P: Por que regiao_selecionada aparece em múltiplos arquivos?**
R: RegionalSelector é um "adapter" visual que encapsula o seletor-corpo.gd existente

**P: Onde fico os custos de ação (PA)?**
R: Serão adicionados em `pontos_acao_por_tipo` em CombatManager.gd quando você decidir os valores

**P: Como adiciono minhas perícias/habilidades?**
R: Implemente os stubs em ActionPanel.gd (`mostrar_menu_pericias`, etc)

**P: Por que ainda não tem IA?**
R: Deixei pronto no stub `_executar_turno_inimigo()` - você implementa conforme quiser

---

## 📞 Referência Rápida - Arquivos

```
Preciso entender como funciona...
├─ ... o sistema em geral?
│  └─→ COMBAT_SYSTEM_README.md
├─ ... como integrar?
│  └─→ INTEGRATION_EXAMPLE.md
├─ ... os sinais?
│  └─→ SIGNALS_REFERENCE.md
├─ ... o visual?
│  └─→ ARCHITECTURE_VISUAL.md
└─ ... um script específico?
   └─→ Leia o código (tem comentários!)
```

---

## ✅ Status de Implementação

```
✅ CombatManager.gd           - Funcional (TODOs marcados)
✅ ActionPanel.gd            - Funcional (stubs prontos)
✅ RegionalSelector.gd       - Funcional
✅ EnemyPanel.gd             - Funcional
✅ PartyPanel.gd             - Funcional
✅ CombatLog.gd              - Funcional
⏳ Menus de ações            - Stub (pronto para implementar)
⏳ Custos de ação            - Stub (pronto para implementar)
⏳ IA de inimigos            - Stub (pronto para implementar)
⏳ Efeitos visuais           - Stub (pronto para implementar)
⏳ Fim de combate            - Stub (pronto para implementar)
```

---

## 🎓 Próximo Passo

👉 **Abra `INTEGRATION_EXAMPLE.md` e siga o passo-a-passo!**

Cada seção é numerada e tem instruções claras. Quando terminar, sua cena de combate estará funcionando com fluxo básico de ataque.

Boa sorte! 🚀
