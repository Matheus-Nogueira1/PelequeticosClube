# 📖 Guia de Implementação - Sistema de Combate OBLIVIO

**Objetivo:** Integrar sistema de combate OBLIVIO completo e funcional no seu projeto Godot.

**Tempo estimado:** 30 minutos (primeira vez)

---

## 📌 Pré-Requisitos

- [x] Godot 4.6+
- [x] GDScript básico
- [x] Familiaridade com sinais Godot
- [x] OBLIVIO (regras de combate)

---

## ✅ Passo 1: Arquivos Já Estão Criados

Você já tem tudo pronto:

```
scripts/
├── combat_manager.gd         (orquestra o combate)
├── action_panel.gd           (botões de ação)
├── regional_selector.gd      (seleciona regiões corpo)
├── enemy_panel.gd            (mostra inimigos)
├── party_panel.gd            (mostra aliados)
└── combat_log.gd             (histórico)

scenes/
└── combat.tscn               (cena pronta)
```

---

## ✅ Passo 2: Verificar Scene Tree (combat.tscn)

Abra `scenes/combat.tscn` e confirme a estrutura:

```
Control (CombatManager)
└── MarginContainer
    └── VBoxContainer
        ├── TopBar (PanelContainer)
        │   └── VBoxContainer                   ← IMPORTANTE!
        │       ├── HBoxContainer (Linha 1)
        │       │   ├── PartyPanel (PartyPanel.gd)
        │       │   ├── Battlefield
        │       │   └── EnemyPanel (EnemyPanel.gd)
        │       └── HBoxContainer2 (Linha 2)
        │           ├── RegionalPanel (RegionalSelector.gd)
        │           └── ActionPanel (ActionPanel.gd)
        └── LogPanel (PanelContainer)
            └── RichTextLabel (CombatLog.gd)
```

**Verificação:**
- [ ] `TopBar` tem um `VBoxContainer` filho
- [ ] Primeiro `HBoxContainer` dentro do `VBoxContainer`
- [ ] Segundo `HBoxContainer2` dentro do `VBoxContainer`
- [ ] Scripts anexados aos painéis corretos

---

## ✅ Passo 3: Testar Fluxo Básico

1. Abra `scenes/combat.tscn`
2. Clique **Run** (F5)

### Esperado:
```
[DEBUG OUTPUT]
[CombatManager] Inicializando combate...
Guerreiro rolou iniciativa: 4
Goblin rolou iniciativa: 2
🎯 Turno de Guerreiro!
```

### UI:
- ✅ PartyPanel mostra "Guerreiro" com destaque amarelo
- ✅ EnemyPanel mostra "Goblin HP: 8/8"
- ✅ ActionPanel visível com 5 botões
- ✅ CombatLog colorido com histórico

---

## ✅ Passo 4: Testar Ataque Completo

1. Clique **ATACAR**
2. Clique 1-3 regiões (ex: Torso, Braço Direito)
3. Clique **Confirmar**
4. Clique **Goblin**

### Esperado:
```
Regiões selecionadas: Torso, Braço Direito
Regiões confirmadas: Torso, Braço Direito
Selecione o inimigo alvo...
Alvo selecionado: Goblin
✓ Goblin atacou Goblin (Torso) - Dado: 4
→ DANO: 2
→ ESTRESSE: +1
Ação pronta. Escolha a próxima ação ou passe o turno.
```

### Verificações:
- [x] HP do Goblin mudou de 8/8 para 6/8
- [x] EnemyPanel atualizado
- [x] ActionPanel reabilitado (botões clicáveis novamente)
- [x] Pode atacar novamente

---

## ✅ Passo 5: Testar Múltiplas Ações

1. Do mesmo turno do Guerreiro:
   - Clique **ATACAR** novamente
   - Selecione regiões
   - Confirme
   - Selecione Goblin
   - Veja segundo ataque processar

2. Ou clique **PASSAR TURNO** para ir ao próximo turno

### Esperado:
```
Ação pronta. Escolha a próxima ação ou passe o turno.
[Clica ATACAR novamente]
Selecione as regiões de ataque...
[... segundo ataque processa ...]
```

---

## ✅ Passo 6: Entender Estrutura de Dados

### Como um combatente é representado:

