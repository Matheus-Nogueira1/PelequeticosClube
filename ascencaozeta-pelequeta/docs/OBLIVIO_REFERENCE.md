# 📖 Referência OBLIVIO - Mapeamento de Regras

**Objetivo:** Mapear as regras do OBLIVIO diretamente para código GDScript

---

## 🎯 Conceitos-Chave OBLIVIO → Godot

### 1. Atributos (5 Pilares)

| OBLIVIO | Godot | Implementação |
|---------|-------|---|
| Força | `force` | Aumenta dano |
| Inteligência | `intelligence` | Aumenta perícia intelectual |
| Agilidade | `agility` | Aumenta iniciativa/defesa |
| Vontade | `will` | Resiste estresse |
| Vitalidade | `vitality` | HP máximo |

**Atual (Simplificado):**
```gdscript
combatente = {
    "dano_arma": 2,      # ← Força (será atributo_forca)
    "defesa_base": 2,    # ← Agilidade
    "saude_maxima": 15   # ← Vitalidade
}
```

**Futuro (Completo):**
```gdscript
combatente = {
    "atributo_forca": 3,
    "atributo_inteligencia": 2,
    "atributo_agilidade": 2,
    "atributo_vontade": 3,
    "atributo_vitalidade": 3,
    "saude_maxima": 15,  # Baseado em Vitalidade
    "defesa_base": 2,    # Baseado em Agilidade
    "dano_arma": 2       # Baseado em Força + arma
}
```

---

### 2. Perícias

**OBLIVIO:** Perícias treinadas modificadas por atributo

**Exemplo:**
- Perícia: "Ataque com Espada"
- Atributo: Força
- Treino: 2
- Rolagem: 1D6 + Força + Treino = ?

**Godot (Futuro):**
```gdscript
var pericias = {
    "ataque_espada": {
        "atributo": "forca",
        "treino": 2
    },
    "esquiva": {
        "atributo": "agilidade",
        "treino": 1
    }
}

func testar_pericia(pericia_nome: String, dificuldade: int = 0) -> bool:
    var pericia = pericias[pericia_nome]
    var attr_valor = combatente_ativo["atributo_" + pericia["atributo"]]
    var resultado = randi_range(1, 6) + attr_valor + pericia["treino"]
    return resultado > dificuldade
```

---

### 3. Pontos de Ação (PA)

**OBLIVIO:**
- Cada combatente tem 3 PA por turno
- Ações consomem PA:
  - Ação Regular: 1 PA
  - Movimento: 1 PA
  - Ação Extra: 2 PA (se houver PA)
  - Ação Completa: consome todos

**Godot (Pronto para implementar):**
```gdscript
enum ActionType {
    ACAO_REGULAR,    # 1 PA
    MOVIMENTO,       # 1 PA
    EXTRA,           # 2 PA
    COMPLETA         # 3 PA
}

var custos_pa = {
    ActionType.ACAO_REGULAR: 1,
    ActionType.MOVIMENTO: 1,
    ActionType.EXTRA: 2,
    ActionType.COMPLETA: 3
}

func consumir_pontos_acao(tipo: ActionType) -> bool:
    var custo = custos_pa[tipo]
    if combatente_ativo["pontos_acao_atuais"] >= custo:
        combatente_ativo["pontos_acao_atuais"] -= custo
        return true
    return false
```

---

### 4. Combate - Processo Completo

**Fluxo OBLIVIO:**

```
1. INICIATIVA
   ↓
   Cada combatente rola 1D6
   Ordem: maior para menor

2. TURNO (por combatente)
   ↓
   A. Recebe 3 PA
   B. Escolhe ações até gastar PA
   C. FIM DO TURNO → Próximo combatente

3. AÇÃO: ATACAR (1 PA)
   ↓
   A. Escolhe 1-3 regiões do corpo
   B. Escolhe alvo
   C. Rola 1D6 (resultado)
      - 6: Sucesso Extremo (dano máximo + crítico)
      - 4-5: Sucesso Regular (dano normal)
      - 2-3: Falha Regular (sem dano)
      - 1: Falha Crítica (danifica a si)
   D. Aplica dano
   E. Aplica estresse nas regiões
   F. Verifica morte

4. RESULTADO
   - Morte: sai da luta
   - Sobrevive: próxima ação OU próximo turno
```

**Godot (Atual):**
```gdscript
# 1. Iniciativa ✅
func _calcular_iniciativa():
    for combatente in ordem_turno:
        combatente["iniciativa"] = randi_range(1, 6)

# 2. Turno ✅
func _avancar_turno():
    combatente_ativo = _encontrar_proximo_combatente()
    # PA será adicionado aqui quando implementado

# 3. Atacar ✅
func _iniciar_ataque():
    # Mostra regional_selector

func _processar_ataque(atacante, alvo, regioes):
    var dado = randi_range(1, 6)
    var categoria = _avaliar_categoria_resultado(dado)
    # Calcula dano baseado em categoria
    # Aplica dano e estresse

# 4. Resultado ✅
func _verificar_fim_combate():
    if qualquer_lado_morreu:
        _finalizar_combate()
```

---

### 5. Regiões de Corpo

**OBLIVIO:** Corpo dividido em 5 regiões

| Região | Efeitos |
|--------|---------|
| Torso | Centro do corpo, vital |
| Braço Direito | Reduz ações com armas de 1 mão |
| Braço Esquerdo | Afeta defesa com escudo |
| Perna Direita | Reduz movimento |
| Perna Esquerda | Reduz movimento |

**Godot (Atual):**
```gdscript
"estresse_por_regiao": {
    "Torso": 0,
    "Braço Direito": 0,
    "Braço Esquerdo": 0,
    "Perna Direita": 0,
    "Perna Esquerda": 0
}

# Aplicar estresse
for regiao in regioes:
    alvo["estresse_por_regiao"][regiao] += estresse_gerado
```

