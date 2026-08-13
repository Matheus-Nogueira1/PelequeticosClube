# Quick Start - Combate Atual

Use este guia para localizar e testar o fluxo atual de combate. Para detalhes completos, leia [ESTADO_ATUAL_CODIGO.md](ESTADO_ATUAL_CODIGO.md).

## 1. Abra a Cena

No Godot 4:

```text
scenes/combat.tscn
```

A cena ja referencia os scripts atuais em `scripts/battle/`.

## 2. Confirme os Scripts Principais

| No/Cena | Script atual |
| --- | --- |
| Raiz de `combat.tscn` | `res://scripts/battle/combat_manager.gd` |
| `%PartyPanel` | `res://scripts/battle/party_panel.gd` |
| `%EnemyPanel` | `res://scripts/battle/enemy_panel.gd` |
| `%RegionalPanel` | `res://scripts/battle/regional_selector.gd` |
| `%ActionPanel` | `res://scripts/battle/action_panel.gd` |
| `LogPanel/RichTextLabel` | `res://scripts/battle/combat_log.gd` |

## 3. Execute o Combate

Ao rodar `combat.tscn`, o `CombatManager` cria:

- Jogadores: Mob, Escolhido e JPdaMaldade.
- Inimigos: Carcaca 1 e Carcaca 2.

O primeiro turno de jogador deve ativar o `ActionPanel`.

## 4. Teste Ataque

1. Escolha `ATACAR`.
2. Selecione de 1 a 5 regioes no `RegionalSelector`.
3. Confirme.
4. Selecione um inimigo no `EnemyPanel`.
5. Veja os resultados no `CombatLog`.

Resultado esperado:

- Cada regiao rola 1D6.
- `1` gera Falha Critica.
- `2-3` gera Falha Regular.
- `4-5` gera Sucesso Regular.
- `6` gera Sucesso Extremo.
- Falhas geram Estresse no atacante.
- Sucessos reduzem ou quebram a Protecao do alvo.

## 5. Teste Pericia

1. Escolha `PERICIA`.
2. Abra uma pericia listada.
3. Confirme `USAR PERICIA`.

Estado atual:

- `Duelo` e a pericia com efeito de combate implementado.
- Sucesso em Duelo revela dados do inimigo.
- Sucesso Extremo em Duelo reduz Protecao temporaria do alvo.

## 6. Teste Habilidade

1. Escolha `HABILIDADE`.
2. Abra uma habilidade conhecida.
3. Confirme o uso.

Estado atual:

- O sistema valida se a habilidade existe.
- O sistema valida se o combatente conhece a habilidade.
- O sistema valida e consome PA.
- A maior parte dos efeitos ainda e textual/logica pendente.
- Sobrecarga e tratada como fluxo especial.

## 7. Teste Item

1. Use o Escolhido, que possui `Estus Fleskus` no inventario inicial.
2. Escolha `ITEM`.
3. Selecione o Estus.
4. Selecione um aliado.
5. Selecione uma regiao com Estresse.

Estado atual:

- O Estus restaura totalmente o Estresse da regiao escolhida.
- O item e removido do inventario apenas em caso de sucesso.

## Troubleshooting

### O painel nao recebeu foco

O `ActionPanel` hoje restaura foco em mais de um ponto do fluxo. Consulte [ESTADO_ATUAL_CODIGO.md](ESTADO_ATUAL_CODIGO.md), secao "Foco e Navegacao de UI", antes de alterar qualquer `grab_focus()`.

### Caminho antigo nao funciona

Use `res://scripts/battle/...` para scripts de combate. Caminhos como `res://scripts/combat_manager.gd` pertencem a documentacao antiga.

### O codigo parece usar D20

O prototipo `scripts/rolagem-dados.gd` ainda existe, mas o combate principal usa `scripts/battle/rolagens-dados-d6.gd`.
