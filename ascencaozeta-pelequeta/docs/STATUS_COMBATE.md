# 🎮 Status da Tela de Combate OBLIVIO

**Data:** 16/05/2026  
**Status:** Em Progresso (60% Completo)

---

## ✅ Funcionalidades Implementadas

### 1. Sistema de Combatentes
- [x] CombatenteData com Atributos Fixos e Mutáveis
- [x] Cálculo automático de Atributos Mutáveis
- [x] Sistema de Estresse por Região
- [x] Transbordamento para Torso
- [x] Verificação de Desmaios (até 3)
- [x] Morte permanente
- [x] Templates de Inimigos (InimigoData)

### 2. Sistema de Perícias
- [x] 10 Perícias OBLIVIO implementadas
- [x] Testes de Perícia com D6 + Atributo + Treino
- [x] Categorização de Resultados (Crítico, Normal, Fracasso)
- [x] Margens de Sucesso
- [x] Cálculo de Atributos corretos

### 3. Interface de Combate
- [x] Panel de Inimigos (com seleção de alvo)
- [x] Panel de Personagens (com status)
- [x] Panel de Ações (Atacar, Perícia, Habilidade, Item)
- [x] Seletor Regional (escolher regiões de ataque 1-3)
- [x] Log de Combate (histórico de eventos)

### 4. Fluxo de Combate Básico
- [x] Iniciativa (rola D6 para cada combatente)
- [x] Ordem de Turno (por Iniciativa descendente)
- [x] Turno de Jogador (múltiplas ações)
- [x] Turno de Inimigo (IA placeholder)
- [x] Aplicação de Estresse por Ataque
- [x] Verificação de Desmaio após ataque
- [x] Detecção de Vitória/Derrota
- [x] Passar Turno (botão PASSAR TURNO)

---

## 🔧 Funcionalidades Parcialmente Implementadas

### 1. Sistema de Dano
- [x] Aplicação básica de Estresse
- [ ] Cálculo de Dano baseado em Categorias de Resultado (1-6 no D6)
- [ ] Modificadores de Dano (Atributo Dano, Habilidades, Itens)
- [ ] Redução por Proteção

### 2. Habilidades
- [x] Base de Dados de Habilidades (6+ implementadas)
- [ ] Sistema de PA (Pontos de Ação) completo
- [ ] Efeitos de Habilidades (cura, dano extra, etc)
- [ ] Menu de Seleção de Habilidades
- [ ] Validação de Custo PA

### 3. IA de Inimigos
- [x] Placeholder que passa turno
- [ ] Seleção de ações (atacar, defender, habilidades)
- [ ] Seleção de alvo inteligente
- [ ] Seleção de regiões de ataque

---

## 🚧 Não Implementado

### 1. Movimento e Posicionamento
- [ ] Sistema de Grid/Posições
- [ ] Ações de Movimento
- [ ] Distância e Alcance
- [ ] Formações de Combate

### 2. Status e Efeitos
- [ ] Efeitos de Status (envenenado, em chamas, etc)
- [ ] Duração de Efeitos
- [ ] Recuperação de Efeitos

### 3. Itens e Equipamento
- [ ] Sistema de Inventário
- [ ] Menu de Itens em Combate
- [ ] Bônus de Equipamento
- [ ] Consumíveis (poções, etc)

### 4. Sistema Completo de Perícias
- [ ] Testes de Perícia em Combate
- [ ] Perícias de Defesa (Esquiva vs Duelo)
- [ ] Perícias de Suporte (Medicina, Liderança)

---

## 📊 Arquitetura Atual

```
CombatManager (Orquestrador)
├── ActionPanel (Botões: Atacar, Perícia, Habilidade, Item)
├── RegionalSelector (Selecionar 1-3 regiões)
├── EnemyPanel (Lista de inimigos + HP/Estresse)
├── PartyPanel (Lista de personagens + Status)
├── CombatLog (Histórico de eventos)
└── Combatentes
    ├── CombatenteData (Jogador)
    ├── CombatenteData (Inimigo 1)
    ├── CombatenteData (Inimigo 2)
    └── ...
```

**Dados Atualizados Para:**
- Atributos Fixos e Mutáveis conforme OBLIVIO 2.2
- Estresse por Região (não HP total)
- Perícias com cálculo correto
- Habilidades OBLIVIO

---

## 🎯 Próximas Prioridades

### Priority 1: Completar Sistema de Dano
- [ ] Categorizar resultado do D6 (1: Falha, 2-3: Sucesso, 4-5: Sucesso+, 6: Crítico)
- [ ] Dano = Categoria × Atributo Dano
- [ ] Aplicar Estresse com bônus/redução por modificadores
- [ ] Implementar Proteção como redução de Dano

### Priority 2: Sistema de PA Completo
- [ ] Restaurar PA no início de cada turno
- [ ] Validar Custo PA antes de ação
- [ ] Mostrar PA disponível no UI
- [ ] Bloquear ações quando PA insuficiente

### Priority 3: IA de Inimigos
- [ ] Escolher alvo prioritário
- [ ] Avaliar ações disponíveis
- [ ] Seleção inteligente de ações
- [ ] Padrão de comportamento (agressivo, defensivo, etc)

### Priority 4: UI Melhorada
- [ ] Mostrar Atributos Mutáveis visualmente
- [ ] Indicadores de Estresse por Região
- [ ] Barra visual de Fôlego/Recuperação
- [ ] Tooltip com detalhes de Atributos

---

## 🐛 Bugs Corrigidos Nesta Versão

- [x] Erro de `.get()` com 2 argumentos em CombatManager (linha 94)
- [x] Erro de `.get()` com 2 argumentos em PericiaData (linha 160)
- [x] Erro de `.get()` com 2 argumentos em EnemyPanel (linha 107)
- [x] Atributos incorretos em testar_pericia() (inteligência, agilidade, vontade, vitalidade)
- [x] Cálculo de Atributos Mutáveis não implementado

---

## 📝 Última Atualização

- **Data**: 16/05/2026
- **Mudanças**: Implementação completa de Atributos Mutáveis, correção de erros de sintaxe
- **Tester**: Sistema compila sem erros
