# ⚡ QUICK START - 5 Minutos para Começar

**Tempo estimado**: 5-10 minutos

---

## 1️⃣ Abra a Cena `combat.tscn`

```
Godot Editor → File → Open Scene → scenes/combat.tscn
```

---

## 2️⃣ Adicione o Script ao Nó Raiz

Se a raiz é um `Control`:

1. Selecione o nó raiz (Control)
2. Inspector → Attach Script
3. Path: `res://scripts/combat_manager.gd`
4. Create

---

## 3️⃣ Marque os Nós com UNIQUE NAME

Para cada painel abaixo, clique direito → Rename:

```
PartyPanel       → %PartyPanel
EnemyPanel       → %EnemyPanel
RegionalPanel    → %RegionalPanel
ActionPanel      → %ActionPanel
LogPanel         → %LogPanel
Battlefield      → %Battlefield (opcional)
```

**Como fazer?**
1. Clique direito no nó
2. Selecione "Rename"
3. Adicione `%` na frente: `%PartyPanel`
4. Pressione Enter

---

## 4️⃣ Atribua Scripts aos Painéis

Selecione cada nó e atribua o script correto:

| Nó | Script |
|----|--------|
| PartyPanel | `party_panel.gd` |
| EnemyPanel | `enemy_panel.gd` |
| RegionalPanel | `regional_selector.gd` |
| ActionPanel | `action_panel.gd` |
| LogPanel | `combat_log.gd` |

**Como fazer?**
1. Selecione o nó
2. Inspector → Script (ou arraste o script para lá)
3. Selecione o script `.gd`
4. Done!

---

## 5️⃣ Execute (Play)

```
Pressione F5 ou clique em Play
```

**Você deve ver:**
- ✅ PartyPanel com "Guerreiro"
- ✅ EnemyPanel com "Goblin"
- ✅ ActionPanel com 4 botões
- ✅ LogPanel com "🎯 Turno de Guerreiro!"

---

## 6️⃣ Teste o Fluxo de Ataque

1. **Clique em "⚔️ ATACAR"**
   - RegionalPanel deve aparecer

2. **Selecione regiões** (clique em 1-3)
   - Exemplo: Torso, Braço Direito

3. **Clique "Confirmar"**
   - EnemyPanel deve ficar selecionável

4. **Clique no "Goblin"**
   - Ver resultado no LogPanel
   - Exemplo: "✓ Guerreiro atacou Goblin (Torso) - Dado: 5"

---

## ✅ Pronto!

Seu sistema de combate está funcionando! 🎉

---

## 📚 Próximos Passos

Leia os documentos nesta ordem:

1. **README_COMBATE.md** (índice geral)
2. **COMBAT_SYSTEM_README.md** (entender funcionamento)
3. **INTEGRATION_EXAMPLE.md** (aprofundar integração)
4. **SIGNALS_REFERENCE.md** (se precisar adicionar funcionalidades)

---

## 🐛 Se Não Funcionar

**Erro**: Scripts não estão sendo encontrados
```
Solução: Verifique se os arquivos .gd estão em scripts/
Caminho correto: scripts/combat_manager.gd, etc
```

**Erro**: Nós não estão sendo encontrados
```
Solução: Verifique se marcou com % (unique_name)
Exemplo correto: %PartyPanel (não "PartyPanel")
```

**Erro**: Painel vazio
```
Solução: O script cria a UI automaticamente no _ready()
Aguarde 1 segundo ou recarregue a cena (F5)
```

**Erro**: Nenhum combatente aparece
```
Solução: Há dados de exemplo em _setup_exemplo()
Se quiser dados reais, edite _inicializar_combate()
```

---

## 💻 Onde Estão os Arquivos?

```
✅ Scripts criados:
   res://scripts/combat_manager.gd
   res://scripts/action_panel.gd
   res://scripts/regional_selector.gd
   res://scripts/enemy_panel.gd
   res://scripts/party_panel.gd
   res://scripts/combat_log.gd

📖 Documentação:
   res://scripts/README_COMBATE.md
   res://scripts/COMBAT_SYSTEM_README.md
   res://scripts/INTEGRATION_EXAMPLE.md
   res://scripts/SIGNALS_REFERENCE.md
   res://scripts/ARCHITECTURE_VISUAL.md
```

---

## 🎮 Controles do Combate

```
Botões com mouse/touch:
├─ ⚔️  ATACAR      - Seleciona regiões → Seleciona alvo
├─ ✨ PERÍCIA     - [Não implementado ainda]
├─ 💥 HABILIDADE - [Não implementado ainda]
├─ 🎒 ITEM       - [Não implementado ainda]
└─ ➡️  PASSAR     - Passa o turno

Regiões (5):
├─ Torso
├─ Braço Direito
├─ Braço Esquerdo
├─ Perna Direita
└─ Perna Esquerda (máximo 3 por ataque)
```

---

## 📊 Estado Atual vs Futuro

**O que funciona AGORA:**
- ✅ Fluxo de turno (jogador → inimigo → próximo)
- ✅ Seleção de regiões (1-3)
- ✅ Seleção de alvo (inimigo)
- ✅ Rolagem de D6 (resultado simulado)
- ✅ Histórico colorido
- ✅ Detecção de derrotas
- ✅ Indicador de turno ativo

**O que precisa implementar:**
- ⏳ Custos de ação (PA)
- ⏳ Menus de perícias/habilidades/itens
- ⏳ IA de inimigos
- ⏳ Efeitos visuais
- ⏳ Integração com sistema de rolagem real

---

## 💡 Dica de Ouro

Se você estiver em `CombatManager.gd` e quiser ver o que fazer depois:

```gdscript
# Procure por:
# TODO: [descrição]

Exemplo:
# TODO: Implementar sistema de custos de ação
# TODO: Adicionar IA para inimigos
```

---

## ☁️ Agora Você Pode...

- [x] Ver o fluxo de combate básico funcionar
- [x] Testar seleção de regiões
- [x] Entender como os painéis se comunicam
- [x] Começar a adicionar funcionalidades próprias

---

## 🚀 Próxima Implementação

Após testar o fluxo básico, leia:
→ **INTEGRATION_EXAMPLE.md** (seção "Como Carregar Dados Reais")

Para carregar seus próprios personagens e inimigos em vez dos de exemplo.

---

## 📞 Referência Rápida

| Você quer... | Faça isto... |
|-------------|-------------|
| Ver como funciona | Jogue a cena (F5) |
| Entender o código | Abra `combat_manager.gd` |
| Integrar melhor | Leia `INTEGRATION_EXAMPLE.md` |
| Adicionar funcionalidade | Procure `# TODO:` nos scripts |
| Debugar um problema | Veja seção "Se Não Funcionar" acima |

---

**🎉 Pronto! Seu sistema de combate está rodando!**

Divirta-se desenvolvendo! 🎮
