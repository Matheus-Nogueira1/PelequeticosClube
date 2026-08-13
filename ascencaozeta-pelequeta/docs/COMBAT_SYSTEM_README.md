# Sistema de Combate Oblivio - Arquitetura Atual

Este documento descreve a arquitetura atual do combate em Godot 4. Para uma auditoria mais detalhada do codigo, consulte [ESTADO_ATUAL_CODIGO.md](ESTADO_ATUAL_CODIGO.md).

## Visao Geral

O combate principal vive em `scenes/combat.tscn` e e orquestrado por `scripts/battle/combat_manager.gd`. Os paineis de UI sao criados ou preenchidos por codigo e se comunicam por sinais.

```text
CombatManager
|-- PartyPanel
|-- EnemyPanel
|-- RegionalSelector
|-- ActionPanel
`-- CombatLog
```

## Scripts de Combate

### `scripts/battle/combat_manager.gd`

Responsavel por:

- Inicializar combatentes de exemplo.
- Conectar sinais dos paineis.
- Calcular iniciativa por `atributo_velocidade`.
- Avancar turnos.
- Processar ataque normal.
- Processar `Duelo`.
- Processar uso de habilidades.
- Processar uso de itens.
- Atualizar PartyPanel, EnemyPanel e CombatLog.
- Verificar derrota e fim de combate.

Fluxos principais:

```gdscript
func _inicializar_combate() -> void
func _avancar_turno() -> void
func _iniciar_ataque() -> void
func _on_regioes_confirmadas(regioes: Array[String]) -> void
func _on_alvo_selecionado(alvo: CombatenteData) -> void
func _processar_ataque(atacante: CombatenteData, alvo: CombatenteData, regioes: Array[String]) -> void
func _on_pericia_escolhida(nome_pericia: String) -> void
func _on_habilidade_escolhida(nome_habilidade: String) -> void
func _on_item_escolhido(nome_item: String) -> void
```

### `scripts/battle/action_panel.gd`

Responsavel por:

- Menu principal do turno: `ATACAR`, `PERICIA`, `HABILIDADE`, `ITEM`, `PASSAR TURNO`.
- Telas internas de lista e detalhes.
- Emissao de sinais apenas quando uma escolha precisa ser resolvida pelo `CombatManager`.
- Foco inicial nos botoes em varios pontos do fluxo.

Estados internos:

```text
PRINCIPAL
PERICIAS
DETALHE_PERICIA
HABILIDADES
DETALHE_HABILIDADE
ITENS
DETALHE_ITEM
```

Observacao: os menus de pericia, habilidade e item nao sao mais stubs. Eles existem no painel, com lista, detalhes, confirmar e voltar.

### `scripts/battle/regional_selector.gd`

Responsavel por:

- Selecionar regioes corporais.
- Validar regiao perdida, protese destruida e regiao esgotada.
- Permitir ate 5 riscos.
- Permitir repeticao da mesma regiao apenas quando Sobrecarga esta ativa.

Modos:

```text
DESATIVADO
ATAQUE
ITEM
HABILIDADE
PERICIA
```

### `scripts/battle/enemy_panel.gd`

Responsavel por:

- Exibir inimigos.
- Mostrar dados ocultos antes de analise.
- Revelar Protecao e Estresse por regiao quando o inimigo foi analisado por Duelo.
- Ativar/desativar selecao de alvo.

### `scripts/battle/party_panel.gd`

Responsavel por:

- Exibir aliados.
- Mostrar PA, arma, Protecao e Estresse por regiao.
- Destacar combatente ativo.
- Ativar selecao de aliado para uso de item.

### `scripts/battle/combat_log.gd`

Responsavel por:

- Registrar eventos com cor por tipo.
- Registrar ataques formatados.
- Registrar status.
- Manter scroll automatico.

### `scripts/battle/rolagens-dados-d6.gd`

Responsavel por:

- Rolagem D6 de conhecimento.
- Rolagem D6 de combate.
- Classificacao:
  - `1`: Falha Critica.
  - `2-3`: Falha Regular.
  - `4-5`: Sucesso Regular.
  - `6`: Sucesso Extremo.

## Fluxo do Turno do Jogador

```text
CombatManager._avancar_turno()
  -> ActionPanel.ativar_para(combatente)
  -> jogador escolhe acao

ATACAR
  -> ActionPanel emite acao_atacar
  -> RegionalSelector seleciona regioes
  -> EnemyPanel seleciona alvo
  -> CombatManager processa ataque

PERICIA
  -> ActionPanel mostra lista
  -> ActionPanel mostra detalhes
  -> ActionPanel emite pericia_escolhida(nome)
  -> CombatManager resolve efeito implementado

HABILIDADE
  -> ActionPanel mostra lista
  -> ActionPanel mostra detalhes
  -> ActionPanel emite habilidade_escolhida(nome)
  -> HabilidadeData valida e consome PA

ITEM
  -> ActionPanel mostra inventario
  -> ActionPanel emite item_escolhido(nome)
  -> PartyPanel seleciona aliado
  -> RegionalSelector seleciona regiao
  -> ItemData aplica efeito
```

## Dados de Combatente

`CombatenteData` e a estrutura base para jogadores, inimigos e NPCs.

Campos centrais:

- `nome` e `tipo`.
- Atributos fixos: Carne, Forca, Mente, Fuga, Determinacao.
- Atributos mutaveis: Folego, Dano, Coragem, Protecao, Velocidade.
- `estresse_por_regiao`.
- `pontos_acao_atuais` e `pontos_acao_maximos`.
- `conhecimentos_treino`.
- `conhecimentos_especializados`.
- `habilidades`.
- `inventario`.
- `fardos`, `regioes_perdidas` e `proteses`.

## Regras Implementadas de Combate D6

- O jogador arrisca de 1 a 5 regioes.
- Cada regiao gera uma rolagem D6.
- Sucesso Extremo vale 2 acertos.
- Sucesso Regular vale 1 acerto.
- Falhas geram Estresse no atacante.
- Se sucessos nao quebram Protecao, reduzem Protecao temporaria.
- Se sucessos quebram Protecao, causam Estresse no Torso do alvo.
- Dano atual usa atributo de Dano somado a rolagem da arma.

## Pendencias de Arquitetura

- IA de inimigos ainda passa turno automaticamente.
- Movimento e alcance por fileira ainda nao fazem parte do fluxo principal.
- `ActionType` existe, mas os custos nao estao unificados para todas as acoes.
- Pericias ainda nao somam treino/atributo/especializacao.
- Habilidades ainda precisam aplicar seus efeitos especificos.
- O fluxo de foco do `ActionPanel` deve ser centralizado para evitar chamadas duplicadas de `grab_focus()`.
