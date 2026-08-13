# Estado Atual do Codigo

Este documento foi atualizado a partir da leitura direta dos scripts atuais do projeto. Ele deve ser usado como retrato tecnico do estado real do codigo antes de consultar documentos historicos.

## Escopo Analisado

- `scripts/battle/`: `action_panel.gd`, `combat_manager.gd`, `combat_log.gd`, `enemy_panel.gd`, `party_panel.gd`, `regional_selector.gd`, `rolagens-dados-d6.gd`.
- `scripts/data/`: `arma_data.gd`, `combatente_data.gd`, `fardo_data.gd`, `habilidade_data.gd`, `inimigo_data.gd`, `item_data.gd`, `pericia_data.gd`, `personagens_principais.gd`, `protese_data.gd`.
- Scripts principais: `player.gd`, `dialogos.gd`, `caixa-dialogo.gd`, `dados.gd`, `click-dados-d6.gd`, `rolagem-dados.gd`, `seletor-corpo.gd`, `tittle_screen.gd`.
- Cenas/configuracao verificadas: `project.godot`, `scenes/combat.tscn`, `scenes/player.tscn`, `scenes/tittle_screen.tscn`, `scenes/caixa-dialogo.tscn`.

## Observacao Sobre `atualizar_docs.py`

O script anexado nao foi executado. Ele define `ROOT = Path(__file__).resolve().parent` e procura `battle/`, `data/` e `docs/` diretamente ao lado do arquivo Python. No projeto atual, os caminhos corretos ficam em `ascencaozeta-pelequeta/scripts/battle`, `ascencaozeta-pelequeta/scripts/data` e `ascencaozeta-pelequeta/docs`.

Mesmo tendo uma funcao de seguranca para impedir escrita fora de `docs/`, executar o arquivo como anexado criaria ou atualizaria a pasta `docs/` no local do proprio anexo, nao a documentacao real do projeto. Por isso, a atualizacao foi feita manualmente e somente em Markdown dentro de `ascencaozeta-pelequeta/docs/`.

## Arquitetura Atual do Combate

`scenes/combat.tscn` usa `scripts/battle/combat_manager.gd` na raiz da cena. O `CombatManager` encontra os paineis por unique names:

- `%PartyPanel` usa `PartyPanel`.
- `%EnemyPanel` usa `EnemyPanel`.
- `%RegionalPanel` usa `RegionalSelector`.
- `%ActionPanel` usa `ActionPanel`.
- `$MarginContainer/VBoxContainer/LogPanel/RichTextLabel` usa `CombatLog`.

Fluxo principal:

1. `_ready()` conecta sinais e chama `_inicializar_combate()`.
2. `_setup_exemplo()` cria Mob, Escolhido, JPdaMaldade e duas Carcacas.
3. Party e inimigos sao renderizados nos paineis.
4. A iniciativa atual usa `atributo_velocidade` diretamente, sem rolagem adicional.
5. `ordem_turno` e ordenada por iniciativa decrescente.
6. `_avancar_turno()` ativa o `ActionPanel` quando o combatente e jogador.
7. Inimigos ainda usam placeholder: aguardam um timer curto e passam o turno.

## Regras de D6 Implementadas

O combate atual usa `scripts/battle/rolagens-dados-d6.gd`:

- `1`: Falha Critica.
- `2-3`: Falha Regular.
- `4-5`: Sucesso Regular.
- `6`: Sucesso Extremo.

Cada regiao arriscada gera uma rolagem D6. Sucesso Regular vale 1 acerto; Sucesso Extremo vale 2 acertos. Falha Regular gera 1 ponto de Estresse na regiao arriscada do atacante; Falha Critica gera 2 pontos.

O script `scripts/rolagem-dados.gd` ainda contem um prototipo antigo com D20 e Zona de Acerto 1/13/20. Ele nao e o fluxo usado pela cena de combate atual.

## Ataque e Protecao

Ataque normal:

1. `ActionPanel` emite `acao_atacar`.
2. `CombatManager._iniciar_ataque()` desabilita o painel e ativa o `RegionalSelector`.
3. `RegionalSelector` permite ate 5 riscos.
4. Sem Sobrecarga, a mesma regiao alterna entre selecionada e nao selecionada.
5. Com Sobrecarga, a mesma regiao pode ser arriscada mais de uma vez, respeitando o limite total de 5 riscos.
6. Ao confirmar regioes, o `EnemyPanel` entra em modo seletor.
7. Ao escolher o alvo, `_processar_ataque()` rola os D6 e aplica os resultados.

Se os sucessos forem menores que a Protecao atual do alvo, a protecao temporaria e reduzida pelo total de sucessos. Se os sucessos forem iguais ou maiores que a Protecao atual, a protecao e considerada quebrada, o dano total e `atributo_dano + dano da arma`, e o Estresse e aplicado no Torso do alvo.

A protecao temporaria e restaurada quando o combatente que a quebrou volta a ter turno, por `_restaurar_protecoes()`.

## Regioes, Estresse e Fardos

`CombatenteData.REGIOES` define cinco regioes:

- Torso.
- Braco Direito.
- Braco Esquerdo.
- Perna Direita.
- Perna Esquerda.

Cada regiao possui `atual` e `limite`. O Torso, ao atingir o limite, marca desmaio. Inimigos morrem ao atingir o limite do Torso; jogadores recebem Fardos por `FardoData.sortear_fardo()`.

Fardos implementados:

- Guilhotina.
- Deterioracao.
- Covardia.
- Mal das Pernas.
- Fragilidade.
- Ataque Cardiaco.

