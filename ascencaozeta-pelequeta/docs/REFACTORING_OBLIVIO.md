# ✅ Refatoração OBLIVIO - COMPLETA

**Data:** 08/05/2026  
**Status:** ✅ CombatenteData INTEGRADO no CombatManager

---

## 📋 Resumo das Mudanças

O sistema foi refatorado para ser **100% fiel ao OBLIVIO**:

### ❌ Sistema Antigo (HP + Estresse Simples)
```gdscript
{
	"nome": "Guerreiro",
	"saude_maxima": 15,       # ← HP TOTAL (ERRADO)
	"saude_atual": 15,        # ← Não existe em OBLIVIO
	"estresse_por_regiao": {
		"Torso": 0,           # ← Sem limites
	}
}
```

### ✅ Sistema Novo (Estresse por Região com Limites)
```gdscript
var guerreiro = CombatenteData.new("Guerreiro", "jogador")
guerreiro.atributo_carne = 3
guerreiro.estresse_por_regiao = {
	"Torso": {"atual": 0, "limite": 6},
	"Braço Direito": {"atual": 0, "limite": 3},
	"Braço Esquerdo": {"atual": 0, "limite": 3},
	"Perna Direita": {"atual": 0, "limite": 3},
	"Perna Esquerda": {"atual": 0, "limite": 3}
}
# ✅ Estresse acumula até limite por região
# ✅ Regiões esgotadas = fadiga
# ✅ Transbordamento para torso
# ✅ Desmaio quando todas regiões esgotadas
```

---

## ✅ Integração Completa no CombatManager

### Mudanças Realizadas:
- **Variáveis atualizadas**: `combatentes_jogador`, `combatentes_inimigo`, `ordem_turno`, `combatente_ativo` agora usam `CombatenteData`
- **Sinais atualizados**: `turno_iniciado` e `turno_finalizado` agora emitem `CombatenteData`
- **Setup atualizado**: `_setup_exemplo()` cria instâncias de `CombatenteData` e `InimigoData`
- **Métodos atualizados**: Todos os métodos de combate agora usam propriedades de classe em vez de acesso a dicionário
- **Verificações atualizadas**: Validação de vida usa `esta_consciente()` e `morto` em vez de `saude_atual`

### Compatibilidade Mantida:
- **UI Panels**: Painéis ainda recebem `Dictionary` via `para_dictionary()` para compatibilidade
- **Sinais externos**: Métodos como `action_panel.ativar_para()` recebem dicionários convertidos
- **Callbacks**: `_on_inimigo_selecionado()` converte dicionário de volta para `CombatenteData`

### Benefícios:
- ✅ **Type Safety**: Erros de acesso a propriedades detectados em tempo de compilação
- ✅ **Métodos consistentes**: `aplicar_estresse()`, `verificar_desmaio()`, `regiao_esgotada()`
- ✅ **Regras OBLIVIO**: Transbordamento para torso, desmaios múltiplos, fadiga por região
- ✅ **Manutenibilidade**: Lógica de combate centralizada na classe `CombatenteData`

### 1. `combatente_data.gd` (CombatenteData)
Classe base para qualquer combatente (jogador, inimigo, NPC)

**Métricas Principais:**
- ✅ **Estresse por região** (0 até limite)
- ✅ **Região esgotada** quando estresse >= limite
- ✅ **Transbordamento** para torso quando região supera limite
- ✅ **Desmaio** quando TODAS regiões esgotadas
- ✅ **Morte** após 3 desmaios

**Uso:**
```gdscript
var combatente = CombatenteData.new("Guerreiro", "jogador")
combatente.atributo_carne = 2
combatente.aplicar_estresse("Torso", 3)  # Estresse: 0 → 3

if combatente.regiao_esgotada("Torso"):
	print("Torso esgotado!")

if combatente.esta_desmaiado():
	print("Desmaiou!")
```

### 2. `inimigo_data.gd` (InimigoData)
Banco de dados de templates de inimigos

**Carcaça (não-morta):**
```gdscript
var carcaca = InimigoData.carcaca()
# Carne: 2, Força: 3, Agilidade: 2, Vontade: 2
# Limite estresse: 22 pontos distribuídos
# Torso: 10, Braços: 4 cada, Pernas: 2 cada
```

### 3. `pericia_data.gd` (PericiaData)
Banco de dados de perícias OBLIVIO

