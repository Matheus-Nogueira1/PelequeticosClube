# Referencia de Sinais e Comunicacao

Este documento descreve os sinais atuais do fluxo de combate em `scripts/battle/`.

## Diagrama Resumido

```text
ActionPanel
  -> acao_atacar                  -> CombatManager._iniciar_ataque()
  -> acao_habilidade              -> CombatManager._iniciar_habilidade()
  -> acao_item                    -> CombatManager._iniciar_item()
  -> turno_passado                -> CombatManager._on_turno_passado()
  -> pericia_escolhida(nome)      -> CombatManager._on_pericia_escolhida(nome)
  -> habilidade_escolhida(nome)   -> CombatManager._on_habilidade_escolhida(nome)
  -> item_escolhido(nome)         -> CombatManager._on_item_escolhido(nome)
  -> habilidade_sobrecarga        -> CombatManager._ativar_sobrecarga()

RegionalSelector
  -> regiao_selecionada(nome, i)  -> CombatManager._on_regiao_selecionada(nome, i)
  -> selecao_confirmada(regioes)  -> CombatManager._on_regioes_confirmadas(regioes)
  -> selecao_cancelada            -> CombatManager._on_selecao_cancelada()

EnemyPanel
  -> alvo_selecionado(alvo)       -> CombatManager._on_alvo_selecionado(alvo)

PartyPanel
  -> aliado_selecionado(aliado)   -> CombatManager._on_personagem_item_selecionado(aliado)

CombatManager
  -> turno_iniciado(combatente)
  -> turno_finalizado(combatente)
  -> combate_iniciado
  -> combate_finalizado(vencedor)
  -> estado_atualizado
  -> turno_passado
```

## ActionPanel

Arquivo: `scripts/battle/action_panel.gd`

Sinais:

```gdscript
signal acao_atacar
signal acao_habilidade
signal acao_item
signal turno_passado
signal habilidade_sobrecarga
signal pericia_escolhida(nome_pericia: String)
signal habilidade_escolhida(nome_habilidade: String)
signal item_escolhido(nome_item: String)
```

Observacoes:

- Nao existe mais `acao_pericia` no codigo atual; pericias sao escolhidas internamente e confirmadas por `pericia_escolhida(nome)`.
- `acao_habilidade` e `acao_item` ainda existem, mas o painel tambem emite os sinais de escolha depois da tela de detalhes.
- `habilidade_sobrecarga` e um fluxo especial para ativar Sobrecarga.

## RegionalSelector

Arquivo: `scripts/battle/regional_selector.gd`

Sinais:

```gdscript
signal regiao_selecionada(nome_regiao: String, indice: int)
signal selecao_confirmada(regioes: Array[String])
signal selecao_cancelada
```

Usos atuais:

- Ataque normal: regioes confirmadas levam ao seletor de inimigo.
- Item: regioes confirmadas chamam `_usar_item(regioes[0])`.
- Cancelamento: desativa o seletor e reabilita o `ActionPanel`.

## EnemyPanel

Arquivo: `scripts/battle/enemy_panel.gd`

Sinais:

```gdscript
signal alvo_selecionado(alvo: CombatenteData)
signal alvo_deselecionado
signal inimigo_deseleccionado
```

Uso atual:

- `alvo_selecionado` e conectado ao `CombatManager`.
- `alvo_deselecionado` e `inimigo_deseleccionado` existem, mas nao aparecem conectados no fluxo atual.

## PartyPanel

Arquivo: `scripts/battle/party_panel.gd`

Sinais:

```gdscript
signal aliado_selecionado(aliado: CombatenteData)
signal aliado_deselecionado
```

Uso atual:

- `aliado_selecionado` e conectado em `_inicializar_combate()` para o fluxo de itens.
- Ao selecionar um aliado, o `CombatManager` ativa o `RegionalSelector` para escolher a regiao que recebera o item.

## CombatManager

Arquivo: `scripts/battle/combat_manager.gd`

Sinais:

```gdscript
signal turno_iniciado(combatente: CombatenteData)
signal turno_finalizado(combatente: CombatenteData)
signal combate_iniciado
signal combate_finalizado(vencedor: String)
signal estado_atualizado
signal turno_passado
```

Observacoes:

- Os sinais de `CombatManager` existem para integracao, mas muitas atualizacoes de UI hoje sao chamadas diretamente pelo proprio manager.
- `estado_atualizado` esta declarado, mas o fluxo atual atualiza os paineis diretamente em pontos especificos.

## Fluxo de Ataque

```text
1. ActionPanel._on_atacar_pressionado()
   -> desabilitar_acoes()
   -> acao_atacar.emit()

2. CombatManager._iniciar_ataque()
   -> acao_em_progresso = true
   -> RegionalSelector.ativar_para_ataque(combatente_ativo)

3. RegionalSelector._on_confirmar()
   -> selecao_confirmada.emit(regioes_finais)
   -> desativar()

4. CombatManager._on_regioes_confirmadas(regioes)
   -> EnemyPanel.ativar_seletor_alvo(combatentes_inimigo)

5. EnemyPanel._on_botao_combatente_pressionado(alvo)
   -> alvo_selecionado.emit(alvo)
   -> desativar_seletor_alvo()

6. CombatManager._on_alvo_selecionado(alvo)
   -> _processar_ataque(combatente_ativo, alvo, regioes_selecionadas)
```

## Fluxo de Duelo

```text
1. ActionPanel abre lista de pericias.
2. Jogador abre detalhes de Duelo.
3. Jogador confirma USAR PERICIA.
4. ActionPanel emite pericia_escolhida("Duelo").
5. CombatManager pede alvo inimigo.
6. EnemyPanel emite alvo_selecionado(alvo).
7. CombatManager._executar_pericia_duelo(alvo).
```

## Fluxo de Item

```text
1. ActionPanel emite item_escolhido(nome_item).
2. CombatManager guarda item_pendente.
3. PartyPanel ativa seletor de aliado.
4. PartyPanel emite aliado_selecionado(aliado).
5. RegionalSelector ativa modo ITEM.
6. RegionalSelector emite selecao_confirmada(regioes).
7. CombatManager._usar_item(regioes[0]).
```

## Tabela Rapida de Conexoes

| Emissor | Sinal | Receptor |
| --- | --- | --- |
| ActionPanel | `acao_atacar` | `_iniciar_ataque()` |
| ActionPanel | `acao_habilidade` | `_iniciar_habilidade()` |
| ActionPanel | `acao_item` | `_iniciar_item()` |
| ActionPanel | `item_escolhido` | `_on_item_escolhido()` |
| ActionPanel | `pericia_escolhida` | `_on_pericia_escolhida()` |
| ActionPanel | `habilidade_escolhida` | `_on_habilidade_escolhida()` |
| ActionPanel | `turno_passado` | `_on_turno_passado()` |
| ActionPanel | `habilidade_sobrecarga` | `_ativar_sobrecarga()` |
| RegionalSelector | `regiao_selecionada` | `_on_regiao_selecionada()` |
| RegionalSelector | `selecao_confirmada` | `_on_regioes_confirmadas()` |
| RegionalSelector | `selecao_cancelada` | `_on_selecao_cancelada()` |
| EnemyPanel | `alvo_selecionado` | `_on_alvo_selecionado()` |
| PartyPanel | `aliado_selecionado` | `_on_personagem_item_selecionado()` |
