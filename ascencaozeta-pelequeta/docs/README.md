# 📚 Documentação - Ascensão Zeta Pelequeta

Bem-vindo à documentação do projeto! Aqui você encontrará guias, referências e especificações para o sistema de combate OBLIVIO implementado em Godot.

---

## 📑 Índice de Documentação

### 🎮 Sistema de Combate
- [**OBLIVIO_REFERENCE.md**](../scripts/OBLIVIO_REFERENCE.md) - Referência completa do sistema OBLIVIO
  - Características do sistema D6 brasileiro
  - 5 regiões corporais
  - Categorias de ações
  - Sistema de estresse psicológico

- [**IMPLEMENTATION_GUIDE.md**](../scripts/IMPLEMENTATION_GUIDE.md) - Guia de implementação técnica
  - Arquitetura de componentes
  - Fluxo de turno
  - Sistema de sinais (signals)
  - Estrutura de dados de combatentes

- [**COMBAT_FIXES_v2.md**](../scripts/COMBAT_FIXES_v2.md) - Histórico de correções
  - Bugs encontrados e resolvidos
  - Padrões de solução
  - Validação de dados

### 🛡️ Melhorias e Padrões
- [**DEFENSIVE_IMPROVEMENTS.md**](../scripts/DEFENSIVE_IMPROVEMENTS.md) - Padrões defensivos de código
  - Validação de dicionários
  - Tratamento de erros
  - Autorecuperação
  - Checklist de implementação

### 📋 Documentação Geral
- [**INDEX_COMPLETE.md**](../scripts/INDEX_COMPLETE.md) - Índice completo de scripts e estruturas

---

## 🚀 Quick Start

### 1️⃣ Entender o Sistema
Leia primeiro: [OBLIVIO_REFERENCE.md](../scripts/OBLIVIO_REFERENCE.md)

### 2️⃣ Implementação Técnica
Depois: [IMPLEMENTATION_GUIDE.md](../scripts/IMPLEMENTATION_GUIDE.md)

### 3️⃣ Padrões de Código
Para manutenção: [DEFENSIVE_IMPROVEMENTS.md](../scripts/DEFENSIVE_IMPROVEMENTS.md)

### 4️⃣ Debugging
Se encontrar problemas: [COMBAT_FIXES_v2.md](../scripts/COMBAT_FIXES_v2.md)

---

## 🎯 Estrutura do Projeto

```
ascencaozeta-pelequeta/
├── assets/              # Sprites, imagens, fontes
├── fonts/               # Fontes personalizadas
├── prefabs/             # Componentes pré-feitos
├── scenes/              # Cenas Godot (combat.tscn, player.tscn, etc)
├── scripts/             # Scripts GDScript
│   ├── combat_manager.gd
│   ├── action_panel.gd
│   ├── enemy_panel.gd
│   ├── party_panel.gd
│   ├── regional_selector.gd
│   ├── combat_log.gd
│   └── [DOCUMENTAÇÕES]
├── docs/                # 📁 Esta pasta (documentação)
└── project.godot        # Configuração do projeto
```

---

## 📝 Documentações por Tópico

### 🎲 Mecânicas OBLIVIO
| Documento | Conteúdo |
|-----------|----------|
| OBLIVIO_REFERENCE.md | Regras do sistema D6 |
| COMBAT_FIXES_v2.md | Como foram implementadas |

### 💻 Código e Arquitetura
| Documento | Conteúdo |
|-----------|----------|
| IMPLEMENTATION_GUIDE.md | Design de componentes |
| INDEX_COMPLETE.md | Referência de todos os scripts |
| DEFENSIVE_IMPROVEMENTS.md | Padrões de validação |

### 🔧 Desenvolvimento
| Documento | Conteúdo |
|-----------|----------|
| COMBAT_FIXES_v2.md | Bugs resolvidos |
| DEFENSIVE_IMPROVEMENTS.md | Padrões de erro |

---

## 🎓 Guias por Perfil

### 👨‍💼 Gerente de Projeto
Leia: OBLIVIO_REFERENCE.md + IMPLEMENTATION_GUIDE.md (seção Arquitetura)

### 👨‍💻 Desenvolvedor (Novo no Projeto)
1. OBLIVIO_REFERENCE.md (entender as regras)
2. IMPLEMENTATION_GUIDE.md (entender a arquitetura)
3. INDEX_COMPLETE.md (referência de componentes)

### 🐛 Debugador
1. DEFENSIVE_IMPROVEMENTS.md (padrões de erro)
2. COMBAT_FIXES_v2.md (bugs conhecidos)
3. Scripts correspondentes (código-fonte)

