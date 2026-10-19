# 🎲 Sistema de Atributos OBLIVIO

**Data:** 16/05/2026  
**Versão:** 2.2 (Conforme PDF Oblivio2.2)

---

## 📊 Atributos Fixos vs Mutáveis

### Atributos Fixos (Imutáveis)
São definidos no início do jogo e representam as capacidades fundamentais da Persona.

| Atributo | Representa | Range |
|----------|-----------|-------|
| **Carne** | Saúde, vigor e integridade física | 1-5 |
| **Força** | Potência muscular e capacidade de danificar | 1-5 |
| **Mente** | Aptidão e resiliência intelectual | 1-5 |
| **Fuga** | Agilidade e velocidade de reação | 1-5 |
| **Determinação** | Resiliência e inteligência emocional | 1-5 |

### Atributos Mutáveis (Podem variar)
São **derivados** dos Atributos Fixos. Podem aumentar (itens, habilidades) ou diminuir (situações estressantes) durante o jogo.

**Fórmula Base**: `(Atributo Fixo 1 + Atributo Fixo 2) / 2` (arredondado para baixo)

| Atributo | Cálculo | Representa |
|----------|---------|-----------|
| **Fôlego** | (Carne + Determinação) / 2 | Capacidade de recuperação durante ação |
| **Dano** | (Força + Carne) / 2 | Intensidade do dano que causa |
| **Coragem** | (Determinação + Mente) / 2 | Firmeza e resiliência emocional |
| **Proteção** | (Carne + Fuga) / 2 | Dificuldade de ser acertado |
| **Velocidade** | (Fuga + Determinação) / 2 | Rapidez de movimento e reação |

---

## 🔧 Implementação em CombatenteData

### Criação de um Combatente
```gdscript
var guerreiro = CombatenteData.new("Guerreiro", "jogador")

# Definir atributos fixos
guerreiro.atributo_carne = 4
guerreiro.atributo_forca = 3
guerreiro.atributo_mente = 2
guerreiro.atributo_fuga = 2
guerreiro.atributo_determinacao = 3

# Os atributos mutáveis são calculados automaticamente!
# Fôlego = (4 + 3) / 2 = 3
# Dano = (3 + 4) / 2 = 3
# Coragem = (3 + 2) / 2 = 2
# Proteção = (4 + 2) / 2 = 3
# Velocidade = (2 + 3) / 2 = 2
```

### Atualizar Atributos Fixos (e Recalcular Mutáveis)
```gdscript
# Método especial que atualiza fixo E recalcula mutáveis
guerreiro.atualizar_atributo_fixo("carne", 5)
# Agora: Fôlego = (5 + 3) / 2 = 4 (foi atualizado automaticamente!)
```

### Acessar Atributos
```gdscript
print("Dano do guerreiro:", guerreiro.atributo_dano)
print("Proteção atual:", guerreiro.atributo_protecao)

# Todos os atributos são acessíveis:
# - atributo_carne, atributo_forca, atributo_mente, atributo_fuga, atributo_determinacao
# - atributo_folego, atributo_dano, atributo_coragem, atributo_protecao, atributo_velocidade
```

---

## 📖 Testes de Perícia

### Sistema de Perícias OBLIVIO
Cada perícia está vinculada a um **Atributo Fixo** e tem um **Nível de Treino** (0-5).

**Fórmula de Teste**: `D6 + Atributo + Treino >= Dificuldade`

| Perícia | Atributo | Descrição |
|---------|----------|-----------|
| Bandidagem | Fuga | Cometer delitos/não ser pego |
| Duelo | Força | Conhecimentos marciais |
| Emocional | Determinação | Lidar com emoções |
| Esforço | Carne | Ações físicas desgastantes |
| Místico | Mente | Artes ritualísticas/religiosas |
| Mundo | Carne | Conhecimento natural |
| Rastro | Fuga | Perceber detalhes ocultos |
| Reflexos | Fuga | Agilidade/esquiva |
| Saber | Mente | Conhecimento adquirido |
| Social | Determinação | Influenciar emoções alheias |

### Exemplo de Teste
```gdscript
var resultado = PericiaData.new().testar_pericia(guerreiro, "Duelo", 1)

# Resultado contém:
# - sucesso: true/false
# - dado: 1-6
# - atributo: valor do atributo base
# - treino: nível de treino
# - resultado: dado + atributo + treino
# - dificuldade: dificuldade (padrão 3)
# - categoria: "Crítico", "Sucesso Excepcional", "Normal", "Fracasso"
# - margem_sucesso: resultado - dificuldade
```

---

## ⚔️ Combate e Estresse

### Estresse por Região
Em OBLIVIO, a saúde não é representada por HP total, mas por **Estresse acumulado por região do corpo**.

Cada região tem um **Limite de Estresse**:
- **Torso**: 6 pontos
- **Braço Direito**: 3 pontos
- **Braço Esquerdo**: 3 pontos
- **Perna Direita**: 3 pontos
- **Perna Esquerda**: 3 pontos

### Aplicar Estresse
```gdscript
guerreiro.aplicar_estresse("Torso", 2)  # Adiciona 2 de estresse

# Verificar status
if guerreiro.regiao_esgotada("Torso"):
	print("Torso está esgotado!")

if guerreiro.esta_consciente():
	print("Ainda está consciente")
```

### Dano e Transbordamento
- Quando uma região **supera seu limite**, o excesso transborda para o **Torso**
- Quando **TODAS as regiões** estão esgotadas, o combatente **desmania**
- Após **3 desmaios**, o combatente **morre**

---

## 📋 Template de Combatente

Para criar um novo tipo de inimigo:

```gdscript
static func criar_novo_inimigo() -> CombatenteData:
	var inimigo = CombatenteData.new("Nome", "inimigo")
	
	# Atributos Fixos
	inimigo.atributo_carne = 3
	inimigo.atributo_forca = 3
	inimigo.atributo_mente = 2
	inimigo.atributo_fuga = 2
	inimigo.atributo_determinacao = 2
	
	# Dano e Defesa
	inimigo.dano_arma = 2
	inimigo.defesa_base = 1
	
	# Perícias (opcional)
	inimigo.pericias = {
		"Duelo": 2,
		"Reflexos": 1
	}
	
	return inimigo
```

---

## ✅ Status da Implementação

- [x] Atributos Fixos e Mutáveis implementados
- [x] Cálculo automático de Mutáveis
- [x] Sistema de Perícias com testes D6
- [x] Estresse por região
- [x] Transbordamento para Torso
- [x] Desmaios e morte
- [ ] Interface visual mostrando Atributos Mutáveis
- [ ] Modificadores de Atributos (itens, habilidades)
- [ ] Críticos e Falhas em Perícias
