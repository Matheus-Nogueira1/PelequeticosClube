# Guia de Implementacao e Manutencao

Este guia descreve como trabalhar com o combate atual sem voltar para a arquitetura antiga baseada em dicionarios/HP. A fonte tecnica mais detalhada e [ESTADO_ATUAL_CODIGO.md](ESTADO_ATUAL_CODIGO.md).

## Principios do Codigo Atual

- O combate usa `CombatenteData`, nao dicionarios soltos.
- O fluxo principal usa D6, nao D20.
- O estado de vida e Estresse por regiao, nao HP global.
- Os scripts de combate ficam em `scripts/battle/`.
- Os bancos de dados ficam em `scripts/data/`.
- `CombatManager` decide regras; paineis de UI emitem sinais e exibem informacao.

## Arquivos Centrais

```text
scripts/battle/
|-- combat_manager.gd
|-- action_panel.gd
|-- regional_selector.gd
|-- enemy_panel.gd
|-- party_panel.gd
|-- combat_log.gd
`-- rolagens-dados-d6.gd

scripts/data/
|-- combatente_data.gd
|-- personagens_principais.gd
|-- inimigo_data.gd
|-- pericia_data.gd
|-- habilidade_data.gd
|-- item_data.gd
|-- arma_data.gd
|-- fardo_data.gd
`-- protese_data.gd
```

## Integracao com a Cena

`scenes/combat.tscn` deve manter estes unique names:

```text
%PartyPanel
%EnemyPanel
%Battlefield
%RegionalPanel
%ActionPanel
```

O log e acessado por caminho direto:

```text
$MarginContainer/VBoxContainer/LogPanel/RichTextLabel
```

## Como Alterar Combatentes de Exemplo

O setup atual fica em:

```text
scripts/battle/combat_manager.gd -> _setup_exemplo()
```

Ele usa fabricas:

```gdscript
var mob = PersonagensData.criar_mob()
var escolhido = PersonagensData.criar_escolhido()
var jp = PersonagensData.criar_JP()

var carcaca1 = InimigoData.criar_carcaca()
var carcaca2 = InimigoData.criar_carcaca()
```

Para mudar dados de personagens, prefira editar ou criar novas funcoes em `scripts/data/personagens_principais.gd` e `scripts/data/inimigo_data.gd`, preservando `CombatenteData` como estrutura base.

## Como Adicionar uma Pericia

1. Registre a pericia em `scripts/data/pericia_data.gd`.
2. Garanta que o combatente tenha treino maior que zero em `conhecimentos_treino`.
3. Se a pericia tiver efeito de combate, trate o nome em `CombatManager._on_pericia_escolhida()`.
4. Se precisar de alvo, siga o padrao de `Duelo`: guarde uma pendencia e ative o `EnemyPanel`.

Estado atual importante: `PericiaData.testar_pericia()` ainda nao usa treino, atributo ou especializacao. Fechar essa regra deve vir antes de balancear pericias novas.

## Como Adicionar uma Habilidade

1. Registre a habilidade em `scripts/data/habilidade_data.gd`.
2. Adicione o nome da habilidade em `combatente.habilidades`.
3. O `ActionPanel` vai listar a habilidade automaticamente quando o banco encontra o nome.
4. `HabilidadeData.usar_habilidade()` ja valida conhecimento e PA.
5. Implemente o efeito real em `CombatManager._on_habilidade_escolhida()` ou em um metodo dedicado chamado a partir dele.

Evite colocar regra de combate dentro do `ActionPanel`. O painel deve mostrar detalhes e emitir a escolha confirmada.

## Como Adicionar um Item

1. Registre o item em `scripts/data/item_data.gd`.
2. Adicione o nome ao `combatente.inventario`.
3. Para consumiveis que miram uma regiao, siga o fluxo atual do `Estus Fleskus`:
   - `ActionPanel` escolhe item.
   - `PartyPanel` escolhe aliado.
   - `RegionalSelector` escolhe regiao.
   - `ItemData.usar_item()` aplica o efeito.

## Como Trabalhar com Foco

Antes de adicionar `grab_focus()`, verifique o fluxo atual:

- `ActionPanel.ativar_para()` chama foco diferido no botao Atacar.
- `ActionPanel.habilitar_acoes()` chama `_mostrar_menu_principal()`.
- `_mostrar_menu_principal()` tambem agenda foco no botao Atacar.
- Listas usam `_focar_primeiro_botao()` com `await get_tree().process_frame`.
- Detalhes focam imediatamente o botao de confirmar.

Correcao limpa recomendada: centralizar restauracao de foco do menu principal em uma unica funcao e chamar essa funcao apenas quando o painel volta ao estado `PRINCIPAL`.

## Como Implementar PA Unificado

`CombatenteData` ja possui:

```gdscript
var pontos_acao_atuais: int = 3
var pontos_acao_maximos: int = 3
```

`HabilidadeData.usar_habilidade()` ja chama `combatente.consumir_pontos_acao(custo)`.

O proximo passo e fazer `CombatManager` aplicar custo tambem para:

- Ataque.
- Pericia.
- Item.
- Movimento.
- Acao completa.

Use o enum `ActionType` ja declarado em `CombatManager`, mas mantenha a decisao de custo centralizada para nao espalhar numeros magicos pelos paineis.

## Como Implementar IA de Inimigos

O ponto atual e:

```text
scripts/battle/combat_manager.gd -> _executar_turno_inimigo()
```

Hoje ele aguarda um timer curto e passa o turno. Uma implementacao inicial deve:

- escolher alvo vivo;
- escolher regioes validas;
- chamar o mesmo processamento de ataque usado pelo jogador;
- atualizar paineis e log;
- respeitar fim de combate.

## Cuidados Antes de Alterar Regras

- Nao use `scripts/rolagem-dados.gd` como referencia do combate principal; ele e um prototipo antigo com D20.
- Nao documente HP global para combatentes; o sistema atual usa Estresse por regiao.
- Nao duplicar nomes de sinais antigos como `inimigo_selecionado`; o sinal atual do `EnemyPanel` e `alvo_selecionado`.
- Nao colocar regra mecanica no `ActionPanel` quando ela altera estado real do combate.

## Checklist de Alteracao Segura

- [ ] Identifique se a mudanca e UI, dado ou regra de combate.
- [ ] Edite o arquivo da camada correta.
- [ ] Preserve sinais existentes ou atualize [SIGNALS_REFERENCE.md](SIGNALS_REFERENCE.md).
- [ ] Atualize [STATUS_COMBATE.md](STATUS_COMBATE.md) quando uma pendencia mudar de estado.
- [ ] Teste ataque, pericia, habilidade e item quando mexer em `CombatManager` ou `ActionPanel`.