```gdscript
{
    "nome": "Guerreiro",
    "tipo": "jogador",           # ou "inimigo"
    "saude_maxima": 15,
    "saude_atual": 15,           # ← Muda com ataque
    "defesa_base": 2,
    "dano_arma": 2,
    "atributo_dano": 1,
    "estresse_por_regiao": {     # Estresse por região
        "Torso": 0,              # ← Muda com ataque
        "Braço Direito": 0,
        "Braço Esquerdo": 0,
        "Perna Direita": 0,
        "Perna Esquerda": 0
    },
    "status": [],
    "iniciativa": 4              # D6 calculado no início
}
```

### Como um ataque é registrado:

```gdscript
{
    "atacante": "Guerreiro",
    "alvo": "Goblin",
    "regiao": "Torso",           # Uma das 5 regiões
    "dado": 5,                   # D6
    "categoria": "Sucesso Regular",  # Baseado no dado
    "dano_aplicado": 2,          # Fixo por enquanto
    "estresse_gerado": 1         # Fixo por enquanto
}
```

---

## 🔧 Passo 7: Customizar Combatentes

Edite `scripts/combat_manager.gd`, função `_setup_exemplo()`:

```gdscript
func _setup_exemplo() -> void:
    # JOGADORES
    combatentes_jogador = [
        {
            "nome": "Seu Herói",          # ← Mude aqui
            "tipo": "jogador",
            "saude_maxima": 20,           # ← HP maior
            "saude_atual": 20,
            "defesa_base": 2,
            "dano_arma": 3,               # ← Dano maior
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
    
    # INIMIGOS
    combatentes_inimigo = [
        {
            "nome": "Chefe Goblin",       # ← Mude aqui
            "tipo": "inimigo",
            "saude_maxima": 15,           # ← HP do chefe
            "saude_atual": 15,
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
```

---

## 🔧 Passo 8: Adicionar Múltiplos Combatentes

Para 2 jogadores vs 3 inimigos:

```gdscript
combatentes_jogador = [
    { "nome": "Guerreiro", ... },
    { "nome": "Mago", ... }
]

combatentes_inimigo = [
    { "nome": "Goblin 1", ... },
    { "nome": "Goblin 2", ... },
    { "nome": "Chefe Goblin", ... }
]
```

---

## 🎯 Passo 9: Entender o Fluxo de Combate

```
1. _inicializar_combate()
   ├─ _setup_exemplo()          (carrega dados)
   ├─ Preenche painéis UI
   ├─ _calcular_iniciativa()    (D6 cada combatente)
   └─ sort() por iniciativa
   
2. _avancar_turno()
   ├─ _encontrar_proximo_combatente() (encontra vivo)
   ├─ combatente_ativo = próximo
   ├─ turno_iniciado.emit()
   └─ Se jogador:
      └─ action_panel.ativar_para()
      
3. Jogador clica ação (ex: ATACAR)
   ├─ _iniciar_ataque()
   ├─ regional_selector.ativar_para_ataque()
   └─ regional_selector.show()
   
4. Jogador seleciona regiões
   ├─ regional_selector.regiao_selecionada.emit()
   └─ _on_regiao_selecionada()
   
5. Jogador clica Confirmar
   ├─ regional_selector.selecao_confirmada.emit()
   └─ _on_regioes_confirmadas()
   
6. Jogador seleciona inimigo
   ├─ enemy_panel.inimigo_selecionado.emit()
   └─ _on_inimigo_selecionado()
   
7. _processar_ataque()
   ├─ Rola D6
   ├─ Calcula dano
   ├─ Aplica ao alvo
   ├─ Registra em log
   ├─ enemy_panel.atualizar_inimigo()
   ├─ action_panel.habilitar_acoes()  ← Permite próxima ação
   └─ Se alvo morreu:
      └─ _derrotar_combatente()
      
8. Jogador clica PASSAR TURNO
   ├─ action_panel.turno_passado.emit()
   └─ _on_turno_passado()
      ├─ turno_finalizado.emit()
      └─ _avancar_turno()  ← Volta ao passo 2
```

---

## 📝 Passo 10: Regras OBLIVIO Implementadas

### ✅ Já Implementado

1. **D6 para tudo**
   - Iniciativa: 1D6 por combatente
   - Ataque: 1D6 resultando em categoria

