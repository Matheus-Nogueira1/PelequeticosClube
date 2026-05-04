# 📡 Referência Rápida - Sinais e Comunicação

Este documento mostra como os scripts se comunicam através de sinais.

---

## 🔗 Diagrama de Comunicação

```
ActionPanel
  │
  ├─→ (acao_atacar) ─→ CombatManager._iniciar_ataque()
  ├─→ (acao_pericia) ─→ CombatManager._iniciar_pericia()
  ├─→ (acao_habilidade) ─→ CombatManager._iniciar_habilidade()
  └─→ (acao_item) ─→ CombatManager._iniciar_item()

RegionalSelector
  │
  ├─→ (regiao_selecionada) ─→ CombatManager._on_regiao_selecionada()
  ├─→ (selecao_confirmada) ─→ [Future]
  └─→ (selecao_cancelada) ─→ [Future]

EnemyPanel
  │
  └─→ (inimigo_selecionado) ─→ CombatManager._on_inimigo_selecionado()

CombatManager
  │
  ├─→ (turno_iniciado) ─→ ActionPanel.ativar_para() + PartyPanel.indicar_personagem_ativo()
  ├─→ (turno_finalizado) ─→ [Para próximo turno]
  ├─→ (combate_iniciado) ─→ PartyPanel.atualizar_todos() + EnemyPanel.atualizar_todos()
  ├─→ (combate_finalizado) ─→ [Tela de resultado]
  └─→ (estado_atualizado) ─→ PartyPanel.atualizar_personagem() + EnemyPanel.atualizar_inimigo()
```

---

## 📤 SINAIS EMITIDOS POR CADA SCRIPT

### ActionPanel

```gdscript
signal acao_atacar
signal acao_pericia
signal acao_habilidade
signal acao_item
```

**Quando emitir?**
```gdscript
# No callback do botão
func _on_atacar_pressionado() -> void:
    desabilitar_acoes()
    acao_atacar.emit()  # ← CombatManager recebe isto
```

**Conectar em CombatManager:**
```gdscript
action_panel.acao_atacar.connect(_iniciar_ataque)
```

---

### RegionalSelector

```gdscript
signal regiao_selecionada(nome_regiao: String, indice: int)
signal selecao_confirmada(regioes: Array[String])
signal selecao_cancelada
```

**Quando emitir?**
```gdscript
# Quando jogador clica em uma região
func _on_regiao_clicada(indice: int, nome_regiao: String) -> void:
    selecionadas[indice] = !selecionadas[indice]
    regiao_selecionada.emit(nome_regiao, indice)  # ← CombatManager recebe
    
# Quando confirma seleção
func _on_confirmar() -> void:
    selecao_confirmada.emit(regioes_finais)  # ← [Future use]
    
# Quando cancela
func _on_cancelar() -> void:
    selecao_cancelada.emit()  # ← [Future use]
```

**Conectar em CombatManager:**
```gdscript
regional_selector.regiao_selecionada.connect(_on_regiao_selecionada)
```

---

### EnemyPanel

```gdscript
signal inimigo_selecionado(inimigo: Dictionary)
signal inimigo_deseleccionado
```

**Quando emitir?**
```gdscript
# Quando jogador clica em um inimigo
func _on_botao_inimigo_pressionado(inimigo: Dictionary) -> void:
    inimigo_selecionado_atual = inimigo
    inimigo_selecionado.emit(inimigo)  # ← CombatManager recebe
```

**Conectar em CombatManager:**
```gdscript
enemy_panel.inimigo_selecionado.connect(_on_inimigo_selecionado)
```

---

### CombatManager

```gdscript
signal turno_iniciado(combatente: Dictionary)
signal turno_finalizado(combatente: Dictionary)
signal combate_iniciado
signal combate_finalizado(vencedor: String)
signal estado_atualizado
```

**Quando emitir?**

```gdscript
# Início do combate
func _inicializar_combate() -> void:
    # ...
    combate_iniciado.emit()  # ← UI atualiza

# Quando novo turno começa
func _avancar_turno() -> void:
    # ...
    turno_iniciado.emit(combatente_ativo)  # ← ActionPanel se ativa

# Quando turno termina
func turno_finalizado() -> void:
    turno_finalizado.emit(combatente_ativo)  # ← Próximo turno

# Quando estado muda
func _processar_ataque(...) -> void:
    # ... aplicar dano, estresse ...
    estado_atualizado.emit()  # ← Painéis se atualizam

# Fim do combate
func _finalizar_combate(resultado: String) -> void:
    combate_finalizado.emit(resultado)  # ← Mostrar resultado
```

---

## 🔄 FLUXO DE SINAIS - EXEMPLO: ATAQUE

