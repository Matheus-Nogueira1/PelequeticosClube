# Documentacao - Ascencaozeta Pelequeta

Esta pasta reune a documentacao do projeto Ascencaozeta Pelequeta / Pelequeticos Clube / Oblivio. O codigo atual esta em Godot 4 e o sistema de combate principal fica em `scripts/battle/`.

## Comece Aqui

- [ESTADO_ATUAL_CODIGO.md](ESTADO_ATUAL_CODIGO.md): retrato mais recente do codigo atual, gerado a partir da leitura direta de `scripts/battle/`, `scripts/data/` e scripts principais.
- [STATUS_COMBATE.md](STATUS_COMBATE.md): status funcional do combate e pendencias tecnicas reais.
- [README_COMBATE.md](README_COMBATE.md): indice da documentacao de combate.

## Regras e Sistema

- [ATRIBUTOS_OBLIVIO.md](ATRIBUTOS_OBLIVIO.md): atributos fixos, atributos mutaveis e conceitos de personagem.
- [OBLIVIO_REFERENCE.md](OBLIVIO_REFERENCE.md): referencia de regras do sistema Oblivio adaptado.
- [COMBAT_SYSTEM_README.md](COMBAT_SYSTEM_README.md): arquitetura geral do combate.
- [SIGNALS_REFERENCE.md](SIGNALS_REFERENCE.md): sinais e comunicacao entre paineis.

## Guias e Historico

- [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md): guia de implementacao e manutencao.
- [QUICK_START.md](QUICK_START.md): guia rapido.
- [COMBAT_FIXES_v2.md](COMBAT_FIXES_v2.md): historico de correcoes.
- [DEFENSIVE_IMPROVEMENTS.md](DEFENSIVE_IMPROVEMENTS.md): padroes defensivos.
- [REFACTORING_OBLIVIO.md](REFACTORING_OBLIVIO.md): historico da refatoracao para Estresse por regiao.
- [INDEX_COMPLETE.md](INDEX_COMPLETE.md): indice historico completo.

## Estrutura Atual do Projeto

```text
ascencaozeta-pelequeta/
|-- assets/
|-- fonts/
|-- prefabs/
|-- scenes/
|   |-- combat.tscn
|   |-- caixa-dialogo.tscn
|   |-- player.tscn
|   `-- tittle_screen.tscn
|-- scripts/
|   |-- battle/
|   |   |-- action_panel.gd
|   |   |-- combat_manager.gd
|   |   |-- combat_log.gd
|   |   |-- enemy_panel.gd
|   |   |-- party_panel.gd
|   |   |-- regional_selector.gd
|   |   `-- rolagens-dados-d6.gd
|   |-- data/
|   |   |-- arma_data.gd
|   |   |-- combatente_data.gd
|   |   |-- fardo_data.gd
|   |   |-- habilidade_data.gd
|   |   |-- inimigo_data.gd
|   |   |-- item_data.gd
|   |   |-- pericia_data.gd
|   |   |-- personagens_principais.gd
|   |   `-- protese_data.gd
|   |-- player.gd
|   |-- caixa-dialogo.gd
|   |-- dialogos.gd
|   `-- tittle_screen.gd
|-- docs/
`-- project.godot
```

## Status Resumido

Implementado no fluxo principal:

- Combate por turnos em `combat.tscn`.
- Ordem de turno por `atributo_velocidade`.
- Selecao de regioes com limite de ate 5 riscos.
- Rolagem D6 para combate.
- Estresse por regiao.
- Quebra/reducao temporaria de Protecao.
- Menu interno de pericias, habilidades e itens no `ActionPanel`.
- Pericia `Duelo` com analise do inimigo e reducao de Protecao em sucesso extremo.
- Uso parcial de habilidades com validacao/consumo de PA.
- Uso de `Estus Fleskus` para restaurar Estresse de uma regiao.

Parcial ou pendente:

- IA de inimigos.
- Movimento e posicionamento por alcance/fileira.
- Custos de PA unificados para todas as acoes.
- Efeitos mecanicos completos para a maioria das habilidades.
- Pericias usando treino, atributo e especializacao na rolagem.

## Nota de Manutencao

Alguns documentos antigos ainda registram etapas historicas do desenvolvimento e podem conter caminhos ou status antigos. Quando houver conflito, use [ESTADO_ATUAL_CODIGO.md](ESTADO_ATUAL_CODIGO.md) como fonte documental mais recente e o codigo como fonte final de verdade.
