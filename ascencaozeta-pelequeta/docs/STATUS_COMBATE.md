# Status da Tela de Combate Oblivio

**Data:** 13/08/2026  
**Fonte:** leitura direta dos scripts atuais.  
**Documento complementar:** [ESTADO_ATUAL_CODIGO.md](ESTADO_ATUAL_CODIGO.md)

## Implementado no Fluxo Principal

### Combate e Turnos

- [x] Cena `scenes/combat.tscn` com `CombatManager` na raiz.
- [x] Criacao de grupo de exemplo com Mob, Escolhido e JPdaMaldade.
- [x] Criacao de duas Carcacas como inimigos de exemplo.
- [x] Ordem de turno por `atributo_velocidade`.
- [x] Turno do jogador ativa o `ActionPanel`.
- [x] Turno de inimigo existe como placeholder automatico que passa o turno.
- [x] Botao `PASSAR TURNO`.
- [x] Verificacao de vitoria/derrota quando combatentes sao removidos.

### Ataque D6

- [x] Selecao de regioes por `RegionalSelector`.
- [x] Limite de ate 5 regioes/riscos.
- [x] Sobrecarga permite repetir a mesma regiao no risco.
- [x] Validacao contra regioes perdidas, proteses destruidas e regioes esgotadas.
- [x] Rolagem D6 por regiao arriscada.
- [x] Sucesso Regular vale 1 acerto.
- [x] Sucesso Extremo vale 2 acertos.
- [x] Falha Regular gera 1 Estresse na regiao arriscada do atacante.
- [x] Falha Critica gera 2 Estresse na regiao arriscada do atacante.
- [x] Sucessos reduzem Protecao temporaria quando nao quebram a defesa.
- [x] Ataque que iguala ou supera a Protecao aplica dano no Torso do alvo.
- [x] Dano atual = `atributo_dano + rolagem da arma`.

### Paineis de UI

- [x] `ActionPanel` cria menu principal por codigo.
- [x] `ActionPanel` possui telas internas de lista e detalhes para pericias, habilidades e itens.
- [x] `PartyPanel` exibe aliados, PA, Protecao, arma, regioes e status especiais.
- [x] `EnemyPanel` exibe inimigos e revela detalhes completos apos analise por Duelo.
- [x] `CombatLog` registra eventos coloridos por tipo.
- [x] Seletor de alvo inimigo por teclado/controle quando ativado.
- [x] Seletor de aliado para itens por teclado/controle quando ativado.

### Dados

- [x] `CombatenteData` com atributos fixos e mutaveis.
- [x] Estresse por cinco regioes.
- [x] Pontos de Acao no combatente.
- [x] Inventario simples por lista de nomes.
- [x] Armas `Besta`, `BolaDeFogo` e `TacoGigante`.
- [x] Proteses e regioes perdidas.
- [x] Fardos sorteados ao atingir limite de Torso em jogadores.
- [x] Templates de inimigos em `InimigoData`.

## Parcialmente Implementado

### Pericias

- [x] Banco com dez pericias.
- [x] Menu de pericias treinadas no `ActionPanel`.
- [x] Tela de detalhes antes de confirmar.
- [x] `Duelo` implementado com analise do alvo e reducao de Protecao em sucesso extremo.
- [ ] `testar_pericia()` ainda nao usa atributo, treino ou especializacao; hoje classifica apenas uma rolagem D6.
- [ ] As demais pericias ainda nao possuem efeito de combate proprio.

### Habilidades

- [x] Banco de habilidades com categorias Principal, Unica e Geral.
- [x] Menu agrupado por categoria.
- [x] Tela de detalhes antes de confirmar.
- [x] Validacao de existencia, conhecimento e PA.
- [x] Consumo de PA ao usar habilidade cadastrada.
- [x] Sobrecarga tratada como habilidade especial no fluxo do painel.
- [ ] A maioria das habilidades ainda nao aplica efeito mecanico alem de consumir PA e registrar texto no log.

### Itens

- [x] Banco de itens com `Estus Fleskus`.
- [x] Menu de inventario.
- [x] Selecao de aliado alvo.
- [x] Selecao de regiao alvo.
- [x] Restauracao total de Estresse da regiao em caso valido.
- [x] Remocao do item em caso de sucesso.
- [ ] Inventario ainda e uma lista simples de nomes.
- [ ] Equipamentos e itens de quest ainda nao possuem fluxo proprio.

### Pontos de Acao

- [x] `CombatenteData` possui PA atual/maximo.
- [x] Habilidades consomem PA.
- [ ] Ataque, pericia, item, movimento e acoes completas ainda nao usam uma tabela unificada de custo por `ActionType`.
- [ ] PA nao e restaurado explicitamente no inicio de cada turno pelo fluxo atual.

## Nao Implementado

- [ ] IA real de inimigos.
- [ ] Movimento em fileira.
- [ ] Alcances `Adjacente`, `Curto`, `Medio`, `Longo`, `Absoluto` no fluxo de combate.
- [ ] Efeitos completos de status.
- [ ] Tela de resultado, experiencia e loot.
- [ ] Persistencia de dados.
- [ ] Balanceamento final.

## Pendencias Tecnicas Importantes

- `FardoData.testar_ataque_cardiaco()` chama `PericiaData.testar_conhecimento()`, mas esse metodo nao existe no `PericiaData` atual.
- `scripts/rolagem-dados.gd` ainda guarda um prototipo D20; o combate principal usa D6 em `scripts/battle/rolagens-dados-d6.gd`.
- O foco do `ActionPanel` e restaurado por varios pontos (`ativar_para()`, `habilitar_acoes()`, `_mostrar_menu_principal()` e confirmacoes). Antes de mexer nisso, convem centralizar a restauracao em uma unica funcao.
- Comentarios de alguns documentos antigos ainda descrevem menus como stubs, mas o codigo atual ja possui listas e telas de detalhes.

## Prioridades Sugeridas

1. Centralizar restauracao de foco do `ActionPanel`.
2. Fazer `PericiaData.testar_pericia()` usar treino, atributo e especializacao.
3. Unificar custo de PA para ataque, pericia, habilidade, item e movimento.
4. Implementar efeitos mecanicos das habilidades principais.
5. Substituir IA placeholder dos inimigos.
6. Implementar alcance/fileira.