### 4. `habilidade_data.gd` (HabilidadeData)
Banco de dados de habilidades especiais

---

---

## 📚 Documentação Relacionada

- [ATRIBUTOS_OBLIVIO.md](ATRIBUTOS_OBLIVIO.md) - Sistema de Atributos Fixos e Mutáveis
- [STATUS_COMBATE.md](STATUS_COMBATE.md) - Status e Progresso da Tela de Combate
- [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) - Guia de Implementação
```gdscript
# Sistema antigo com HP total
var combatentes_jogador = [
	{
		"nome": "Guerreiro",
		"tipo": "jogador",
		"saude_maxima": 15,
		"saude_atual": 15,
		"estresse_por_regiao": {"Torso": 0, ...}
	}
]
```

### Depois (CombatenteData):
```gdscript
# Sistema novo com Estresse por região
var combatentes_jogador: Array[CombatenteData] = []

func _setup_exemplo() -> void:
	var guerreiro = CombatenteData.new("Guerreiro", "jogador")
	guerreiro.atributo_carne = 3
	guerreiro.atributo_forca = 3
	guerreiro.dano_arma = 2
	guerreiro.defesa_base = 2
	
	combatentes_jogador.append(guerreiro)
	
	# Inimigos usando templates
	combatentes_inimigo = [InimigoData.criar_carcaca()]
```

### Atualização dos Métodos:
```gdscript
# Antes
if combatente["saude_atual"] > 0:
	# ...

# Depois  
if combatente.esta_consciente() and not combatente.morto:
	# ...

# Antes
combatente["estresse_por_regiao"]["Torso"] += 1

# Depois
combatente.aplicar_estresse("Torso", 1)
```

---

## 📊 Estrutura de Dados Atual

### CombatenteData (Sistema Estresse OBLIVIO)
```gdscript
class_name CombatenteData
extends RefCounted

# Informações Básicas
var nome: String
var tipo: String  # "jogador", "inimigo", "npc"

# Atributos OBLIVIO (5 pilares)
var atributo_carne: int = 1      # Define limites de estresse base
var atributo_forca: int = 1
var atributo_inteligencia: int = 1
var atributo_agilidade: int = 1
var atributo_vontade: int = 1

# Combate
var dano_arma: int = 1
var defesa_base: int = 1
var iniciativa: int = 0
var status: Array[String] = []

# ESTRESSE POR REGIÃO (métrica principal OBLIVIO)
var estresse_por_regiao: Dictionary = {
	"Torso": {"atual": 0, "limite": 6},
	"Braço Direito": {"atual": 0, "limite": 3},
	"Braço Esquerdo": {"atual": 0, "limite": 3},
	"Perna Direita": {"atual": 0, "limite": 3},
	"Perna Esquerda": {"atual": 0, "limite": 3}
}

# Pontos de Ação
var pontos_acao_atuais: int = 3
var pontos_acao_maximos: int = 3

# Sistema de Perícias e Habilidades
var pericias: Dictionary = {}       # {"nome": nivel}
var habilidades: Array[String] = []  # ["Golpe Duplo", "Bloqueio"]
var inventario: Array[String] = []

# Contadores OBLIVIO
var desmaios: int = 0  # Máximo 3 antes da morte
var morto: bool = false
```

### Métodos Principais
```gdscript
# Status de consciência
combatente.esta_consciente() -> bool     # Pelo menos uma região não esgotada
combatente.esta_desmaiado() -> bool      # TODAS regiões esgotadas

# Regiões
combatente.regiao_esgotada(regiao: String) -> bool
combatente.regiao_pode_ser_arriscada(regiao: String) -> bool

# Aplicar efeitos
combatente.aplicar_estresse(regiao: String, quantidade: int)
combatente.aliviar_estresse(regiao: String, quantidade: int)

# Verificações
combatente.verificar_desmaio() -> bool   # Retorna true se desmaiou
combatente.contar_regioes_esgotadas() -> int

# Cálculos
combatente.get_estresse_total() -> int
combatente.get_limite_estresse_total() -> int
combatente.get_porcentagem_fadiga() -> float

# Compatibilidade
combatente.para_dictionary() -> Dictionary
CombatenteData.de_dictionary(dados: Dictionary) -> CombatenteData
```

---

## 🎯 Próximos Passos