---

### 6. Estresse

**OBLIVIO:**
- Acumula por região
- Limiares psicológicos (8, 12, 16 estresse)
- Ao ultrapassar: efeitos psíquicos

**Godot (Atual - Parcial):**
```gdscript
# PartyPanel mostra:
if estresse_total >= 12:
    color = RED  # Crítico
elif estresse_total >= 8:
    color = YELLOW  # Alto

# Futuro: implementar efeitos psicológicos
# - 8+ Estresse: -1 ação por turno
# - 12+ Estresse: -2 ações por turno
# - 16+ Estresse: enlouquece, saí da luta
```

---

### 7. Dado (D6)

**OBLIVIO:** Tudo baseado em D6 único

| Resultado | Interpretação |
|-----------|---|
| 6 | Sucesso Extremo |
| 4-5 | Sucesso Regular |
| 2-3 | Falha Regular |
| 1 | Falha Crítica |

**Godot:**
```gdscript
func _avaliar_categoria_resultado(dado: int) -> String:
    match dado:
        6: return "Sucesso Extremo"
        4, 5: return "Sucesso Regular"
        2, 3: return "Falha Regular"
        1: return "Falha Crítica"
        _: return "Indefinido"
```

---

## 🔄 Fluxo Completo (Mapeado)

```
INICIALIZAÇÃO
├─ Carrega combatentes (jogador + inimigos)
├─ Calcula Iniciativa (1D6)
├─ Ordena por iniciativa
└─ Vai para TURNO 1

TURNO (Combatente X)
├─ Restaura 3 PA
├─ Jogador:
│  └─ Escolhe ação (gastar PA)
│     ├─ ATACAR (1 PA)
│     │  ├─ Seleciona 1-3 regiões
│     │  ├─ Seleciona alvo
│     │  ├─ Rola 1D6
│     │  ├─ Aplica dano (segundo resultado)
│     │  ├─ Aplica estresse (por região)
│     │  ├─ Verifica morte
│     │  └─ Se vivo: voltar passo 2
│     │
│     ├─ PERÍCIA (1 PA)
│     │  ├─ Escolhe perícia
│     │  ├─ Rola teste (D6 + atributo + treino vs dificuldade)
│     │  └─ Aplica efeito
│     │
│     ├─ HABILIDADE (2-3 PA)
│     │  └─ Efeito especial
│     │
│     ├─ ITEM (1-2 PA)
│     │  └─ Usa do inventário
│     │
│     └─ PASSAR TURNO
│        └─ Vai para próximo combatente
│
└─ Inimigo: IA decide ação

VERIFICA FIM
├─ Algum lado morreu?
│  ├─ SIM: Combate termina (vitória/derrota)
│  └─ NÃO: Volta ao TURNO
└─ [LOOP até fim]
```

---

## 📊 Tabela de Dano

**Atual (Simplificado):**
```
Resultado → Dano
Qualquer → 2 (fixo)
```

**OBLIVIO (Correto):**
```
Sucesso Extremo → Dano máximo (Força + arma + crítico)
Sucesso Regular → Dano normal (Força + arma)
Falha Regular → 0 dano
Falha Crítica → Danifica a si (dano mínimo)
```

**Godot (Futuro):**
```gdscript
func calcular_dano(categoria: String, atacante: Dictionary) -> int:
    var dano_base = atacante["dano_arma"] + atacante["atributo_forca"]
    
    match categoria:
        "Sucesso Extremo":
            return dano_base + 2  # Crítico
        "Sucesso Regular":
            return dano_base
        "Falha Regular":
            return 0
        "Falha Crítica":
            return dano_base * -1  # Danifica a si
    return 0
```

---

## 🎯 Checklist de Fidelidade OBLIVIO

### Implementado ✅
- [x] D6 para iniciativa
- [x] Ordem de turno por iniciativa
- [x] Regiões de corpo (5)
- [x] Seleção 1-3 regiões por ataque
- [x] Categorias de resultado (D6)
- [x] Estresse por região
- [x] Log colorido de eventos
- [x] Estrutura de atributos (pronta)

### Não Implementado ❌
- [ ] PA (Pontos de Ação)
- [ ] Testes de Perícia
- [ ] Limiares de Estresse (psicológicos)
- [ ] Modificadores de dano por atributo
- [ ] Modificadores de defesa
- [ ] Habilidades especiais
- [ ] Status (envenenado, queimado, etc)
- [ ] IA inteligente
- [ ] Animações

---

## 🚀 Próximas Implementações (Ordem OBLIVIO)

### Priority 1: Pontos de Ação (PA)
**Por quê:** É o pilar da mecânica de ação em OBLIVIO
**Tempo:** 30 min
**Complexidade:** Baixa

### Priority 2: Modificadores de Dano
**Por quê:** Força afeta dano direto
**Tempo:** 15 min
**Complexidade:** Muito Baixa

### Priority 3: Testes de Perícia
**Por quê:** Ações secundárias precisam de testes
**Tempo:** 1 hora
**Complexidade:** Média

### Priority 4: Limiares de Estresse
**Por quê:** Efeitos psicológicos definem condição
**Tempo:** 30 min
**Complexidade:** Baixa

### Priority 5: IA de Inimigos
**Por quê:** Combate automático requer IA
**Tempo:** 1 hora
**Complexidade:** Média

---

## 📚 Referências

- **OBLIVIO Livro de Regras** - Capítulo 3: Combate
- **Godot Docs** - Signals, Nodes, GDScript

---

**Versão:** 1.0  
**Data:** 06/05/2026  
**Fidelidade OBLIVIO:** ~60% (core implementado, extras pendentes)
