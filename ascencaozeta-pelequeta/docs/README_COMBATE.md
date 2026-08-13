# Sistema de Combate Oblivio - Indice Atual

Esta pagina resume onde esta cada parte da documentacao de combate. Para o estado real do codigo atual, comece por [ESTADO_ATUAL_CODIGO.md](ESTADO_ATUAL_CODIGO.md).

## Documentos Principais

- [ESTADO_ATUAL_CODIGO.md](ESTADO_ATUAL_CODIGO.md): leitura atual de `scripts/battle/`, `scripts/data/` e scripts principais.
- [STATUS_COMBATE.md](STATUS_COMBATE.md): checklist do que esta implementado, parcial e pendente.
- [COMBAT_SYSTEM_README.md](COMBAT_SYSTEM_README.md): arquitetura geral do sistema.
- [SIGNALS_REFERENCE.md](SIGNALS_REFERENCE.md): sinais atuais entre paineis e `CombatManager`.
- [OBLIVIO_REFERENCE.md](OBLIVIO_REFERENCE.md): regras e conceitos de Oblivio.
- [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md): orientacoes de integracao e manutencao.

## Scripts do Combate Atual

| Arquivo | Responsabilidade |
| --- | --- |
| `scripts/battle/combat_manager.gd` | Orquestra combate, turnos, ataques, pericias, habilidades, itens e fim de combate. |
| `scripts/battle/action_panel.gd` | Menu principal e subtelas de pericias, habilidades e itens. |
| `scripts/battle/regional_selector.gd` | Selecao de regioes para ataque, item, habilidade ou pericia. |
| `scripts/battle/enemy_panel.gd` | Lista inimigos, revela detalhes apos Duelo e permite selecionar alvo. |
| `scripts/battle/party_panel.gd` | Lista aliados, mostra PA, arma, Protecao, regioes e permite selecionar aliado para item. |
| `scripts/battle/combat_log.gd` | Log colorido de eventos do combate. |
| `scripts/battle/rolagens-dados-d6.gd` | Regras de rolagem D6 usadas pelo combate. |

## Dados Usados pelo Combate

| Arquivo | Responsabilidade |
| --- | --- |
| `scripts/data/combatente_data.gd` | Estado de jogadores, inimigos e NPCs. |
| `scripts/data/personagens_principais.gd` | Mob, Escolhido e JPdaMaldade. |
| `scripts/data/inimigo_data.gd` | Templates de inimigos. |
| `scripts/data/pericia_data.gd` | Banco e testes de pericias. |
| `scripts/data/habilidade_data.gd` | Banco, validacao e consumo de PA de habilidades. |
| `scripts/data/item_data.gd` | Inventario simples e uso de Estus Fleskus. |
| `scripts/data/arma_data.gd` | Armas e rolagem de dano. |
| `scripts/data/fardo_data.gd` | Fardos aplicados ao atingir limite de Torso. |
| `scripts/data/protese_data.gd` | Proteses, destruicao e reparo. |

## Fluxo Basico Atual

```text
CombatManager._ready()
  -> conecta sinais dos paineis
  -> cria combatentes de exemplo
  -> atualiza PartyPanel e EnemyPanel
  -> ordena turnos por atributo_velocidade
  -> avanca para o proximo combatente

Turno do jogador
  -> ActionPanel.ativar_para(combatente)
  -> jogador escolhe Atacar, Pericia, Habilidade, Item ou Passar Turno

Atacar
  -> RegionalSelector.ativar_para_ataque()
  -> selecao de ate 5 riscos
  -> EnemyPanel.ativar_seletor_alvo()
  -> CombatManager._processar_ataque()

Pericia
  -> ActionPanel lista pericias treinadas
  -> detalhes
  -> CombatManager executa Duelo se aplicavel

Habilidade
  -> ActionPanel lista habilidades conhecidas
  -> detalhes
  -> HabilidadeData valida e consome PA

Item
  -> ActionPanel lista inventario
  -> PartyPanel seleciona aliado
  -> RegionalSelector seleciona regiao
  -> ItemData usa Estus Fleskus quando valido
```

## Estado Atual em Uma Frase

O combate D6 por turnos ja possui fluxo jogavel de ataque, pericia Duelo, habilidades com validacao de PA e item Estus, mas ainda precisa consolidar PA para todas as acoes, IA, alcance/fileira e efeitos completos das habilidades.

## Nota Sobre Documentos Historicos

Arquivos como `COMBAT_FIXES_v2.md`, `REFACTORING_OBLIVIO.md`, `SUMARIO_EXECUTIVO.md` e `INDEX_COMPLETE.md` podem conter afirmacoes antigas. Eles continuam uteis para contexto historico, mas nao devem substituir a leitura de [ESTADO_ATUAL_CODIGO.md](ESTADO_ATUAL_CODIGO.md) e do codigo atual.