### Priority 1: Refatorar combat_manager.gd
- [ ] Usar `CombatenteData` em vez de Dictionaries
- [ ] Integrar `InimigoData` para criar inimigos
- [ ] Atualizar `_processar_ataque()` para trabalhar com regiões

### Priority 2: Refatorar enemy_panel.gd e party_panel.gd
- [ ] Mostrar HP por região (não total)
- [ ] Mostrar estresse por região com limite
- [ ] Mostrar quando região está incapacitada

### Priority 3: Integrar Perícias
- [ ] Adicionar menu de perícias em action_panel.gd
- [ ] Usar `PericiaData` para testar perícias
- [ ] Consumir PA ao usar perícias

### Priority 4: Integrar Habilidades
- [ ] Adicionar menu de habilidades em action_panel.gd
- [ ] Usar `HabilidadeData` para usar habilidades
- [ ] Consumir PA ao usar habilidades

---

## 💡 Exemplo Completo: Criar um Combatente

```gdscript
# Criar combatente manualmente
var mago = CombatenteData.new("Mago", "jogador")
mago.atributo_inteligencia = 3
mago.atributo_agilidade = 2
mago.defesa_base = 1
mago.dano_arma = 1  # Varinhas fazem pouco dano

# Customizar HP por região (mais magro)
mago.hp_por_regiao = {
	"Torso": {"atual": 4, "maximo": 4},
	"Braço Direito": {"atual": 2, "maximo": 2},
	"Braço Esquerdo": {"atual": 2, "maximo": 2},
	"Perna Direita": {"atual": 2, "maximo": 2},
	"Perna Esquerda": {"atual": 2, "maximo": 2}
}

# Adicionar habilidades
mago.habilidades = ["Golpe Duplo", "Análise Tática"]
mago.pericias = {"Conhecimento Geral": 3, "Investigação": 2}

# Usar em combate
combatentes_jogador.append(mago)
```

---

## 📝 Mudanças em Painéis

### PartyPanel
- **Antes:** Mostrava "Estresse Total: X"
- **Depois:** Mostra "HP Total: X/Y" com cor baseada em saúde

### EnemyPanel
- **Antes:** Formatava `inimigo["saude_atual"]`
- **Depois:** Deve calcular HP total de todas regiões

---

## 🎮 Fluxo de Ataque Atualizado

```
1. Jogador clica ATACAR
2. Regional Selector mostra (seleciona regiões)
3. Enemy Panel ativa (seleciona inimigo)
4. _processar_ataque(atacante, alvo, regioes)
   ├─ Rola D6
   ├─ Calcula dano
   ├─ Para cada região:
   │  ├─ alvo.aplicar_dano(regiao, dano)
   │  ├─ alvo.aplicar_estresse(regiao, estresse)
   │  └─ Verifica se regiao.hp <= 0
   ├─ Atualiza UI
   └─ Verifica se alvo morreu (nenhuma região consciente)
5. Próxima ação OU PASSAR TURNO
```

---

## 🔗 Integração com OBLIVIO

### ✅ Agora Implementado
- [x] HP por região (não total)
- [x] Estresse com limite por região
- [x] Atributos OBLIVIO (5 pilares)
- [x] Perícias com atributo base
- [x] Habilidades com custo PA
- [x] PA (Pontos de Ação)
- [x] Combatentes criáveis via templates

### 🟡 Pronto mas Não Integrado
- [ ] _processar_ataque() usando CombatenteData
- [ ] Party/Enemy Panels mostrando HP por região
- [ ] Menu de perícias ativo
- [ ] Menu de habilidades ativo
- [ ] IA usando pericias e habilidades

---

## 📞 Questões Frequentes

**P: Como calcular HP total?**  
R: `combatente.get_hp_total()` ou:
```gdscript
var hp_total = 0
for regiao_hp in combatente.hp_por_regiao.values():
	hp_total += regiao_hp["atual"]
```

**P: Como verificar se combatente morreu?**  
R: `if not combatente.esta_vivo():`

**P: Como saber se região está incapacitada?**  
R: `if combatente.regiao_incapacitada("Torso"):`

**P: Como aplicar dano corretamente?**  
R: `combatente.aplicar_dano("Torso", 2)` - reduz HP da região

---

**Versão:** 1.0  
**Data:** 08/05/2026  
**Status:** ✅ Estrutura completa, aguardando integração