```
1. Jogador clica "⚔️ ATACAR"
   └─→ ActionPanel emite: acao_atacar

2. CombatManager recebe acao_atacar
   └─→ CombatManager._iniciar_ataque()
       └─→ regional_selector.ativar_para_ataque()

3. Jogador seleciona 1-3 regiões
   └─→ RegionalSelector emite: regiao_selecionada(nome, indice)
       └─→ CombatManager._on_regiao_selecionada()

4. CombatManager habilita seletor de alvo
   └─→ enemy_panel.ativar_seletor_alvo()

5. Jogador clica em um inimigo
   └─→ EnemyPanel emite: inimigo_selecionado(inimigo)
       └─→ CombatManager._on_inimigo_selecionado()

6. CombatManager processa ataque
   └─→ CombatManager._processar_ataque(atacante, alvo, regioes)
       ├─→ Rola dados D6
       ├─→ CombatLog.registrar_ataque(resultado)
       ├─→ Aplica dano/estresse
       └─→ CombatManager emite: estado_atualizado

7. Estado atualiza painéis
   ├─→ PartyPanel.atualizar_personagem(alvo)
   ├─→ EnemyPanel.atualizar_inimigo(alvo)
   └─→ CombatLog mostra resultado

8. Turno finaliza
   └─→ CombatManager._avancar_turno()
       └─→ CombatManager emite: turno_iniciado(proximo_combatente)
           └─→ ActionPanel se ativa para novo personagem
```

---

## 📊 TABELA RÁPIDA DE CONEXÕES

| Emissor | Sinal | Receptor | Função |
|---------|-------|----------|--------|
| ActionPanel | `acao_atacar` | CombatManager | `_iniciar_ataque()` |
| ActionPanel | `acao_pericia` | CombatManager | `_iniciar_pericia()` |
| ActionPanel | `acao_habilidade` | CombatManager | `_iniciar_habilidade()` |
| ActionPanel | `acao_item` | CombatManager | `_iniciar_item()` |
| RegionalSelector | `regiao_selecionada` | CombatManager | `_on_regiao_selecionada()` |
| EnemyPanel | `inimigo_selecionado` | CombatManager | `_on_inimigo_selecionado()` |
| CombatManager | `turno_iniciado` | ActionPanel | `ativar_para()` |
| CombatManager | `turno_iniciado` | PartyPanel | `indicar_personagem_ativo()` |
| CombatManager | `estado_atualizado` | PartyPanel | `atualizar_personagem()` |
| CombatManager | `estado_atualizado` | EnemyPanel | `atualizar_inimigo()` |
| CombatManager | `combate_finalizado` | [SceneManager] | `mostrar_resultado()` |

---

## 🧩 COMO ADICIONAR UM NOVO SINAL

### 1. Declare o sinal no script

```gdscript
# Em seu script (ex: NovoScript.gd)
signal meu_novo_sinal(parametro: String)
```

### 2. Emita quando necessário

```gdscript
func alguma_funcao() -> void:
    # ... fazer algo ...
    meu_novo_sinal.emit("valor")
```

### 3. Conecte em CombatManager._conectar_sinais_paineis()

```gdscript
novo_script.meu_novo_sinal.connect(_on_meu_novo_sinal)

func _on_meu_novo_sinal(parametro: String) -> void:
    print("Recebi: " + parametro)
    # ... tratar sinal ...
```

---

## 🐛 DEBUG: Verificar Sinais Conectados

```gdscript
# Adicione no _ready() do CombatManager para verificar conexões
func _debug_sinais() -> void:
    print("=== SINAIS CONECTADOS ===")
    
    if action_panel:
        print("✓ ActionPanel sinais:", [
            "acao_atacar" if action_panel.is_connected("acao_atacar", Callable(self, "_iniciar_ataque")) else "✗ acao_atacar"
        ])
    
    if regional_selector:
        print("✓ RegionalSelector sinais:", [
            "regiao_selecionada" if regional_selector.is_connected("regiao_selecionada", Callable(self, "_on_regiao_selecionada")) else "✗ regiao_selecionada"
        ])
    
    if enemy_panel:
        print("✓ EnemyPanel sinais:", [
            "inimigo_selecionado" if enemy_panel.is_connected("inimigo_selecionado", Callable(self, "_on_inimigo_selecionado")) else "✗ inimigo_selecionado"
        ])
    
    print("=== FIM DEBUG ===")

# Chamar em _ready():
_debug_sinais()
```

---

## 💡 BOAS PRÁTICAS

1. **Sempre desconecte quando não mais necessário**:
   ```gdscript
   signal.disconnect(callback)
   ```

2. **Use nomes descritivos** para sinais:
   ```gdscript
   signal botao_atacar_pressionado  # ✓ Bom
   signal ataque                     # ✗ Vago
   ```

3. **Passe dados necessários no sinal**:
   ```gdscript
   signal inimigo_selecionado(inimigo: Dictionary)  # ✓ Completo
   signal inimigo_selecionado                       # ✗ Sem contexto
   ```

4. **Documente sinais em comentários**:
   ```gdscript
   ## Emitido quando jogador seleciona um alvo
   signal inimigo_selecionado(inimigo: Dictionary)
   ```
