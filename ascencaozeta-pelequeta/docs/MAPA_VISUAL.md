# Mapa Visual do Combate Atual

Este mapa mostra a organizacao atual do combate em `scenes/combat.tscn`.

## Cena

```text
Control (CombatManager)
`-- MarginContainer
    `-- VBoxContainer
        |-- TopBar
        |   `-- VBoxContainer
        |       |-- HBoxContainer
        |       |   |-- PartyPanel
        |       |   |-- Battlefield
        |       |   `-- EnemyPanel
        |       `-- HBoxContainer2
        |           |-- RegionalPanel
        |           `-- ActionPanel
        `-- LogPanel
            `-- RichTextLabel (CombatLog)
```

## Responsabilidades

```text
CombatManager
|-- cria combatentes de exemplo
|-- controla turnos
|-- processa ataques
|-- resolve Duelo
|-- valida habilidades
|-- processa itens
`-- atualiza paineis

ActionPanel
|-- menu principal
|-- lista de pericias
|-- detalhes de pericia
|-- lista de habilidades
|-- detalhes de habilidade
|-- lista de itens
`-- detalhes de item

RegionalSelector
|-- riscos de ataque
|-- regiao para item
|-- validacao de regiao perdida
|-- validacao de protese destruida
`-- validacao de regiao esgotada

EnemyPanel
|-- lista inimigos
|-- alvo selecionavel
|-- informacoes ocultas antes de Duelo
`-- informacoes reveladas apos analise

PartyPanel
|-- lista aliados
|-- destaque do turno
|-- PA, arma e Protecao
|-- Estresse por regiao
`-- alvo aliado para itens

CombatLog
|-- eventos de turno
|-- eventos de acao
|-- avisos
|-- dano/cura
`-- eventos criticos
```

## Fluxo de Ataque

```text
[ActionPanel: ATACAR]
        |
        v
[RegionalSelector: escolher regioes]
        |
        v
[EnemyPanel: escolher alvo]
        |
        v
[CombatManager: rolar D6 e processar]
        |
        v
[PartyPanel / EnemyPanel / CombatLog atualizados]
```

## Fluxo de Pericia Duelo

```text
[ActionPanel: PERICIA]
        |
        v
[Lista de pericias treinadas]
        |
        v
[Detalhes de Duelo]
        |
        v
[EnemyPanel: escolher alvo]
        |
        v
[CombatManager: executar Duelo]
        |
        v
[EnemyPanel revela dados se analisado]
```

## Fluxo de Habilidade

```text
[ActionPanel: HABILIDADE]
        |
        v
[Lista agrupada por Principal / Unica / Geral]
        |
        v
[Detalhes da habilidade]
        |
        v
[HabilidadeData: validar conhecimento e PA]
        |
        v
[CombatLog registra efeito textual]
```

## Fluxo de Item

```text
[ActionPanel: ITEM]
        |
        v
[Lista do inventario]
        |
        v
[Detalhes do item]
        |
        v
[PartyPanel: escolher aliado]
        |
        v
[RegionalSelector: escolher regiao]
        |
        v
[ItemData: aplicar Estus Fleskus]
```

## Estado Visual Atual

```text
Implementado
|-- ataque D6
|-- regioes corporais
|-- Estresse por regiao
|-- Protecao temporaria
|-- Duelo
|-- habilidades com validacao/PA
|-- item Estus
`-- log de combate

Parcial
|-- efeitos mecanicos de habilidades
|-- PA para todas as acoes
|-- foco centralizado do ActionPanel
`-- inventario/equipamentos

Pendente
|-- IA real
|-- movimento em fileira
|-- alcance no fluxo principal
|-- tela de resultado/loot
`-- persistencia
```