### 🎨 Designer de Conteúdo (Inimigos, Habilidades)
1. OBLIVIO_REFERENCE.md (estrutura de dados)
2. IMPLEMENTATION_GUIDE.md (seção "Estrutura de Combatentes")

---

## 📞 Referência Rápida

### Arquivo de Configuração Principal
- `project.godot` - Configurações do Godot Engine

### Cenas Principais
- `combat.tscn` - Cena de combate (raiz de todo o sistema)
- `player.tscn` - Jogador (personagem controlável)
- `main.tscn` - Menu principal

### Scripts Críticos
- `combat_manager.gd` (470 linhas) - Orquestrador central
- `action_panel.gd` (170 linhas) - Interface de ações
- `regional_selector.gd` (220 linhas) - Seletor de regiões

---

## 🔗 Links Úteis

### Dentro do Projeto
- [Scripts](../scripts) - Código-fonte GDScript
- [Scenes](../scenes) - Arquivos de cena Godot

### Externo
- [Godot Engine](https://godotengine.org/) - Engine oficial
- [GDScript Docs](https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/index.html) - Linguagem GDScript

---

## 📊 Status do Projeto

### ✅ Implementado
- [x] Sistema de turnos baseado em iniciativa
- [x] Seleção de regiões corporais
- [x] Cálculo de dano e estresse
- [x] Interface de combate
- [x] Logs de combate coloridos
- [x] Detecção de derrotas
- [x] Validação defensiva de dados

### 🟡 Parcialmente Implementado
- [ ] Sistema de Pontos de Ação (PA)
- [ ] Menu de habilidades
- [ ] Menu de itens
- [ ] IA de inimigos

### ⭕ Não Implementado
- [ ] Persistência de dados
- [ ] Modo multijogador
- [ ] Cinematics

---

## 🎯 Próximas Prioridades

1. **Implementar Sistema PA** - Usar enum ActionType e custos_pa definidos
2. **Expandir IA de Inimigos** - Substituir placeholder em `_executar_turno_inimigo()`
3. **Adicionar Habilidades** - Implementar método stubs em action_panel.gd
4. **Testes de Integração** - Validar com múltiplos combatentes

---

## 📖 Convenções de Nomenclatura

| Tipo | Convenção | Exemplo |
|------|-----------|---------|
| Scripts | snake_case | `combat_manager.gd` |
| Funções | snake_case | `_processar_ataque()` |
| Sinais | snake_case | `turno_finalizado` |
| Constantes | UPPER_SNAKE_CASE | `DANO_BASE = 2` |
| Classes/Enums | PascalCase | `ActionType` |
| Variáveis | snake_case | `saude_atual` |

---

## 🚨 Troubleshooting

### Erro: "Invalid access to property or key 'saude_atual'"
**Solução:** Ver [DEFENSIVE_IMPROVEMENTS.md](../scripts/DEFENSIVE_IMPROVEMENTS.md) - Seção "Padrão de Validação"

### Erro: "Null instance" ao acessar log_panel
**Solução:** Ver [COMBAT_FIXES_v2.md](../scripts/COMBAT_FIXES_v2.md) - "Problema: Null Reference"

### UI Elements Não Aparecem ou Não Respondem ao Click
**Solução:** Ver [COMBAT_FIXES_v2.md](../scripts/COMBAT_FIXES_v2.md) - "Problema: Layout Quebrado"

---

## 📝 Contribuindo

Ao fazer mudanças no sistema:

1. ✅ Testar com múltiplos combatantes
2. ✅ Validar com dados inválidos (usar padrão em DEFENSIVE_IMPROVEMENTS.md)
3. ✅ Atualizar documentação relevante
4. ✅ Adicionar comentários no código
5. ✅ Verificar compatibilidade com OBLIVIO

---

## 📅 Histórico de Versões

| Versão | Data | Mudanças Principais |
|--------|------|-------------------|
| 2.1 | 07/05/2026 | Adicionadas validações defensivas, novo DEFENSIVE_IMPROVEMENTS.md |
| 2.0 | 07/05/2026 | Sistema completo de combate implementado |
| 1.0 | 05/05/2026 | Prototipo inicial |

---

## 📧 Suporte

Para dúvidas sobre:
- **Regras OBLIVIO**: Consulte OBLIVIO_REFERENCE.md
- **Código GDScript**: Consulte o script específico com comentários
- **Arquitetura**: Consulte IMPLEMENTATION_GUIDE.md
- **Bugs**: Consulte COMBAT_FIXES_v2.md

---

**Última atualização:** 07/05/2026  
**Versão da Documentação:** 2.1  
**Status:** ✅ Completa