2. **Categorias de Resultado**
   ```
   6   → Sucesso Extremo (✓✓)
   4-5 → Sucesso Regular (✓)
   2-3 → Falha Regular (✗)
   1   → Falha Crítica (✗✗)
   ```

3. **Regiões de Corpo (5)**
   - Torso, 2x Braços, 2x Pernas
   - Estresse aplicado por região

4. **Turnos**
   - Um combatente por vez
   - Ordem por iniciativa
   - Cicla infinito até alguém ganhar

### ❌ Ainda Não Implementado

1. **Pontos de Ação (PA)**
   - Cada turno começa com 3 PA
   - Ações consomem PA
   - Sem PA = pode só passar turno

2. **Testes de Habilidade**
   - Perícias + atributos vs dificuldade
   - Sistema d6 pool (não-implementado)

3. **Modificadores de Dano**
   - Força = +X ao dano
   - Arma especial = +X ao dano

4. **Modificadores de Defesa**
   - Regiões vulneráveis = -X à defesa
   - Estresse acumulado = -X à defesa

---

## 🚀 Próximos Passos (Ordem de Implementação)

### 1️⃣ **Implementar PA (Pontos de Ação)** - 30 min

Edite `combat_manager.gd`:

```gdscript
# Adicionar ao enum
enum ActionType {
    ACAO_REGULAR,    # 1 PA
    MOVIMENTO,       # 1 PA
    EXTRA,           # 2 PA
    COMPLETA         # 3+ PA
}

# No combatente, adicionar:
combatente["pontos_acao_atuais"] = 3
combatente["pontos_acao_maximos"] = 3

# Função nova:
func consumir_pontos_acao(tipo: ActionType) -> bool:
    var custo = 1  # Padrão
    match tipo:
        ActionType.ACAO_REGULAR: custo = 1
        ActionType.MOVIMENTO: custo = 1
        ActionType.EXTRA: custo = 2
        ActionType.COMPLETA: custo = 3
    
    if combatente_ativo["pontos_acao_atuais"] >= custo:
        combatente_ativo["pontos_acao_atuais"] -= custo
        return true
    else:
        log_panel.registrar_evento("PA insuficiente!", "aviso")
        return false

# Em _iniciar_ataque(), adicionar:
if not consumir_pontos_acao(ActionType.ACAO_REGULAR):
    return
```

### 2️⃣ **Implementar Perícias** - 1 hora

- Criar struct de Perícia
- Banco de dados de perícias
- Menu de seleção
- Teste: Perícia + atributo vs dificuldade

### 3️⃣ **Implementar IA Básica** - 30 min

```gdscript
func _executar_turno_inimigo() -> void:
    var inimigos_vivos = combatentes_inimigo.filter(func(i): return i["saude_atual"] > 0)
    if inimigos_vivos.is_empty():
        _avancar_turno()
        return
    
    # Escolher alvo aleatório
    var alvo = combatentes_jogador.filter(func(j): return j["saude_atual"] > 0).pick_random()
    
    # Escolher região aleatória
    var regiao = ["Torso", "Braço Direito", "Braço Esquerdo", "Perna Direita", "Perna Esquerda"].pick_random()
    
    # Atacar
    _processar_ataque(combatente_ativo, alvo, [regiao])
```

---

## 🎮 Teste Final

1. Run cena
2. Ataque Goblin até morte
3. Goblin desaparece
4. Mensagem: "COMBATE FINALIZADO: Vitória"
5. Parar cena

✅ **Sistema funciona!**

---

## 📞 Troubleshooting

### Problema: "Inimigo inválido selecionado"
**Solução:** Clique em **Confirmar** após selecionar regiões

### Problema: Botões não reativam
**Solução:** Certifique-se que `action_panel.habilitar_acoes()` é chamado em `_processar_ataque()`

### Problema: HP não atualiza
**Solução:** Certifique-se que `enemy_panel.atualizar_inimigo(alvo)` é chamado

### Problema: Combate não termina quando todos morrem
**Solução:** Verifique se `_verificar_fim_combate()` é chamada em `_derrotar_combatente()`

---

## 📚 Referências

- [Godot Signals](https://docs.godotengine.org/en/stable/tutorials/programming/using_signals.html)
- [GDScript Best Practices](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
- OBLIVIO Livro de Regras (capítulo de combate)

---

**Versão:** 2.0  
**Última atualização:** 06/05/2026  
**Status:** ✅ Pronto para usar