Pendencia real do codigo: `FardoData.testar_ataque_cardiaco()` chama `PericiaData.testar_conhecimento()`, mas `PericiaData` expoe `testar_pericia()`. Essa funcao precisa ser revisada antes de ser usada em jogo.

## Pericias

`PericiaData` registra dez conhecimentos:

- Bandidagem.
- Duelo.
- Emocional.
- Esforco.
- Mistico.
- Mundo.
- Rastro.
- Reflexos.
- Saber.
- Social.

Estado atual importante: apesar do comentario do arquivo falar em D6 + atributo + treino, `testar_pericia()` hoje rola apenas `1D6` e classifica o resultado. O valor de treino guardado em `CombatenteData.conhecimentos_treino` e exibido no menu, mas ainda nao altera a rolagem.

`Duelo` e a unica pericia com efeito de combate implementado:

- Falha Critica/Falha: nao analisa e nao reduz protecao.
- Sucesso: marca o inimigo como analisado, revelando informacoes detalhadas no `EnemyPanel`.
- Sucesso Extremo: marca como analisado e aumenta `reducao_protecao_temporaria` do alvo em 1.

## Habilidades

`HabilidadeData` contem um banco de habilidades principais, unicas e gerais. O `ActionPanel` mostra habilidades conhecidas por categoria, abre uma tela de detalhes e confirma o uso.

O uso atual valida:

- Se a habilidade existe.
- Se o combatente conhece a habilidade, tolerando diferencas de capitalizacao.
- Se o combatente tem PA suficiente.
- O consumo de PA pelo custo cadastrado.

Estado atual importante: a maioria dos efeitos de habilidade ainda nao aplica mecanicas proprias. Ao confirmar, o sistema consome PA, registra o texto do efeito no log e reabilita o painel. A excecao pratica e Sobrecarga, tratada como acao especial no `ActionPanel` e processada por `_ativar_sobrecarga()`.

## Itens

`ItemData` implementa o banco de itens com `Estus Fleskus`.

Fluxo atual:

1. O jogador abre o menu de itens pelo `ActionPanel`.
2. O painel lista nomes do inventario do combatente ativo.
3. Ao confirmar um item, o `CombatManager` pede um aliado pelo `PartyPanel`.
4. Depois pede uma regiao pelo `RegionalSelector`.
5. `Estus Fleskus` tenta restaurar totalmente o Estresse daquela regiao.
6. Em sucesso, o item e removido do inventario.

Restricoes atuais do Estus:

- A regiao precisa existir.
- Regiao perdida nao pode ser restaurada.
- Protese destruida bloqueia uso.
- Regiao sem Estresse retorna falha.

## Foco e Navegacao de UI

O `ActionPanel` controla foco para teclado/controle em alguns pontos:

- `ativar_para()` chama `show()`, `habilitar_acoes()` e depois `call_deferred("_focar_botao")`.
- `habilitar_acoes()` chama `_mostrar_menu_principal()`.
- `_mostrar_menu_principal()` limpa telas contextuais, mostra os botoes fixos e tambem chama `call_deferred("_focar_botao")`.
- Menus de lista chamam `_focar_primeiro_botao(lista)`, que aguarda `get_tree().process_frame`.
- Telas de detalhes focam imediatamente o botao de confirmar.

Isso significa que o foco nao e totalmente centralizado em uma unica funcao de restauracao. Antes de alterar codigo de foco, a correcao limpa deve consolidar o retorno ao menu principal em um ponto unico, evitando multiplos `grab_focus()` em cascata.

## Dados de Personagens

`PersonagensData` cria tres jogadores de exemplo:

- Mob: Papel Quem Protege, arma `TacoGigante`, pericias Duelo/Esforco/Reflexos, habilidade `Escudo humano`.
- Escolhido: Papel Quem Cuida, protese no Braco Direito, arma `BolaDeFogo`, inventario com `Estus Fleskus`, habilidade `Ajudar os necessitados`.
- JPdaMaldade: Papel Quem Manda, Braco Direito perdido, arma `Besta`, habilidade `Dar uma maozinha`, Sobrecarga ja ativa.

`InimigoData` cria Carcaca, Goblin e Orc Guerreiro. O combate de exemplo usa duas Carcacas.

## Scripts Principais Fora do Combate

- `project.godot`: projeto Godot 4, cena principal por UID e autoload `Dialogos`.
- `tittle_screen.gd`: tela inicial com start para `caixa-dialogo.tscn` e quit.
- `caixa-dialogo.gd`: caixa de dialogo com efeito de escrita, avanco por `ui_accept`, cancelamento por `ui_cancel` e troca para `player.tscn` ao finalizar.
- `dialogos.gd`: autoload com conversas estaticas.
- `player.gd`: movimentacao 2D por acoes `left`, `right`, `up`, `down` e animacao por direcao.
- `dados.gd`, `click-dados-d6.gd`, `seletor-corpo.gd` e `rolagem-dados.gd`: prototipos/suportes de dados e selecao; nem todos fazem parte do fluxo principal de `combat.tscn`.

## Pendencias Tecnicas Reais

- IA de inimigos ainda e placeholder.
- Movimento, posicionamento por alcance e fileira ainda nao estao implementados no fluxo principal.
- PA existe em `CombatenteData` e e consumido por habilidades, mas ataque/pericia/item ainda nao possuem custo unificado por `ActionType`.
- `PericiaData.testar_pericia()` ainda nao usa treino, atributo ou especializacao.
- A maior parte das habilidades registra efeito textual, mas ainda nao aplica regra mecanica especifica.
- O fluxo de foco do `ActionPanel` funciona por varios pontos de `grab_focus()`, sem uma restauracao central unica.
- Existem scripts/prototipos antigos de D20 que devem ser tratados como historicos enquanto o combate principal usa D6.
